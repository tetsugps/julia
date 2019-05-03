module ViewHelper

using Genie, Genie.Helpers, SearchLight, Genie.Router

export output_flash, book_cover, book_form_uri

function output_flash(params::Dict{Symbol,Any}) :: String
  ! isempty( flash(params) ) ? """<div class="form-group alert alert-info">$(flash(params))</div>""" : ""
end

function book_cover(book)
  isempty(book.cover) ? "img/docs.png" : book.cover
end

function book_form_uri(book)
  ispersisted(book) ? link_to(:update_book, id = book.id |> get) : link_to(:create_book)
end

end
