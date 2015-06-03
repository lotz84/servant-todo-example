Servant Todo Example
====================

Todo web app example using [servant](https://hackage.haskell.org/package/servant)

![](http://i.gyazo.com/34857e26647291c283537f95fe137f48.png)

```bash
$ cabal install --only-dependencies
$ cabal run
```

And access <http://localhost:3000> on web browser.

##Type of API

```haskell
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
```
