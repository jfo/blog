---
title: C and Simple Types
date: 2016-05-26
layout: post
tags: rc
---

I'm going to explain some things about C and computers in general in simplified
terms, ignoring a lot of details.

When a C program starts, it has access to a big chunk of memory. This memory is
basically just a really long series of bits that can only either be 1 or 0.
Everything in computing is either a 1 or a 0, and that's it!  I've always loved
that.

Here are a bunch of bits:

```
0110100001100101011011000110110001101111001000000111011101101111011100100110110001100100
```

Here, here are some more bits:

```
0100110001101111011011110110101100100000011000010111010000100000011110010110111101110101001000010010000001011001011011110111010100100111011100100110010100100000011101100110010101110010011110010010000001100011011011000110010101110110011001010111001000101100001000000110110101100001011110010110001001100101001000000111100101101111011101010010000001110011011010000110111101110101011011000110010000100000011100110110101101101001011100000010000001110100011010000110100101110011001000000111001101100101011000110111010001101001011011110110111000101110
```

You get the idea. You can think of this collection of bits as one long
continuous block. It isn't _really_ that, necessarily, but you can think of it
that way.

The C program can only "see" a small portion of the
memory that is available to the whole computer, but from the program's
perspective, this memory is it's entire universe.

There isn't much you can represent with binary atomic values like 1 and 0. In
fact, you can only represent like, max 2 things. Hamburgers (1) and hotdogs (0)
maybe, or donuts (0) and jetskis (1), true (1) and false (0), or hell...
true(0) and false(1).  Whatever. We need to be able to represent _way_ more
than two things.

if we group bits together and look at them as little contiguous units, we can
do that. If we always read them two at a time, suddenly we can represent 4
things:

```
00 Hamburgers
01 Hotdogs
10 Bacon Sandwiches
11 Ice Cream
```

This could be arbitrary, as above, or it could make more sense, like this, now
with groups of 3 bits:

```
000 Zero
001 One
010 Two
011 Three
100 Four
101 Five
110 Six
111 Seven
```

In that case, a set of bits like `011001` would map to `3` for the first three bits
and `1` for the second three bits.

This is just counting up in binary numbers, in fact, and binary is just another
way of saying "base 2."

Decimal numbers, the numbers we are used to using almost all the time in
regular life, have a base of 10 (`Dec-` for 10, like in
`decade` or `decathalon`). Counting up like this, try it on your hands:

```
 0  1  2  3  4  5  6  7  8  9 10
10 11 12 13 14 15 16 17 18 19 20
etc...
```

Notice that the "full" set of fingers (10!) is the same thing as the "empty"
set of fingers for the next round up.

When you get to 9 (the tenth number, including 0!) you increment the tens place
and start over at zero. The fact that we do this is pretty arbitrary, really,
and probably came from having ten fingers. What if we had 4 fingers on each
hand, for a total of 8 fingers?

```
 0  1  2  3  4  5  6  7 10
10 11 12 13 14 15 16 17 20
```

That would be a base of 8. Or how about 3 fingers on one hand and 0 on the other?

```
 0  1  2 10
10 11 12 20
```

That would be base 3. How about just two lonely fingers on one lonely hand?

```
  0   1  10
 10  11 100
100 101 111
```

Aha, base 2! Remember, the "full" count of all the fingers is equivalent to
the empty count on the next set up, like when you get to the 10s and 20s and
30s and onwards and upwards!

