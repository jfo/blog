---
title: monome part bi
date: 2015-05-15 02:09 UTC
layout: post
published: false
tags: hs, monome, music, programming
---


In the last post I talked about figuring out what signals are coming from the monome when I press buttons. The obvious next question is what signals I can send _to_ the monome.

I'd like to say I reverse engineered this, also, but I'd be lying. My best guess was that it would follow a similar pattern of 3 bytes per signal- x and y coordinates and an on or off byte. I didn't want to start guessing though, so to check my intuition I instead turned to the [protocol itself](http://monome.org/docs/tech:serial). I was right, pretty much.

The protocol, I suppose, is exhaustive


trying it with bash.
working only the first time
new line duh in echo
ok so ets write a script
ruby open serial
most languages have a serial lib
here's one in clojure
here's one in c
or whatever the fuck.
how do I turn all the lights on?
how do I turn all the lights off?
how do I control a single light?
how do  I control intensity? how many layers of intensity?
a simple simple program... light comes on when you hit the button, goes off when you release.
problems with this thinger... multiple at once makes things fucked up. uh oh! how does libmonome solve this problem? a buffer, probably. let's try that and see what happens! 
I heart monome!

