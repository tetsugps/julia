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

route("/bgbooks/new", BooksController.new)
route("/bgbooks/create", BooksController.create, method = POST, named = :create_book)

route("/api/v1/bgbooks", BooksController.API.billgatesbooks)
