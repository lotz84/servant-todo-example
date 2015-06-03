{-# LANGUAGE DataKinds, DeriveGeneric, TypeOperators, OverloadedStrings #-}

import GHC.Generics
import Control.Monad.IO.Class (liftIO)
import Data.Aeson
import Data.Text (Text, empty, unpack)
import Data.IORef
import Lucid
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import Servant.HTML.Lucid

data Todo = Todo
    { todoId    :: Int
    , todoDone  :: Bool
    , todoTitle :: String
    } deriving Generic

instance ToJSON Todo where
    toJSON (Todo id' done' title') = object [ "id"    .= id'
                                            , "done"  .= done'
                                            , "title" .= title'
                                            ]

instance FromJSON Todo where
    parseJSON (Object v) = Todo
                       <$> v .: "id"
                       <*> v .: "done"
                       <*> v .: "title"
    parseJSON _          = error "Todo parse error from JSON"

instance FromFormUrlEncoded Todo where
    fromFormUrlEncoded form = let maybeTodo = do
                                      let id' = maybe (-1) (read . unpack) $ lookup "id" form
                                      let done   = maybe False (=="on") $ lookup "done" form
                                      title <- lookup "title" form
                                      return $ Todo id' done (unpack title)
                              in  maybe (Left "Todo parse error from Form") Right maybeTodo

type TodoAPI = Get '[HTML] (Html ()) -- root
          -- GET    /todo/all
          :<|> "todo" :> "all" :> Get '[JSON] [Todo]
          -- POST   /todo
          :<|> "todo" :> ReqBody '[FormUrlEncoded] Todo :> Post '[JSON] [Todo]
          -- PUT    /todo/:id
          :<|> "todo" :> Capture "id" Int :> ReqBody '[JSON] Todo :> Put '[JSON] [Todo]
          -- DELETE /todo/:id
          :<|> "todo" :> Capture "id" Int :> Delete '[JSON] [Todo]
          -- static files /public/*
          :<|> "public" :> Raw

todoAPI :: Proxy TodoAPI
todoAPI = Proxy

server :: IORef [Todo] -> Server TodoAPI
server todosRef = index
             :<|> todoAll
             :<|> createTodo
             :<|> putTodo
             :<|> deleteTodo
             :<|> serveDirectory "public"
    where
    index           = return $ indexHtml
    todoAll         = liftIO $ readIORef todosRef
    createTodo todo = do
        todos <- liftIO $ readIORef todosRef
        let nextId = if null todos
                         then 1
                         else (+1) . maximum . fmap todoId $ todos
        let todos' = todo {todoId = nextId} : todos
        liftIO $ writeIORef todosRef todos'
        return todos'
    putTodo targetId todo = do
        todos <- liftIO $ readIORef todosRef
        let (xs, ys) = break ((==targetId) . todoId) todos
        if null ys
            then return todos
            else do
               let todos' = xs ++ [todo] ++ tail ys
               liftIO $ writeIORef todosRef todos'
               return todos'
    deleteTodo targetId = do
        todos <- liftIO $ readIORef todosRef
        let todos' = filter ((/= targetId) . todoId) todos
        liftIO $ writeIORef todosRef todos'
        return todos'

main :: IO ()
main = do
    putStrLn "Listening on port 3000"
    todosRef <- newIORef []
    run 3000 $ serve todoAPI (server todosRef)

indexHtml :: Html ()
indexHtml = do
    doctype_
    html_ $ do
        head_ $ title_ [] "Servant Todo Example"
        body_ $ do
            h1_ [] "Servant Todo Example"
            table_ [id_ "todo-list"] ""
            form_ [id_ "todo-form", method_ "POST", action_ "/todo"] $ do
                input_ [type_ "text", name_ "title"]
                input_ [type_ "submit", value_ "Add"]
            script_ [src_ "//ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js"] empty
            script_ [src_ "/public/main.js"] empty
