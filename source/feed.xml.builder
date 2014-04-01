---
layout: false
---

xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title "Jeff Fowler's Blog"
  xml.subtitle ""
  xml.id "http://urthbound.github.io/blog"
  xml.link "href" => "http://urthbound.github.io"
  xml.link "href" => "http://urthbound.github.io/feed.xml", "rel" => "self"
  xml.updated blog.articles.first.date.to_time.iso8601
  blog.articles[0..5].each do |article|
    if article.tags.include? "hs"
      xml.entry do
        xml.title article.title
        xml.link "rel" => "alternate", "href" => "http://urthbound.github.io" + article.url
        xml.id "http://urthbound.github.io" + article.url
        xml.published article.date.to_time.iso8601
        xml.updated article.date.to_time.iso8601
        xml.author { xml.name "Article Author" }
        # xml.summary article.summary, "type" => "html"
        xml.content article.body, "type" => "html"
      end
    end
  end
end
