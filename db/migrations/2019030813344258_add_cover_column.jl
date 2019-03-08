module AddCoverColumn

import SearchLight.Migrations: add_column, remove_column

function up()
  add_column(:books, :cover, :string)
end

function down()
  remove_column(:books, :cover)
end

end
