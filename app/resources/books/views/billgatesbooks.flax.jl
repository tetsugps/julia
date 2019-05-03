() -> begin
Flax.h1("Bill's Gates top $( length(@vars(:books)) ) recommended books")
Flax.ul(
   @foreach(@vars(:books)) do book
      partial("app/resources/books/views/book.jl.html", book = book)
   end
)
end
