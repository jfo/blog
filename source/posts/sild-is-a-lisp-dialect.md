---
title: Sild is a lisp dialect
date: 2016-06-5
layout: post
tags: rc
---

Today, I'm releasing [**Sild**](https://github.com/urthbound/sild), a tiny
little intepreted lisp that I wrote in C.

I've been interested in trying to learn about language design and
implementation for a while now. I've also been interested in Lisp as a concept,
and I had _also_ been wanting to learn C so that I could start wrapping my head
around systems programming. This project brought all of those objectives
together in a really natural way!

Sild is not conformant to any existing spec. It's not _really_ a Scheme and it
is _definitely_ not a version of Common Lisp. It is simply my attempt to build a
minimal lispy language in a semi-vacuum from first principles.

Though I'm proud of the final result, that's not what I'm _most_ excited about
sharing. I also wrote blog posts as I went along. A _lot_ of them. Just about
40,000 words' worth! I'm going to post them here in the coming weeks. It's my
hope that other people might be able to learn some of the things I learned!

I've tried to write those posts so that they will be understandable to someone
who can program in some language, and who maybe knows a _little_ about C, and maybe
knows a _little_ about lisp.

I am open to suggestions and criticisms. The posts might seem like they are
written from a position of authority, but do not be fooled. I was figuring
everything out as I went along, then writing them down just after I had figured
them out, and I most certainly did not nail everything! I am very interested to
hear where what I tried to do diverged from historical attempts, or where I
reinvented some wheel or another.

<hr>

I was inspired to try this project by a variety of things.

- Mary Rose Cook's [_Little Lisp Interpreter_](https://www.recurse.com/blog/21-little-lisp-interpreter)

At some point during a long flight I tried coding most of this post in Ruby. I don't
remember what I did with that repo, and I don't think it even really worked all
the way, but it gave me the idea that a lisp might be a lot easier to
implement than I thought.

- Paul Graham's [_The Roots of Lisp_](http://www.paulgraham.com/rootsoflisp.html)

This is a very sticky essay. Graham's proceduralness possesses a certain kind
of clarity that left me with the impression that it might be worth trying to
write the simple lisp he describes, and indeed that's pretty much what I ended
up with. Sild, as it is right now, has no types (like strings or numbers), and
has no I/O save a basic `display` that prints to `stdout`. It has no real
standard library to speak of, either, but it _does_ have the basic operations
that Graham describes as necessary to implement `eval`.

- Daniel Holden's [_Build Your Own Lisp_](http://www.buildyourownlisp.com/)

Google "[build your own
lisp](https://www.google.com/search?q=build+your+own+lisp&oq=build+your+own+lisp&aqs=chrome..69i57j69i60l2.2691j0j7&sourceid=chrome&ie=UTF-8)",
and you'll get an entire first page of results referencing this site. I [gave
it a good go](https://github.com/urthbound/buildyourownlisp), making it to
chapter 9 or so, and I have to say that it is incredibly well thought out and
well expressed and I totally learned a lot from it! But somewhere along the way I started
feeling like I was just typing things in until they worked without really
understanding why, which is my personal canary in the coal mine for impending
this-isn't-working-for-me-anymore-ness. Then I read the URL and realized what
appealed to me so much about the site is the _your_ in "build your own lisp", so
I stopped working through the tutorial and decided to try that for real! From
there, I circled back to the Paul Graham essay and used it as a guide.

<hr>

There were a variety of other things I ran across while writing this language
that I read parts of, with the intention of revisiting them with a more context
after I was done with the project.

- John McCarthy's original 1960 paper [_Recursive Functions of Symbolic
  Expressions and Their Computation by Machine (Part
  I)_](http://www-formal.stanford.edu/jmc/recursive.html)

I had "read" this a few times, but always with the feeling I wasn't really
getting it. Implementing what amounts to the lisp described in this paper
(via the Paul Graham essay), has made this seminal work a lot easier to
comprehend!

- Sussman and Abelson's [_The Art of the Interpreter_](http://repository.readscheme.org/ftp/papers/ai-lab-pubs/AIM-453.pdf)

I consulted this a few times when I ran into specific questions, but again, I
didn't really grok it until after I had finished the whole thing. The finer
points of closures and mutability and garbage collection were all lost on me
until I banged my own head against them all for a while. The first time I read
this paper it was a "I know these words" sort of situation. Now, it's more of a
"YES OMG YES SO TRUE" kind of deal.

- Sussman and Abelson's [Structure and Interpretation of Computer Programs](https://mitpress.mit.edu/sicp/full-text/book/book.html)

Again, I had read a lot of this before, and had gotten real value out of it. But
now when I go back, it just reads a lot richer and more nuanced, and I find
myself considering intricacies that simply wouldn't have occured to me before.

Thanks
------

Big thanks to [Andrew Kelley](https://github.com/andrewrk), whose brilliant
code reviews levelled up my C on multiple occasions. Also to [Darius
Bacon](https://github.com/darius), whose feedback had a fantastic twinge of "I
have trod where you tread" that helped me appreciate all the things I must have
missed. I look forward to finding them out in more detail!

Also to [Pam Selle](http://thewebivore.com/) and [Nick
Drozd](https://github.com/nickdrozd) for reading early posts, and [Bert
Muthalany](https://github.com/stijlist) for his enthusiasm.

<hr>

Working on this language was immensely rewarding, and I learned an enormous
amount from it. While I intend to work on it more, adding some of the TODO's
in the README, and hope to end up with a useful scripting language all to
myself, the original motivation of the project has been satisfied. I hope you
find it as interesting as I did!
