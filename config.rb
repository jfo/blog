set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'
set :layout, :standard
set :markdown, :fenced_code_blocks => true, :smartypants => true
set :markdown_engine, :redcarpet
activate :directory_indexes
activate :syntax

activate :blog do |blog|
  blog.sources = "posts/:year-:month-:day-:title.html"
  blog.permalink = "/{year}/{month}/{title}.html"
end

configure :build do
end
