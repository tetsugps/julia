# Bill Gates' top $( length(@vars(:books)) ) recommended books
$(
   @foreach(@vars(:books)) do book
      "* $(book.title) by $(book.author)"
   end
)
