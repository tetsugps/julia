module BooksController

using Genie.Renderer, SearchLight, Books, Genie.Router, Genie.Requests

function billgatesbooks()
  html!(:books, :billgatesbooks, context = @__MODULE__, books = SearchLight.all(Book))
end

function new()
  html!(:books, :new, context = @__MODULE__, book = Book())
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
  book = try
    SearchLight.find_one!!(Book, @params(:id))
  catch ex
    return error_404("Book ID $(@params(:id))")
  end

  html!(:books, :edit, book = book, context = @__MODULE__)
end

function update()

end

module API

using ..BooksController
using Genie.Renderer
using SearchLight, Books

function billgatesbooks()
  json!(:books, :billgatesbooks, books = SearchLight.all(Book), context = @__MODULE__)
end

end # API

end # BooksController
