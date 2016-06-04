---
title: Sild is a lisp dialect
layout: post
---

Today, I'm releasing [**Sild**](https://github.com/urthbound/sild), a tiny
little intepreted lisp that I wrote in C.

I've been interested in trying to learn about language design and
implementation for a while now. I've also been interested in Lisp as a concept,
and I had been wanting to learn C so that I could start wrapping my head around
systems programming too. This project brought all of those things together!

Sild is not conformant to any existing spec. It's not _really_ a Scheme and it
is definitely not a version of Common Lisp. It is simply my attempt to build a
lispy language in a semi-vacuum from first principles.

A Lisp can be _incredibly_ syntactically simple. It is comparatively easy to
write a parser for a homegrown lisp; the same task for a homegrown
pretty-much-anything-else would be orders of magnitude more complex, full of
bugs and edgecases. For Sild, I was able to write a parser that operates with
minimal lookahead and in linear time.

I was inspired to try this project by a variety of things. 

Paul Graham's [_The Roots of Lisp_](http://www.paulgraham.com/rootsoflisp.html)

Mary Rose Cook's [_Little Lisp Interpreter_](https://www.recurse.com/blog/21-little-lisp-interpreter)

Daniel Holden's [_Build Your Own Lisp_](http://www.buildyourownlisp.com/)

John Mccarthy's original 1960 paper [_Recursive Functions of Symbolic Expressions and Their Computation by Machine (Part I)_](http://www-formal.stanford.edu/jmc/recursive.html)

the art of the interpreter

http://repository.readscheme.org/ftp/papers/ai-lab-pubs/AIM-453.pdf

and of course, Sicp https://mitpress.mit.edu/sicp/full-text/book/book.html


