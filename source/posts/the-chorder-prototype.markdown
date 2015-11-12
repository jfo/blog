---
title: '"The Chorder" prototype'
date: 2013/10/06
layout: post
categories:
- Programming
---

I wrote [this](https://github.com/urthbound/chorder) program a few months ago. It's visually minimal, but it can generate over a thousand valid chord shapes. I wrote it in Ruby and wrapped it in <a href="http://shoesrb.com/" target="_blank">Shoes</a>. Instead of prettifying it, I decided to refactor the whole project and build it into a web app, while extending it's functionality to include Drop 3, Drop 2/3, and Drop 2/4 voicings and inversions. That's in the pipes.

I'm  planning to use this as a base from which to write a program that can output properly voice-led arrangements of any jazz tune by reading charts from the <a href="http://musiccog.ohio-state.edu/home/index.php/iRb_Jazz_Corpus" target="_blank">iRb Jazz Corpus</a>, which I'm making good progress with but will elaborate on in a future post.

If you'd like to run this version, you can<a href="http://shoesrb.com/downloads.html" target="_blank"> download the shoes interpreter here</a> and open the source in the shoes GUI. If you're command-line savvy, you could also <a href="https://github.com/urthbound/chorder" target="_blank">clone the github repo</a> and run a terminal interface via `$ruby interface.rb` that accesses the same logic.

The left hand side has five main groups of buttons:

<ul>
        <li>root note</li>
        <li>accidental</li>
        <li>chord quality</li>
        <li>inversion</li>
        <li>string set</li>
</ul>

The program will also accommodate open strings and notes that fall above the 12th fret.
