module BooksController

using Genie.Renderer, SearchLight, Books, Genie.Router, Genie.Requests

function billgatesbooks()
  html!(:books, :billgatesbooks, books = SearchLight.all(Book))
end

function new()
  html!(:books, :new)
end

function create()
  cover_path = if haskey(filespayload(), "book_cover")
      path = joinpath("img", "covers", filespayload("book_cover").name)
      write(joinpath("public", path), IOBuffer(filespayload("book_cover").data))

      path
    else
      ""
  end

  Book( title = @params(:book_title),
        author = @params(:book_author),
        cover = cover_path) |> save && redirect_to(:get_bgbooks)
end

function edit()

end

function update()

end

module API

using ..BooksController
using Genie.Renderer
using SearchLight, Books

function billgatesbooks()
  json!(:books, :billgatesbooks, books = SearchLight.all(Book))
end

end # API

end # BooksController
