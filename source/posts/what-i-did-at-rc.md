---
title: What I did at the Recurse Center
date: 2016-05-20
layout: post
tags: rc
---

I wrote about what I did [before](/how-i-went-to-rc) I went to the Recurse Center, essentially about
what I did to learn (or more accurately, begin to learn) to program, and now I want
to write about what I did while I was there, and what I did just prior to
being there, after I had been accepted.

I should have written all this while it was happening, but I didn't. I remember
a lot about the process of working on these projects, but I have forgotten just
as much. I've forgotten the specific challenges and pitfalls I ran into at the
time. I've forgotten a lot of what surprised me... perhaps more importantly,
though, is that I've forgotten the perspective I had. I still _remember having
it_, I just can't _access_ it. I wish I had taken more notes, I wish I had
written more things, but I'll try to write them now, as well as I maybe can.

<hr>

![img](https://s-media-cache-ak0.pinimg.com/736x/74/57/0b/74570beddef5a8f0beefdd102eec9739.jpg)

The very first thing I did after I was accepted was to not program at all for
two solid weeks, and instead to take a trip to Copenhagen to get hazed by my
girlfriend's Danish uncles.

I came back in early January of '14, brain freshly pickled in
[snaps](https://en.wikipedia.org/wiki/Snaps). I
had around a month before my batch started, and a renewed vigor. Now freed from
the idea that I "had" to learn Rails, I gave some more attention to the Ruby
language, by itself, starting with a week or two working through the [ruby
koans](http://rubykoans.com/). They were fun, and I really liked the format.

Sometime around then, the mailing list opened up for my batchmates to introduce
themselves and coordinate housing and things like that. I wrote a little
[hello program](https://github.com/urthbound/hello), but I don't think anyone
ever ran it. That's ok it was kind of silly.

I asked for suggestions for resources to learn low level programming. Real low
level programming, this time, not [brainfuck](/how-brainfuck-works/), which I
thought was low level when I learned it, and in some way it is, I guess, but
not in any meaningful sense of the way that term is actually used by real
people. [Rose Ames](https://superluser.recurse.com/) suggested ["From NAND to
Tetris: Building a Modern Computer from First
Principles"](http://www.nand2tetris.org/).

Now if there is one thing I love, it's first principles. I loooooove first
principles. The idea of starting with something very simple and building out of
it a _giant system_ or an _entire world_ is baked into the way I _want_ to
understand everything. I bought the book immediately, and spent the next three
weeks working through it for as much time as I could find every day. It was
_really_ hard, and _really_ good. I probably learned more from that book than
any other single thing I did throughout this entire process, for real.

I got [almost all the way through it](https://github.com/urthbound/nand2tetris),
but I hit my limits the week before the batch started. I got the compiler to
work, but I couldn't find the desire to work on the OS. It's really just as
well... I needed a rest before things really kicked off, after all.

And then the batch started!

<hr>

I'll try to recall the rough order I worked on these projects, but it's been
two years now, so... sorry I guess, random internet person and/or irl friend.

The first thing I remember doing was pairing with [Robert Lord](https://lord.io/)
on a battleship playing [bot](https://github.com/urthbound/battleship) in Ruby
for a [fight club meetup](http://www.meetup.com/Ruby-Fight-Club/events/164727382/)
later that week. Robert was so good! And like, seventeen years
old. I hadn't done too much pairing before RC and it was something I wanted to
get a lot better at, so this was an auspicious start. We didn't win the
contest, but if I recall correctly we came in respectably in the middle of the pack.
More importantly, it was a lot of fun, and it was the first time I went out _in
public_ and looked a stranger _right in the eyes_ and told them I was a programmer.
That was a pretty big step.

The rest of that first week I waffled between trying to decide what to work on
for the batch and feeling guilty for not having finished / trying to finish
Nand2Tetris (as it is colloquially known). I couldn't get myself to finish it,
and decided that as much as I wanted to appease the completest inside of me, it
wasn't worth working on it when I was so much more interested in other things,
so I let it lie. I had gotten an enormous amount out of it, and most of what I
wanted from it was in the low level parts anyway.

<hr>

The second week I spent a day or so worrying about whether or not I should
switch to Python. There were really only a few other Ruby people in my batch-
it seemed like everyone else did python, and it was stressing me out. How could
I pair with _python_ people if I only knew _ruby_?

I talked with all the facilitators at least once about this, probably, and they
all said the same thing, which is also in the [user's manual](https://www.recurse.com/manual),
and that was to stick with the language I knew the best and write things with it.

But I couldn't shake the feeling that I should be using the language that most
of the people around me were using, so I resolved to learn it. I spent a
couple of days reading through some tutorials, doing some exercises... it all
seemed very familiar, like I had already done this step... it was not super
exciting.

On the third day of this, I was solving a [project euler](https://projecteuler.net/)
problem in
[Ruby](https://github.com/urthbound/euler/blob/master/18_max_path_sum.rb) and
[Python](https://github.com/urthbound/euler/blob/master/18_max_path_sum.py)
side by side. Halfway through writing the Ruby version, I really noticed how
similar they were. They are _really_ similar, especially on the surface,
especially so at the level I was at at the time, which was pretty
rudimentary, still, and I got really _mad_, actually, that I had been spending so
much time fretting about this and buying into the fiction that all languages
are incredibly different and that choosing one was like putting on a team
jersey. I think I even stopped working on it
[_mid line_](https://github.com/urthbound/euler/blob/master/18_max_path_sum.rb#L40), actually.

They were right, of course, about sticking with what you're comfortable with
and exploring concepts and projects instead, but I needed to learn that the
language you choose doesn't matter that much in the end on my own, so that was
worth a week, I think. It's a hard lesson to learn as a beginner! I stopped
feeling like I _had to_ learn python, but I also stopped being afraid of it.
Turns out that's all you really need to be able to pair with someone in a less
familiar to you language. Who knew?

<hr>


Somewhere around the middle of the batch I participated in the traditional "I
should have a blog which one should it be" week, decided on a static generator
instead of wordpress, switched from middleman to jekyll and back, decided I
should know how to host it myself, and then fought nginx config files and [AWS](/into-the-cloud-a-quick-aws-primer/)
for like _another_ week . I also decided it would be good to be able to host my
own apps and sites, and spent part of that time figuring out really boring
server config type stuff. I polished up my rubik's cube with keyboard
bindings, made it look better, and hosted it on my own server.  I spent a
pretty long time, a few weeks probably, with this as my primary project. I
can't say that was super fun, the nginx docs are some of the least beginner
friendly things I've ever read, but as it turns out a lot of that was
really valuable experience. Never really did get any blog posts done,
though, just one where I kind of shittily explain [recursion](/recursion/)
even though I only kind of knew what it was, but A for effort?

<hr>

I decided to learn Clojure. There were a few reasons for this. There was a
sizable subgroup of my batch that was into it. It is a lisp, and traditionally,
lisps have been used in generative music research. Also lisp was very exotic
and seemed really hard, and trying things that would normally seem too hard is
one of the things they told us to do in our batch. Unlike my hemming and hawing
about python and ruby, clojure is _actually_ different from anything I had done
before... a completely different paradigm- both syntactically (zomg parens
amirite?) and functionally (functionally). The ruby koans worked for me, and I
found the [Clojure Koans](http://clojurekoans.com/) pretty approachable as
well, so that's where I started.

It didn't take me long to discover [Overtone](http://overtone.github.io/), a
Clojure wrapper library to interact with the software synth
[Supercollider](http://supercollider.github.io/).  I had originally wanted to
write a voice leading engine, but ended up writing a
[humdrum](http://www.musiccog.ohio-state.edu/Humdrum/) interpreter and player
instead, called [Fux](https://github.com/urthbound/fux). I think Fux was the
biggest thing that I felt the most proud of doing while I was there, and it's
one of only a few things I gave a presentation on. It would read a textfile
representation of a score of a Bach chorale, and then output the four voices as
sine waves via Overtone. It really made noise! It was great!

<hr>

I worked on quite a few smaller projects, too.

- A [Chessbot](https://github.com/urthbound/chessbot) for
  [Zulip](https://zulip.org/), our internal chat client.

  Zulip bots are a
  really popular project as they are of a pretty contained scope and
  immediately useful.  This one couldn't play with you, but it acted like a
  chess board that anyone could interact with in a given channel or private
  message thread.

- A simple [genetic algorithm](/a-simple-gene) that
  optimizes for the number of `1`'s in a series.

  I think this was a very successful project, despite its small size. I learned
  a LOT that I didn't know, it only took a few days, it _worked_, and I was
  even able to write it up. This is exactlyy the kind of thing I would try
  harder to do more of if I were to do another batch.

- A vim plugin called [Runners](https://github.com/urthbound/vim-runners)
  that knows how to execute scripts by filetype.

  It is really simple and not especially clever, but I still use this plugin
  almost every single day to iterate quickly, and I've recently added support
  for makefiles! The plugin will delegate its behaviour to the makefile if it
  has a "run" target, essentially allowing you to script any behavior you
  want in whatever context. Also it makes C feel like a scripting language!
  So that is very nice.

- A [url link shortener](https://www.youtube.com/watch?v=dQw4w9WgXcQ) that
  could be set to automagically redirect a user to Rick Astly's 1987 smash hit,
  "Never Gonna Give You Up" ([code here](https://github.com/urthbound/rickroller))

  No further comment.

- Some miscellaneous puzzle solutions that I'm quite proud of, including [the
  eight queens](https://github.com/urthbound/puzzles/blob/master/eightqueens.rb),
  a [sudoku solver](https://github.com/urthbound/puzzles/blob/master/sudoku.rb),
  and [Conway's Game of Life](https://github.com/urthbound/terrorium/blob/master/life.rb).

There was some more Euler solving, and some more pairing, and even some just
plain old hanging out. It was an amazing group of people from an impressively
wide array of backgrounds. There were at least half a dozen Phd's in varied
fields that had nothing to do with programming at all.

I was still teaching music throughout all of this; I had _just enough_ students
to keep my rent paid. But it meant that I usually had to miss most if not all
of the Thursday night presentations, where my batchmates would talk about
what they were working on and what they had made. I really regretted missing
those, but there was nothing I could do about it. The presentations are so fun
and so interesting and for some people it is the only time that they _really_
put themselves out there and share the cool things they've been learning.

The last couple of weeks were filled with more intense interview prep, more
"looking for jobs" type stuff, and general stressing out followed by marginally
more partying than we had been doing. Then it was over. It both went fast and
slow... so much happened, to be honest when I think back on it, it kind of
feels like a full school year somehow, but three months is really not that
long.

<hr>

And that's it. After hearing about RC, people often scratch their heads and
ask... "but what do you learn there? are there classes? that doesn't sound like
it would work...". I don't blame the reaction- I had my own skepticism going
in, but I also knew how powerful self directed learning could be.

It's not magic dust- I spent three months with my hands on the keyboard,
programming a lot of different things, surrounded by other people doing the
same. If I got stuck, now there was someone who could get me unstuck sitting
next to me, or across the room. If I got distracted, or didn't know what I
wanted to work on, I could just pair for a while with someone else, or watch
what they were doing. There was no question I could think up that didn't
have an answer close by, especially at the level I was at going in, as one of
the most inexperienced people there.

I spent a lot of time programming, and I got a lot better at it! That's all
there was to it, at the end of the day. It was super fun!  If this sounds like
something you might enjoy doing, you should totally [apply](https://www.recurse.com)!
