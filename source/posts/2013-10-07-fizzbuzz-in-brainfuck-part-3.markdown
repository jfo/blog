---
layout: post
status: publish
published: true
title: fizzbuzz in brainfuck, part 3
author: Jeff
categories:
- Programming
tags: []
comments: []
---
<p style="text-align: left;">Alright. I have a memory array loaded with the information I need to get going, and I have a program blueprint that I should be able to implement. I only need to be able to use if/else and if. I looked up some algorithms to use for this bit, and these are the ones I settled on...<a id="more"></a><a id="more-706"></a></p>


<p style="text-align: left;">If ...</p>

<pre>
temp0[-]
temp1[-]
x[temp0+temp1+x-]temp0[x+temp0-]+
temp1[temp0-temp1[-]]
temp0[
<strong>
<i>  code</i  >

</strong>temp0-]</pre>

and If/Else...

<pre>temp0[-]+
temp1[-]
x[
<strong>   <i>code1</i></strong>

temp0-
x[temp1+x-]
]
temp1[x+temp1-]
temp0[
<strong>   
<i>    code2
</i></strong>
temp0]</pre>


<p>Note that the inline "variable" names are actually describing whatever location that cell happens to be. When we get to the final code, those plain text names will be appended with the pointer motions necessary to arrive at them. Both of these algorithms were lifted from <a href="http://esolangs.org/wiki/brainfuck_algorithms" target="_blank">here</a>. For every cell I want to evaluate, I need two more cells to hold temporary information. This is why I left two empty cells next to each multiples counter in the last post, and it is also why I'll need to slap a couple more empty cells onto the beginning of the whole program when we get around to putting in the final "Buzz" block that needs to be nested into the "Fizz" block. But notice! There is already a problem here... for If/Else, this algorithm runs the first block IF the cell it's evaluating is "TRUE" (meaning it's holding a value other than 0). For our "Fizz" and "Buzz" statements, we want them to run if the value of the cell is "0". Sad Trombone. But it's an easy fix, of course! We just have to invert all the code we had <a title="fizzbuzz in brainfuck, part one" href="http://www.jeffalanfowler.com/blog/fizzbuzz-in-brainfuck-part-one/" target="_blank">before</a>. Just keep that in mind. Lets write the inverted program in psuedo-code and then fill it all in with the specifics...</p>

<pre>
number = 0

until number == 100 do
  if number   % 3 != 0
    if number % 5 != 0
      print number
    else
      print "Buzz"
    end

  else
    print "Fizz"

    if number % 5 == 0
      print "Buzz"
    end
  end

number += 1
end
</pre>


Keep in mind that we've taken care of all the variable assignments and memory allocation in the last post, so this really is all we have left. I'll upcase the "rubyish" lines and fill in the brainfuck underneath them.

<pre>
open hundreds loop
&lt;&lt;&lt;[&gt;&gt;&gt;
  open tens loop
  &lt;&lt;[&gt;&gt;
    open ones loop
    &lt;[&gt;

      IF NUMBER % 3 != 0
      if cell1 == true
      &lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;
      &gt;temp0[-]+
      &gt;temp1[-]
      &lt;&lt;x[

      IF NUMBER % 5 != 0
      &gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;
      &lt;&lt;&lt;&lt;&lt;&lt;
      &gt;temp0[-]
      &gt;temp1[-]
      &lt;&lt;x[&gt;temp0+&gt;temp1+&lt;&lt;x-]&gt;temp0[&lt;x+&gt;temp0-]
      &gt;temp1[
      &gt;&gt;&gt;&gt;

        print current number
        .&gt;.&gt;.&gt;.&lt;&lt;&lt;
        &lt;&lt;&lt;&lt;
        temp1[-]]
        &gt;&gt;&gt;&gt;
        &lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;

      ELSIF NUMBER % 3 == 0
      elsif cell1 == false
      &gt;temp0-
      &lt;x[&gt;&gt;temp1+&lt;&lt;x-]

      ]

        PRINT FIZZ
        &gt;&gt;temp1[&lt;&lt;x+&gt;&gt;temp1-]
        &lt;temp0[
        &gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;

        .
        &gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;
        .&gt;.&gt;&gt;&gt;..&lt;&lt;&lt;&lt;
        &lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;

        IF NUMBER % 5 == 0
        &lt;&lt;&lt;&lt;&lt;&lt;
        &gt;temp0[-]
        &gt;temp1[-]
        &lt;&lt;x[&gt;temp0+&gt;temp1+&lt;&lt;x-]&gt;temp0[&lt;x+&gt;temp0-]+
        &gt;temp1[&lt;temp0-&gt;temp1[-]]
        &lt;temp0[&gt;&gt;&gt;&gt;&gt;

        PRINT BUZZ
        &gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;
        &gt;&gt;.&gt;.&gt;..&lt;&lt;&lt;&lt;
        &lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;

        &lt;&lt;&lt;&lt;&lt;
        temp0-]
        &gt;&gt;&gt;&gt;&gt;

        cell 1 = 3
        &lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;+++&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;

        &lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;
        temp0-]
        &gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;

      ELSIF NUMBER % 5 == 0
      &lt;&lt;&lt;&lt;&lt;&lt;
      &gt;temp0[-]+
      &gt;temp1[-]
      &lt;&lt;x[&gt;temp0-&lt;x[&gt;&gt;temp1+&lt;&lt;x-]]
      &gt;&gt;temp1[&lt;&lt;x+&gt;&gt;temp1-]
      &lt;temp0[
      &lt;+++++&gt;

        PRINT BUZZ
        &gt;&gt;&gt;&gt;&gt;
        .
        &gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;
        &gt;&gt;&gt;&gt;&gt;
        &gt;&gt;.&gt;.&gt;..&lt;&lt;&lt;&lt;
        &lt;&lt;&lt;&lt;&lt;
        &lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;
        &lt;&lt;&lt;&lt;&lt;
        temp0-]
        &gt;&gt;&gt;&gt;&gt;

      increment ones place
      &gt;&gt;&gt;+&lt;&lt;&lt;
      decrement 3s counter
      &lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;-&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;
      decrement 5s counter
      &lt;&lt;&lt;&lt;&lt;&lt;-&gt;&gt;&gt;&gt;&gt;&gt;
      Decrement ones counter
      &lt;-]

  reset ones counter
  +++++ +++++
  rest ones place to 0
  &gt;&gt;&gt;&gt; ----- -----
  increment 10s place
  &lt;+&lt;&lt;

  decrement 10s counter
  &lt;&lt;-]

  reset tens counter to
  +++++ +++++ &gt;&gt;&gt;&gt; ----- -----
  &lt;+&lt;
  &lt;&lt;&lt;-]

  PRINT BUZZ FOR 100
  &gt;&gt;&gt;.
  &gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;
  &gt;.&gt;.&gt;.
</pre>

So, that's basically that. This is super hard to read, because of the crazy syntax and how unreadable brainfuck is, but maybe having it parsed out so much will help some peeps understand it better. I sure learned a hell of a lot about memory allocation, pointers, and logic gates. All in all, now that I have a couple of weeks between it and me, it was worth the time.

Oh yeah, of course you can see the <a href="http://replit.com/Kr0/3" target="_blank">whole annotated program here</a>. This is EXACTLY the same code as the giant block of bf symbols I put in the <a title="fizzbuzz in brainfuck, part one" href="/blog/2013/09/22/fizzbuzz-in-brainfuck-part-one.html" target="_blank">first part</a>, just spread out with indentation etc.

Next time in the brainfuck series: <a href="https://github.com/urthbound/esoteric/blob/master/brainfuckint.rb" target="_blank">writing a compiler / interpreter for brainfuck in ruby. </a> Sometime. But don't hold your breath. All you brainfuck fans out there. In Ukraine. Don't think I don't see your ip's.

Oh and just to wrap this up: it feels pretty good to say that I am never going to write another fizzbuzz again; FizzBuzz is officially checked of the bucket list.

Goodnight and goodluck, interwebs.

&nbsp;
