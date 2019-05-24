module BooksController

using Genie.Renderer, SearchLight, Books, Genie.Router, Genie.Requests

using Debugger
Debugger.break_on(:error)

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

function index()
  @vars(:books, SearchLight.all(Book))
  html!("""
<h1>Bill's Gates top $(length(@vars(:books))) recommended books</h1>
<ul>
  <%
    @foreach(@vars(:books)) do book
      partial("app/resources/books/views/book.jl.html", book = book)
    end
  %>
</ul>
  """, context = @__MODULE__)
end

function flaxtest()
  books = SearchLight.all(Book)
  Flax.section([
    Flax.h1("Bill's Gates top $(length(books))")
    Flax.ul(
      @foreach(books) do book
        partial("app/resources/books/views/book.jl.html", context = @__MODULE__, book = book)
      end
    )
  ])
end

function foo()
  "mee"
end

### API

module API

using ..BooksController
using Genie.Renderer
using SearchLight, Books
using JSON

function billgatesbooks()
  json!(:books, :billgatesbooks, books = SearchLight.all(Book), context = @__MODULE__)
end

function jsontest()
  respond(JSON.json(SearchLight.all(Book)), "application/json")
end

end # API

end # BooksController
