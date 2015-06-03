var updateTodoList = function(list){
    $("#todo-list .todo-item").remove();
    list.sort(function(a, b){return a.id - b.id;})
    list.forEach(function(todo){
        var doneCheckbox = $("<input />")
                           .attr("type", "checkbox")
                           .prop("checked", todo.done)
                           .on("change", function(e){
                               todo.done = !todo.done;
                               $.ajax({
                                   url:  "/todo/" + todo.id,
                                   type: "PUT",
                                   contentType: 'application/json',
                                   data: JSON.stringify(todo)
                               })
                               .then(updateTodoList);
                           });
        var deleteButton = $("<button />")
                           .text("Delete")
                           .on("click", function(e){
                               $.ajax({
                                   url:  "/todo/" + todo.id,
                                   type: "DELETE"
                               })
                               .then(updateTodoList);
                           });
        var tr = $("<tr />").addClass("todo-item")
                 .append($("<td />").text(todo.id))
                 .append($("<td />").html(doneCheckbox))
                 .append($("<td />").text(todo.title))
                 .append($("<td />").html(deleteButton));
        $("#todo-list").append(tr);
    });
}

$.get("/todo/all", updateTodoList);

$("#todo-form").on("submit", function(e){
    e.preventDefault();
    var $form = $(this);
    $.ajax({
        url: $form.attr('action'),
        type: $form.attr('method'),
        data: $form.serialize()
    })
    .then(updateTodoList);
});
