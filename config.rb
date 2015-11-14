activate :syntax
set :markdown, :fenced_code_blocks => true, :smartypants => true
set :markdown_engine, :redcarpet

activate :blog do |blog|
    blog.sources = "posts/:title.html"
    blog.permalink = "/{title}.html"
end

activate :directory_indexes

configure :development do
    activate :drafts do |drafts|
        drafts.build = true
    end
end

configure :build do
    activate :drafts do |drafts|
        drafts.build = false
    end
end
