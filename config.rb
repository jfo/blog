set :layout, :standard

activate :syntax
set :markdown, :fenced_code_blocks => true, :smartypants => true
set :markdown_engine, :redcarpet

# Middleman provides the Directory Indexes extension to tell Middleman to create 
# a folder for each .html file and place the built template file as the index 
# of that folder.
activate :directory_indexes

activate :blog do |blog|
  blog.sources = "posts/:title.html"
  blog.permalink = "/{title}.html"
end