> It's important to pause here to point out again that what a collection of
bits represents really is arbitrary, we can map it to anything we want, as long
as we all agree on that [mapping](http://www.asciitable.com/). Just keep this
in mind.

You might notice that which each added bit, we double the amount of things we could
represent. Here, `**` means "to the nth power"

```
1 = 2**1 = 2 things
2 = 2**2 = 4 things
3 = 2**3 = 8 things
.
8 = 2**8 = 256 things!
.
32 = 2**2 = 4294967296 things!!!
.
64 = 2**64 = 18446744073709551616 things!!!!!! ZOMG  . * ･ ｡ﾟ☆━੧༼ •́ヮ•̀ ༽୨
```

Remember, these are _bits_. A bit is one tiny piece of information: 1 or 0. A
lot of times we will also talk about _bytes_, which are chunks of 8 bits. This
means that 2 bytes are 16 bits, 8 bytes are 64 bits, etc. _One_ byte is 8 bits,
which can represent 256 things (2<sup>8</sup>). If that number rings a bell,
maybe you've worked with digital imagry, where often the most saturated value
in an RGB channel is represented as `255` (the `1st` value is `0`, so the last
is 1 less than 2<sup>8</sup>!)

Let's look at a little C program.

```c
#include <stdio.h>

int main() {
    int x;
    printf("%d", sizeof(x));
    return 0;
}
```

Notice the variable declaration `int x;`. This program sets aside some space in
the memory for `x`, which we are telling the program is an `int`. That's what
declaring a variable does; whether or not you assign it any value (this program
does not do that, `x` has not been initialized to a value, and so is
_uninitialized_), but it sets aside that space.

In C, the typing of a variable determines an appropriate amount of memory to
use for that variable's value. In the above example, the `sizeof` operator
looks at x, discovers that it is an int, and prints out the number of _bytes_
that an int uses, which in this case is:

```
4
```

4 bytes is 32 bits, so a regular, run of the mill `int` on my machine (this can
vary by machine!) takes up 32 bits. looking at the table above, 32 bits (4
bytes) can represent a maximum of `4294967296` things.

Remember- `x` here is _declared_ but still _uninitialized_. If you try to
actually _use_ an uninitialized variable, you'll get a warning, something like
this:

```
filename.c:6:19: warning: variable 'x' is uninitialized when used here
    printf("%d", x);
```

Though you haven't assigned `x` to anything, that line _will_ print out a
value. That value is junk data; it's whatever happened to be in the slot that
was set aside for x, but since x was not initialized, that slot had residual,
junk data inside of it. It will also likely be different each time you run the
program, since memory allocation occurs at runtime.

<hr>

Knowing that an `int` is 32 bits long is valuable information. Remember before,
when we looked at our 3 bit possibilities? Well, that actually would look more
like this, with a bunch of leading zeroes:

```
00000000000000000000000000000000 Zero
00000000000000000000000000000001 One
00000000000000000000000000000010 Two
00000000000000000000000000000011 Three
00000000000000000000000000000100 Four
00000000000000000000000000000101 Five
00000000000000000000000000000110 Six
00000000000000000000000000000111 Seven
```

Types
-----

I'm going to pick a number out of a hat. Let's say... `33`. Look at that table
just above- if I kept counting up like that, `33` would end up being `100001`
(we can omit the leading zeros as is typical when typing binary numbers). In
`C`, you can represent a binary number like that by prefacing it with `0b` as a
bare string in the code. That would look like `0b100001`. That means that the
following two lines are exactly the same.

```c
printf("%i", 0b100001); // 33
printf("%i", 33); // 33
```


`printf` takes a string of text and some arguments, and interpolates the
arguments into the string where there are 'embedded format tags' like `%i`.
These tags are typed so that `printf` knows how to interpret what it is being
given. `%i` means `int`. What do you suppose `%c` means? How about this program:

```c
#include <stdio.h>
int main() {
    printf("%i", 0b100001);
    printf("%c", 0b100001);
}
```

This program prints out:

```
33!
```

Where did all that excitement come from? It came from interpreting the binary
value `100001` as a `%c`, which means `char`. According to the [ASCII
table](http://www.theasciicode.com.ar/ascii-printable-characters/exclamation-mark-ascii-code-33.html), `33` is equal to `!`! The value of the number hasn't changed, _but how we're interpreting it has changed._

<hr>

Same same but different:

```c
#include <stdio.h>
int main() {
    int x = 33;
    printf("%i", x);
    printf("%c", x);
}
```

Still outputs:

```
33!
```

It doesn't matter that `x` is an `int`, because the value of that data can be
interpreted any way we want. Can we add two `chars` together, I wonder? `! + !` would be `66`, right?

```c
printf("%i", '!' + '!'); // 66
```

Can we print an int directly as a character?

```c
printf("%c", 33); // !
```

Well I'll be.
