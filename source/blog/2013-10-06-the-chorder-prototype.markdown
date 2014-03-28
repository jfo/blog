---
layout: post
status: publish
published: true
title: '"The Chorder" prototype'
author: Jeff
author_login: jeffowler
author_email: jeffowler@gmail.com
wordpress_id: 714
wordpress_url: http://www.jeffalanfowler.com/blog/?p=714
categories:
- Programming
tags: []
comments:
- id: 9
  author: John Doing
  author_email: ''
  author_url: http://facebook.com/profile.php?id=8627460
  date: '2013-10-06 21:40:41 -0400'
  date_gmt: '2013-10-07 01:40:41 -0400'
  content: Looking good man!!
---
<img class=" wp-image-728 aligncenter" alt="Screen Shot 2013-10-06 at 4.53.52 PM" src="/images/30.png" width="578" height="434" /></a></p>
&nbsp;

<p>
  I wrote this program a few months ago. It's visually minimal, but it can generate over a thousand valid chord shapes. I wrote it in Ruby and wrapped it in <a href="http://shoesrb.com/" target="_blank">Shoes</a>. Instead of prettifying the above format, I decided to refactor the whole project and build it into a web app, while extending it's functionality to include Drop 3, Drop 2/3, and Drop 2/4 voicings and inversions. That's in the pipes.

I'm  planning to use this as a base from which to write a program that can output properly voice-led arrangements of any jazz tune by reading charts from the <a href="http://musiccog.ohio-state.edu/home/index.php/iRb_Jazz_Corpus" target="_blank">iRb Jazz Corpus</a>, which I'm making good progress with but will elaborate on in a future post.

If you'd like to run this version, you can<a href="http://shoesrb.com/downloads.html" target="_blank"> download the shoes interpreter here</a> and the <a href="http://jeffalanfowler.com/drop/shoeschorder.rb" target="_blank">GUI source code here </a> and open the latter in the former. If you're command-line savvy, you could also <a href="https://github.com/urthbound/chorder" target="_blank">clone the github repo</a> and run a terminal interface via "$ruby interface.rb" that accesses the same logic.

The left hand side has five main groups of buttons:

<ul>
	<li>root note</li>
	<li>accidental</li>
	<li>chord quality</li>
	<li>inversion</li>
	<li>string set</li>
</ul>
<p>The program will also accommodate open strings and notes that fall above the 12th fret.</p>
