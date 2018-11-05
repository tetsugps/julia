module BooksController

using Genie.Renderer, SearchLight, Books, Genie.Router

function billgatesbooks()
  html!(:books, :billgatesbooks, books = SearchLight.all(Book))
end

function new()
  html!(:books, :new)
end

function create()
  Book(title = @params(:book_title), author = @params(:book_author)) |> save && redirect_to(:get_bgbooks)
end

module API

using ..BooksController
using Genie.Renderer
using JSON

function billgatesbooks()
  json!(:books, :billgatesbooks, books = SearchLight.all(Book))
end

end

end
