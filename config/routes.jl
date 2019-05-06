using Genie.Router, Genie.Renderer
using MyLib
using BooksController
using BooksController.API

route("/") do
  serve_static_file("/welcome.html")
end

route("/hello") do
  "Welcome to Genie!"
end

route("/friday") do
  MyLib.isitfriday() ? "Yes, it's Friday!" : "No, not yet :("
end

route("/bgbooks", BooksController.billgatesbooks)
route("/bgbooks/list", BooksController.index, named = :list_books)
route("/bgbooks/flaxlist", BooksController.flaxtest)
route("/bgbooks/new", BooksController.new)
route("/bgbooks/create", BooksController.create, method = POST, named = :create_book)
route("/bgbooks/:id::Int/edit", BooksController.edit, named = :edit_book)
route("/bgbooks/:id::Int/update", BooksController.update, method = POST, named = :update_book)

route("/api/v1/bgbooks", BooksController.API.billgatesbooks)
