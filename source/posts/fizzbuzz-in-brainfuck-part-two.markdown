---
title: fizzbuzz in brainfuck, part two
date: 2013/9/24
layout: post
categories:
- Programming
---

Last time, <a title="fizzbuzz in brainfuck, part one" href="/2013/09/fizzbuzz-in-brainfuck-part-one.html">this</a>!

This time I'll translate the first half of the "Ruby" code into brainfuck. Oh the anticipation!

Because every bf interpreter initializes with a completely clean memory slate, we have to set the memory cells we are going to use before we do anything else. I approximated this in Ruby by using variables to stand in for the memory slots and simply assigning them the value necessary. This time, we have to do it manually, and incrementally, but there's no trick at all to it, just remembering where we are, really. I'll kind of do this in the order I did it last time, too.

First we go to cell 7 to start:

```
>>>>>>
```

...and increment it to the hundreds counter:

```
+
```

same for cell 8; the tens counter:

```
>++++++++++
```

and cell 9 for the ones counter

```
>++++++++++
```

Now the printing cells... cell 10 gets a newline character, which in ascii code is the byte value "10" in decimal (or 0000 1010 in binary).

```
>++++++++++
```

Cells 11, 12, and 13 are assigned to the hundreds, tens, and ones printing places respectively. They have to be initialized to 0, but there's a little trick to it. Remember, we don't want the byte value to be 0, we want to byte value to be "0", which is a string that prints the character for zero, not the byte value for zero itself. All three of these cells, then, need the byte value "48," which is the ascii code for the _STRING_ "0".

```
to 11 hold hundreds place "0"
>>
+++++ +++++ +++++ +++++
+++++ +++++ +++++ +++++
+++++ +++

to 12 hold tens place "0"
>
+++++ +++++ +++++ +++++
+++++ +++++ +++++ +++++
+++++ +++

to 13 hold ones place "0"
>
+++++ +++++ +++++ +++++
+++++ +++++ +++++ +++++
+++++ +++
```

Now we initialize a few cells to ascii values for the letters we will need to print "Fizz" and "Buzz" and "FizzBuzz." Turns out we only need 5: "FizBu". I chose to move the pointer all the way to cell 25 to do this one, both so that I would have more space to work with if I needed it for anything else, and more importantly so that I could visually keep track of where my pointer generally was in the program. When I saw a long string of `>`'s I had an idea of where it all was. So cells 25-29 spell "FizBu":


```
Move to cell 25:
>>>>>>> >>>>>

Set 25 to "F" (ascii key "70")
>>>>>+++++ ++[<<<<<+++++ +++++>>>>>-]

Set 26 to "i" (ascii key "105")
+++++ +++++ +[<<<<+++++ +++++>>>>-]<<<----->>>

Set 27 to "z" (ascii key "122")
+++++ +++++ ++[<<<+++++ +++++>>>-]<<++>>

Set 28 to "B" (ascii key "66")
+++++ ++[<<+++++ +++++>>-]<---->

Set 29 to "u" (ascii key "117")
+++++ +++++ ++[<+++++ +++++>-]<---

Move back to cell 25
<<<<

Move back to cell 10 to begin program
<<<<< <<<<< <<<<<
```

Oh, and for all of these I'm using cell 30 as a counter cell to iterate through the incrementer loops. Not so many "++++++++++" etc that way...

Incidentally- I used cell 10 as my "Home Base" for all of this. After any operation I would reset the pointer back to cell 10 so I had a pretty good idea of where I was. This was super inefficient from a computing standpoint, resulting in a lot of wasted pointer motions, but carpe diem.

Oh!... only one more thing we need to do, and that is to prepare the 3 and 5 multiples finder to 3 and 5, respectively! I put those in cells 1 (for the 3's counter) and 4 (for the 5's counter) because each of them needs two helper cells for all the logic we're going to futz with later on.

```
<<<<<<
+++++
<<<
+++
>>>>>>>>>
```

We've set everything up and our "workspace", so to speak, is ready to go...

```
3 0 0 5 0 0 1 10 10 [10] 48 48 48 0 0 0 0 0 0 0 0 70 105 122 66 117 0
```

Also, spoiler alert. At this point when I was setting everything up, I had forgotten to allocate temp cells for the logic of the innermost "if" block that prints "Buzz" after "Fizz", so I'll have to add a couple more slots when I get to that bit. The logic part is what I'm really looking forward to trying to explain, because it all makes sense to me but in a pretty jumbled up way so far...

That concludes <a href="http://www.youtube.com/watch?v=QIL-nwJfGgg" target="_blank">the first half of this basketball game</a>, which is a thing that Chuck Mangione says right before starting to play that track on a live album I had in high school. You should totally click through to the video and let the soothing sounds of well orchestrated, innocuous, proto easy listening jazz drizzle into your ears like honey and cream while riding a bike in a park or petting a dog or something.
