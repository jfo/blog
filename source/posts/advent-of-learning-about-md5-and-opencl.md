---
title: Advent of Learning About MD5 and OpenCL
layout: post
tags: rc
date: 2016-12-28
---

So Hi, hello. [Last post](/adventure-of-advent-of-code) I was talking about [Advent of
Code](http://adventofcode.com/) and how it can help you discover new things and
ideas to learn about and also rabbit holes to go down. This post is about one
of those rabbit holes! It's a really deep one, too. I got nerdsniped on day 5
and I totally couldn't let it go.

This post got kind of ridiculously long. I'm sorry. But this snipe definitely
took me for a ride. I hope it's interesting!

<a name=toc />
Table of Contents
====

- [How about a nice game of chess?](#chess)
- [This is Expensive](#expense)
- [Down the Hole](#hole)
- [My own md5 function](#own)
- [Padding](#padding)
- [Time to actually process the hash](#time)
- [Output](#output)
- [I am quite sure my homegrown hashing function will outperform Ruby's built in version](#quite)
- [Let's C](#c)
- [Act III: OpenCL](#opencl)
- [Crackin'](#crackin)
- [Advent of Coda](#coda)

<sub><a href='#toc'>toc</a></sub>
<a name=chess />
How about a nice game of chess?
======

Day 5 this year asks us to calculate an 8 digit code based on the [md5
digest](https://en.wikipedia.org/wiki/MD5) of a user-specific input
concatenated with the string representations of incrementing numbers.

![img](https://pbs.twimg.com/media/CzwETWbUsAALRtW.jpg)

> <sub>
> [Source](https://twitter.com/jon_bottarini/status/809526790494375937), sort of,
> not that it matters, not that anything matters, since that's not even the
> source and the real source is
> [this](http://poorlydrawnlines.com/comic/a-message/) and copyright law is broken
> and we live in a creative post scarcity society.
> <a href="https://media.giphy.com/media/Wgx6zPreg4aac/giphy.gif" ><img height=20 style="display:inline;" src="https://imgflip.com/s/meme/But-Thats-None-Of-My-Business.jpg" /></a>
> </sub>


[You should go read the question here!]( http://adventofcode.com/2016/day/5 )

> Spoiler alert, etc, cause I'm about to just explain how I did this one so if
> you want to solve it yourself you should go do that first.

My door input was `abbhdwsy`. With just two small lines, I can compute the MD5
hash for that basic input like this using Ruby's built in library method:

```ruby
require 'digest'
puts Digest::MD5.hexdigest("abbhdwsy")
```

Which gives me:

```
b0d0113e0f3745b2eb8d0db1b6aad818
```

But the problem states that I need to to compute the md5's for that input
_plus a number_. To be clear, that's _the string representation of a number_
concatenated onto the end of the input, not the numerical value itself.

That might look like this, right?

```ruby
require 'digest'

puts Digest::MD5.hexdigest("abbhdwsy0")
```

Yields:

```
7e51386949e56ddab4f31c503de50f83
```

That's... really really different than the first hash!

Maybe I'd like to get a few more of these?

```ruby
require 'digest'

puts Digest::MD5.hexdigest("abbhdwsy1")
puts Digest::MD5.hexdigest("abbhdwsy2")
puts Digest::MD5.hexdigest("abbhdwsy3")
puts Digest::MD5.hexdigest("abbhdwsy4")
puts Digest::MD5.hexdigest("abbhdwsy5")
```

```
917b4f767f6713624ae0e4b4a4cd3cc9
1e2ec6125cc3e05cfd556134ae10e8ac
475a5869d93ec860881f9805460dc8fe
41ceab0f4edefdb821d47e8682adef7a
3c91defeee434cf792491e1d0e58876a
```

Look how different all those hashes are!

You may have noticed that my strategy here is to increment the number that I'm
appending to my unique input. This seems like it might take a while to do
manually, oh if only there were a way to automate it! Luckily computers

```ruby
require 'digest'

i = 0
loop do
    puts Digest::MD5.hexdigest("abbhdwsy" + i.to_s)
    i += 1
end
```

I increment that `i` value on each loop, and append it to the static input by
calling `to_s` on it (again, this gives back the _string_ of the number)! Easy
peasy. This, as you would expect, fills my screen with hashes, all different,
all unique, like snowflakes, or little babies!

> Lol jk no they are not unique! They are... _mostly_ different from each
> other, of course, but although MD5 hashes are guaranteed to be reproducible
> for any given input, they are decidedly _not_ guaranteed to always be unique.
> When two different inputs result in the same hash, it's called a _hash
> collision_, and you can read a lot more about that
> [here](http://www.mscs.dal.ca/~selinger/md5collision/).

From there, it's a pretty straightforward exercise to collect the hashes I need
to compute the password. I need the first 8 hashes in this series that begin
with 5 zeros. I'll just throw a test case in the loop and push them into an
accumulator if they match:

```ruby
require 'digest'

i = 0
acc = []
loop do
    candidate = Digest::MD5.hexdigest("abbhdwsy" + i.to_s)
    acc << candidate if candidate[0..4] == "00000"
    i += 1
end
```

That's almost it, really! This loop goes forever... all I need is the first 8
matches, so I can terminate the loop once I have those:

```ruby
require 'digest'

i = 0
acc = []
until acc.length == 8
    candidate = Digest::MD5.hexdigest("abbhdwsy" + i.to_s)
    acc << candidate if candidate[0..4] == "00000"
    i += 1
end
puts acc
```

running this will give me the output I need:

```
000008bfb72caf77542c32b53a73439b
0000004ed0ede071d293b5f33de2dc2f
0000012be6057b2554c26bfddab18b08
00000bf3f1ca8d1f229aa50b3093b2be
00000512874cc40b764728993dd71ffb
0000069710beec5f9a1943a610be52d8
00000a8da36ee9b7e193f956cf701911
00000776b6ff41a7e30ed2d4b6663351
```

All that's left is to concatenate the 6th characters in these hashes into the
password. I can just do this with my eyes, of course, or I can write a little
map to do it for me!

```ruby
puts acc.map { |e| e[5] }.join
```

This returns `801b56a7`, which is, in fact, my password.

<sub><a href='#toc'>toc</a></sub>
<a name=expense />
This is Expensive
======

This was the first puzzle of the year that could be considered
at all _computationally expensive._. Indeed, it is a _feature_, not a bug, for
a cryptographic hashing function to be at least somewhat difficult to compute.
Though md5's are now mostly considered broken for cryptography, it's still what
they were designed to do. If it takes actual time to compute a hash, it's that
much harder to brute force guess a password if all you have is a hash.

But how long does this solution take, anyway?

```
real	0m14.256s
user	0m14.011s
sys	0m0.096s
```

> This is the output of `time`. If you aren't familiar with that, [read
> this](http://stackoverflow.com/questions/556405/what-do-real-user-and-sys-mean-in-the-output-of-time1).

That's not terrible, that's not even really _bad_, considering all
the processing we're doing. How much is that? How many
hashes did we process? If I just add `puts i` after the loop breaks out:

```
7777890
```

So, almost 8 million. That's, a lot? I mean, not really, by computering
standards, but it's enough to kind of take a little while, I guess?

None of that is the point really, though, because it's not that I needed to
have faster or better code to solve the problem. 15 seconds is not that long to
wait. But- what if I want it to go faster! What if I had to process 800 million
hashes? Or 80 billion? Then we'd be bumping up against some more aggressive
limits.

And that's the rabbit. "What is a hashing algorithm, and how fast can I make it run."

And here is where I followed it.


<a name=hole />
<sub><a href='#toc'>toc</a></sub>
Down the hole
=============

I wonder if I can write a faster implementation of the [md5 hashing
algorithm](https://en.wikipedia.org/wiki/MD5) than the one that Ruby is using?
I don't know if I can, maybe? First I would have to be able to write _any_
implementation of the md5 hashing algorithm. How would I do that?

To start with, I can read the [wiki page](https://en.wikipedia.org/wiki/MD5), which contains
some psuedocode, that's helpful.

I can read the [rosetta code](https://rosettacode.org/wiki/MD5) page for this
task, which contains working examples in many different languages, that is also
helpful.

And I also have access to the [original md5
specification](https://www.ietf.org/rfc/rfc1321.txt) which contains both the
canonical explanation of the algorithm and a reference implementation.

So that's a good start. This is enough information to allow me to write my own
version.

<a name=own />
<sub><a href='#toc'>toc</a></sub>
My own md5 function
===================

Let's say I want the md5 hash sum of my door key. It would look like this:

```ruby
def md5(input)
    # stuff stuff stuff
end

puts md5 "abbhdwsy"
```
and it should return

```
b0d0113e0f3745b2eb8d0db1b6aad818
```

The first thing I need to do is turn the ruby string into an array of bytes.

```ruby
def md5(input)
    message = input.bytes
end

puts md5 "abbhdwsy"
```

yields:

```ruby
[97, 98, 98, 104, 100, 119, 115, 121]
```

Which are the _numerical values_ of the characters in my string. These are
"bytes" in the sense that each value in the byte array is guaranteed to be no
more than 255, even if the input is unicode, you're going to get the bytes back
in byte format. This unicode lambda is a single character when it is outputted to the
screen,

```ruby
p "λ".bytes
```

but its machine representation is in fact two bytes long:

```
[206, 187]
```

[Unicode!](https://www.youtube.com/watch?v=MijmeoH9LT4)

Externally to the interpreter, I have no way of really knowing how ruby is
storing these values. They could be signed 64 bit ints for all I know!
And even if they are being stored as bytes- they get autopromoted just fine.

```ruby
[97, 98, 98, 104, 100, 119, 115, 121].map {|e| e ** 10}
```

```ruby
[73742412689492826049, 81707280688754689024, 81707280688754689024, 148024428491834392576, 100000000000000000000, 569468379011812486801, 404555773570791015625, 672749994932560009201]
```

:shrug:! Ruby has plenty of ways to work with bits and bytes, as you'll see,
but this is definitely not its strong point. This is usually a Good Thing- all
these messy little details are left to the interpreter and I can just focus on
expressing a problem and solution, or whatever. But when you're trying to
implement something to a spec and doing bit fiddly things... well...

The next step is to add some padding! All md5 input gets padded to add up to a
multiple of 512 bits. If it's _already_ a multiple of 512, it gets padded one whole
new chunk.

The padding always starts with a 1 and then contains a bunch of 0's until the
last NTH bytes, which are the length of the original input value's length _in bits_
in little endian format. Does this sound confusing? It kind of is! But let's go
through it 'bit by bit'

> lol

First, we'll grab the length after we split the input string into a byte array
but before we do anything else to it.

```ruby
def md5(input)
    message = input.bytes
    orig_length = message.bytes.length
end

puts md5 "abbhdwsy"
```

> It's important to split it into bytes first! In the case of our earlier unicode
> example and how ruby thinks about things...

> ```ruby
> "λλλ".length # 3
> "λλλ".bytes.length # 6
> ```

this gives me


```
8
```

Which makes sense, because `"abbhdwsy"` is 8 characters long and none of them
are more than one byte long in unicode because they all used to be ascii!

> More on that:

But remember, I'm going to want the length _in bits_. Ok, I've already got 8
bytes, and there are 8 bits in a byte, so

```ruby
def md5(input)
    message = input.bytes
    orig_length_in_bits = message.length * 8
end

puts md5 "abbhdwsy"
```

```
64
```

I'll just hold onto that for later.

<sub><a href='#toc'>toc</a></sub>
<a name=padding />
Padding
========

Next, comes the padding. I'm doing everything with byte sized operations since
I am simply building this as a little prototype for turning strings into md5
hashes... a real md5 implementation has to support streams of arbitrary numbers
of bits, but assuming the smallest unit I'm going to deal with is a byte is ok
for learning.


I know I need to append a single `1` bit to the input and then start padding
with zeros. I might be tempted to do this:

```ruby
message << 1
```

But don't be fooled! This is a 1, yes, but it's a whole byte at least on its
own! This operation would give me this:

```ruby
[97, 98, 98, 104, 100, 119, 115, 121, 1]
```

that might look right? But it's not! Consider if I look at the binary values of
all of these, padded to make them output as if they are indeed 8 bits long:

```ruby
p [97, 98, 98, 104, 100, 119, 115, 121, 1].map {|e| e.to_s(2).rjust(8, '0')}
```

gives me:

```ruby
["01100001", "01100010", "01100010", "01101000", "01100100", "01110111", "01110011", "01111001", "00000001"]
```

As you can see, if we think of each integer in the array as a full byte, that
`1` is indeed worth 8 bits by itself! What we really wanted is a single bit set
to one followed by some number of other bits set to zero. We really want that last byte to read:

```ruby
10000000
```

So this is interesting, right? We can't just append a single bit to this byte
array, because ruby doesn't make that easy (there may be a way, but work with
me!). Plus, as I said, we're sort of just working with bytes here, right? So
what needs to be appended to the array if not `1`?

```ruby
p "10000000".to_i(2)
```

Of course!

```ruby
128
```

so we want to append `128` to the byte array to start the padding!

```ruby
message << 128
```

> You could also write `128` in its binary format as `0b10000000` or its
> hexadecimal format as `0x80`. These are all exactly the same value.


Now, I pad this array with `0`'s until it's length in bytes is a multiple of
512 bits. (That's 64 bytes!)


```ruby
while message.length % 64 != 0
    message << 0
end
```

That gives me,

```ruby
[97, 98, 98, 104, 100, 119, 115, 121, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

But ah! I missed something, right? I need to use the last 64 bits of this
padding to fill in the length that I collected from the original message!

So I stop that modulo 8 bytes early:

```ruby
while message.length % 64 != 56
    message << 0
end
```

Now I need to get `orig_length_in_bits` into the right format! This part was
tricky to me, because I am not good at `pack` and `unpack` in Ruby, which
afaict is a thing that it inherited from perl and could probably do this. But
oh well, this worked too!

I'll take that original value I had grabbed earlier:

```ruby
orig_len_in_bits # 64
```

And I'll turn it into a string of its hexadecimal representation!

```ruby
orig_len_in_bits.to_s(16) # "40"
```

This will ensure that every two characters represents one byte.

Now, I pad this string with zeros to fill out the rest of the space I need to
fill on the remainder of the message space that I left for this! Remember, I
left 64 bits, which is 8 bytes, which is 16 characters long in hexadecimal
representation...

```ruby
 orig_len_in_bits.to_s(16).rjust(16, '0') # "0000000000000040"
```

> Hey ps if you find this really confusing then let's start a club! There is a
> reason why bit twiddling is hard, and very arguably much _harder_ in higher
> level languages that normally take great pains to shield you from this
> befuddlery.

Right, so now I just need to split this up into its constituent hexadecimal
byte character pairs! I can do this with `scan`, which will return an array of
matches to a regular expression that are ordered by where they are in the string.

```ruby
orig_len_in_bits
    .to_s(16)
    .rjust(16, '0')
    .scan(/../)
```
That returns:

```ruby
["00", "00", "00", "00", "00", "00", "00", "40"]
```

> Almost there hang in there

Now, we map over this array and replace each string with an actual numerical
value that is not a string. Notice that `hex` parses the string and returns its
actual integer value for that byte.

```ruby
orig_len_in_bits
    .to_s(16)
    .rjust(16, '0')
    .scan(/../)
    .map{|e| e.hex}
```

```ruby
[0, 0, 0, 0, 0, 0, 0, 64]
```

Hey guess what? that's it. Actually wait not because it's gotta be _little
endian_ again. Whatevs nbd.

```ruby
message << (orig_len_in_bits
    .to_s(16)
    .rjust(16, '0')
    .scan(/../)
    .map{|e| e.hex}
    .reverse).flatten!
```

Now that I've completed the padding operation, my message looks like this:

```ruby
[97, 98, 98, 104, 100, 119, 115, 121, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

Each of these elements represents one byte, and the array itself is 64 bytes
long, which is 512 bits. Keep in mind that this is a byte array, and because of
the way we generated it, no number in the array will ever be more than 255,
which is the maximum value of a byte. But to reiterate, I have neither insight
nor control over how ruby is storing these values, so I have to be careful
about maintaining it in that state!

I'll just pull this into its own little helper function:

```ruby
def msg_to_byte_array(message)
    message = message.bytes
    orig_len_in_bits = (8 * message.length) & 0xffffffffffffffff
    message << 0x80
    while message.length % 64 != 56
        message << 0
    end
    message
    (message <<
        orig_len_in_bits
        .to_s(16)
        .rjust(16, '0')
        .scan(/../)
        .map{|e| e.hex}
        .reverse).flatten!
    return message
end
```

This is obviously the most efficient way you could ever perform this operation
in any language. This hashing function is going to be _ludicrous speed!_

Oh yeah, one more detail to note! The spec says that in the event that the
length of the input is more than the maximum number you can encode in the 64
bits of padding left over to hold the size, that you'll just take the 64 least
significant bits and discard the rest. This is like, really really long.
18446744073709551615 bits long, in fact, or 2305843009213693952 bytes. Which is
2 [exbibytes](https://en.wikipedia.org/wiki/Exbibyte), which are actual things
I didn't know existed until right now.

> Wait really? That's _really_ a lot. I don't think we're going to be using md5s
> very often on exbibytes worth of data. But what do I know.

Anyway, just bitwise `and`ing (`&`) the length in bits against
18446744073709551615 will discard those higher order bits that we're very
likely to run into in the many applications this implementation will be used
for.

```ruby
orig_len_in_bits = (8 * message.length) & 0xffffffffffffffff
```

<sub><a href='#toc'>toc</a></sub>
<a name=time />
Time to actually process the hash
=============================

We're here:

```ruby
def md5(message)
    message = msg_to_byte_array(message)
end
```

...and now it's time to _actually process the hash_. If you haven't already, jump back
to the wiki for the [md5 algorithm](https://en.wikipedia.org/wiki/MD5) and give
it a once over. It's not really that it's complicated per se- all of the most
complex operations are straightforwardly laid out for me there, but it is definitely
really fiddly, and easy to mess up.

First, we initialize an accumulator with some predefined constants.

```ruby
def md5(message)
    message = msg_to_byte_array(message)
    @acc = [ 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 ]
end
```

On first glance this looks like nothing, but if you squint you might notice
that it's actually these nibbles in this order:

```
01234567 89abcdef fedcba98 76543210
```

expressed in _little endian_.

Next we're going to loop over the input message in chunks and adjust the
accumulator values as we go on each pass in a predetermined way. We're always
going to end.

We do the outer loop one 512 byte chunk at a time. For this input, it's only
one chunk, but we might as well write it to accomodate more.

```ruby
def md5(message)
    message = msg_to_byte_array(message)
    @acc = [ 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 ]

    (0...message.count/64).each do |message_index_base|
    end

end
```

In this example, `message.count / 64` equals `1`, but ruby's three dotted range
is exclusive, so this loop is really saying "do this one time, for
`message_index_base` of `0`.

Within this loop, we perform some specific operations 64 times. So, an inner
loop would look like:

```ruby
def md5(message)
    message = msg_to_byte_array(message)
    @acc = [ 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 ]

    (0...message.count / 64).each do |message_index_base|
        (0..63).each do |i|
        end
    end

end
```

In the outer loop, we'll prepare a few variables to use in the inner loop.

First, we extract the chunk of the input message that we're interested in by
using the `message_index_base`:

```ruby
(0...message.count/64).each do |message_index_base|
    message_index = message_index_base * 64
    chunk = message[message_index..message_index + 64]

    (0..63).each do |i|
    end
end
```

Again, in this case, it's going to be the whole message.

Oh, we'll also destructure the accumulator values into some temporary vars that
we can manipulate in the inner loop.

```ruby
a, b, c, d = @acc
```

Now, for each iteration of this inner loop, we'll perform a few bit fiddles and
then mutate the temporary variables. The operations are different depending on
the position we're at in the chunk

```ruby
a, b, c, d = @acc
(0..63).each do |i|
    if i < 16
        f = (b & c) | (~b & d)
        g = i
    elsif i < 32
        f = (d & b) | (~d & c)
        g = (5 * i + 1) % 16
    elsif i < 48
        f = b ^ c ^ d
        g = (3 * i + 5) % 16
    elsif i < 64
        f = c ^ (b | ~d)
        g = (7 * i) % 16
    end

    to_rotate = a + f + @constants[i] + chunk[4*g...4*g+4].to_int
    new_b = b + left_rotate(to_rotate, @rotate_amounts[i])
    a, b, c, d = d, new_b, b, c
end
```

Gross, right? :D

I don't have much to say about why these operations are what they are or the
cryptography behind them. Maybe I'll read up on that sometime, but for now,
this is just a play by play of an implementation of the existing spec.

The three lines at the end of the inner loop take the computed `f` and `g`
values and _doooo stuffff_ with them. Let's unpack those lines!

```ruby
to_rotate = a + f + @constants[i] + chunk[4*g...4*g+4].to_int
```

This is a preperatory step. The only thing here we haven't seen before is the
`@constants` array that we're grabbing something out of. We can compute them
like this:

```ruby
// Use binary integer part of the sines of integers (Radians) as constants:
@constants = (0.. 63).map { |i| (2**32 * Math.sin(i + 1).abs).floor }
```

We take that and 'rotate' it using a little helper function:

```ruby
new_b = b + left_rotate(to_rotate, @rotate_amounts[i])
```

That looks like this:

```ruby
def left_rotate(x, amount)
    x &= 0xffffffff
    ((x << amount) | (x >> (32 - amount))) & 0xffffffff
end
```

(notice the conservative `&`'s)

Oh, and `@rotate_amounts` is another collection of constants.

They look like this!

```ruby
@rotate_amounts = [ 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
                    5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
                    4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
                    6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 ]
```

Which can be generated a little less verbosely as:

```ruby
@rotate_amounts = [[7, 12, 17, 22],
                   [5,  9, 14, 20],
                   [4, 11, 16, 23],
                   [6, 10, 15, 21]].map{|e|[e,e,e,e]}.flatten
```

(yay ruby!)

Lastly, reassign the the temporary vars before starting the next loop:

```ruby
a, b, c, d = d, new_b, b, c
```

After this chunk has been processed, we just add the values back into the accumulator:

```ruby
[a,b,c,d].each_with_index do |val, i|
    @acc[i] += val
    @acc[i] &= 0xffffffff
end
```
(notice we're again guarding against overflow with an `&`)

Hey that's it! (almost).

The whole function looks like this now:

```ruby
def md5(message)
    message = msg_to_byte_array(message)
    @acc = [ 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 ]

    (0...message.count.send(:/, 64)).each do |message_index_base|
        message_index = message_index_base * 64
        chunk = message[message_index..message_index + 63]

        a, b, c, d = @acc

        (0..63).each do |i|
            if i < 16
                f = (b & c) | (~b & d)
                g = i
            elsif i < 32
                f = (d & b) | (~d & c)
                g = (5 * i + 1) % 16
            elsif i < 48
                f = b ^ c ^ d
                g = (3 * i + 5) % 16
            elsif i < 64
                f = c ^ (b | ~d)
                g = (7 * i) % 16
            end

            to_rotate = a + f + @constants[i] + chunk[4*g...4*g+4].to_int
            new_b = b + left_rotate(to_rotate, @rotate_amounts[i])
            a, b, c, d = d, new_b, b, c
        end

        [a,b,c,d].each_with_index do |val, i|
            @acc[i] += val
            @acc[i] &= 0xffffffff
        end
    end
    @acc
end
```

> If you're wondering about that stupid `.send(:/, 64)` thing, blame my syntax highlighter.

Now,

```
md5("abbhdwsy")
```

Yields:

```ruby
[1041354928, 2990880527, 2970455531, 416852662]
```

Ah, oh yeah, we gotta transform those values into a hexadecimal output string!
This is a little tricky but not too bad. First, we need to shift each of these
values over so that when we "or" (`|`) all 4 32 bits together, we get a single 128 bit
number.

First we'll turn the accumulator into an enumerator:

```ruby
@acc.each_with_index
```

then map over the tuple pairs of element and index to shift the bits:

```ruby
@acc.each_with_index
    .map{|e,i| e << (32 * i)}
```

then reduce the resulting elements by or-ring them all together:

```ruby
@acc.each_with_index
    .map{|e,i| e << (32 * i)}
    .reduce{|acc, e| acc | e}
```

Ok still going... turn the resulting number into a hexadecimal string:

```ruby
@acc.each_with_index
    .map{|e,i| e << (32 * i)}
    .reduce{|acc, e| acc | e}
    .to_s(16)
```

then pad the string to make sure we have the right number of digits:

```ruby
@acc.each_with_index
    .map{|e,i| e << (32 * i)}
    .reduce{|acc, e| acc | e}
    .to_s(16)
    .rjust(32, '0')
```

_then_ split _that_ string up into pairs of characters to isolate the bytes

```ruby
@acc.each_with_index
    .map{|e,i| e << (32 * i)}
    .reduce{|acc, e| acc | e}
    .to_s(16)
    .rjust(32, '0')
    .scan(/../)
```

_then_ reverse the whole thing and join it together to get you...

```ruby
@acc.each_with_index
    .map{|e,i| e << (32 * i)}
    .reduce{|acc, e| acc | e}
    .to_s(16)
    .rjust(32, '0')
    .scan(/../)
    .reverse.join
```

*gasp* _the final output_.

<sub><a href='#toc'>toc</a></sub>
<a name=output />
Output
======

Did it work?

```ruby
require "digest"
@door = "abbhdwsy"
puts md5(@door)
puts Digest::MD5.hexdigest(@door)
```

```
b0d0113e0f3745b2eb8d0db1b6aad818
b0d0113e0f3745b2eb8d0db1b6aad818
```
Sweet.

<sub><a href='#toc'>toc</a></sub>
<a name=quite />
I am quite sure my homegrown hashing function will outperform Ruby's built in version
=====================================================================================

Now that I have my custom built md5 hashing function, I bet I can use it to
compute the answer to this question a lot faster.

I swapped the function out and tried it out with the same solution code from above.

```
real	38m18.696s
```

Wow ok, that's hella slow, but why? I thought I was using Ruby's built in
function, so shouldn't my own version written in Ruby be comparable on the same task?

The answer to this is pretty simple. Ruby's built in function isn't written in
Ruby at all, it's a compiled C extension! The business end of the
`Digest::MD5.hexdigest()` is _all_ C, and it turns out it's already _really
fast_. [It lives here in the
source](https://github.com/ruby/ruby/blob/trunk/ext/digest/md5/md5.c), and was
first commited by Matz himself in 1998 as a migration commit from Subversion.

```git
commit 3db12e8b236ac8f88db8eb4690d10e4a3b8dbcd4
Author: matz <matz@b2dd03c8-39d4-4d8f-98ff-823fe69b080e>
Date:   Fri Jan 16 12:13:05 1998 +0000

    Initial revision


    git-svn-id: svn+ssh://ci.ruby-lang.org/ruby/trunk@2 b2dd03c8-39d4-4d8f-98ff-823fe69b080e
```

<sub><a href='#toc'>toc</a></sub>
<a name=c />
Let's C.
==========

So it's pretty obvious that writing my own md5 function in pure Ruby is never
going to cut it. Regardless of how many (of the probably many) inefficiencies
in the above code I find, stamp out, or reduce, I'm never going to come close
to the pure C extension that ruby already has built in.

Here's an aside about speed. Like many beginners, when I was first learning to
code I absorbed a lot of information and chatter about programming in general
and specific programming languages and how they related to each other. But at
the time, I had no perspective on anything. People often said things like "Ruby
is slow". And I thought that meant "Ruby is like, actually really slow and
useless." It turns out, well yeah no shit Ruby is slow for really
computationally intensive tasks like computing an MD5, it's just _not designed_
to excel for that type of application. It's designed to be flexible, and
expressive, and a joy to work in, and it's plenty fast enough for almost
anything you might want to use it for in a general context like that... but if
you have a task like this that _really is_ this computationally expensive, well
_of course_ it's too slow, and blaming ruby for that just straight up _isn't
fair,_ and totally misses the point.

This goes for Python too! Or other dynamic languages! Python might be faster
than Ruby for some things, and vice versa, but they are essentially in the same
class, and designed with similar goals in mind. We can nitpick the differences
of course, but when you're talking about apples to oranges, yeah they're
different but they're a lot more similar to each other than say, apples to
rocketships, you know what I mean?

The most logical thing to do when you find an application that a dynamic
language is ill suited to because of speed constraints is simply to not use
that language. So with that in mind, let's port that solution to C!

It's going to basically have the same shape, let's start with this:

```c
char *md5digest(char* msg) {
    // stuff stuff stuff
}
```

Just like in the ruby version, we're passing in a "string". C strings are
_already_ basically represented as contiguous bytes in memory, so we don't need
to convert them or anything like that!

We do have to pad the input though, here's what I ended up with:

```c
char *md5digest(char* msg) {
    struct Message* padded_msg = md5padding(msg);
}
```

A wild helper function appears!

```c
static struct Message* md5padding(char* msg) {
    unsigned long orig_length_in_bytes = strlen(msg);
    unsigned long orig_length_in_bits = (orig_length_in_bytes * 8) & 0xffffffffffffffff;

    unsigned long padded_length = orig_length_in_bytes;

    padded_length += 4;
    while (padded_length % 64 != 0) {
        padded_length += 1;
    }

    unsigned char *output_buffer = malloc(padded_length + 1);
    memcpy(output_buffer, msg, orig_length_in_bytes);

    output_buffer[orig_length_in_bytes] = 0x80;
    int i;
    for (i = orig_length_in_bytes + 1; i % 64 != 56; i++) {
        output_buffer[i] = 0x0;
    }

// TODO: proper bit shifting here instead of this garbage <<<
    output_buffer[i] = orig_length_in_bits;
    for (++i; i % 64 != 0; i++) {
        output_buffer[i] = 0;
    }
// TODO: proper bit shifting here instead of this garbage ^^^

    struct Message* output_msg = malloc(sizeof(struct Message));
    output_msg->start = output_buffer;
    output_msg->size = padded_length;
    return output_msg;
}
```

This function is basically doing the same thing as the ruby version! I grab the
original length of the input in bytes and bits...

```c
    unsigned long orig_length_in_bytes = strlen(msg);
    unsigned long orig_length_in_bits = (orig_length_in_bytes * 8) & 0xffffffffffffffff;
```

Then I compute what the final padded length of the message will be by adding 4
(4 bytes for the initial `1` bit followed by zeros...) and then counting how
many bytes it will take to have a multiple of 64 bytes.

```c
    padded_length += 4;
    while (padded_length % 64 != 0) {
        padded_length += 1;
    }
```
Next I `malloc` an output buffer with this computed size and copy the original input into it:

```c
    unsigned char *output_buffer = malloc(padded_length);
    memcpy(output_buffer, msg, orig_length_in_bytes);
```

Finally, we'll actually pad the output, with the initial `128` byte
(`1000000`), a bunch of zeros, followed by the original size in bits and a few
more zeros.

```c
    output_buffer[orig_length_in_bytes] = 0x80;
    int i;
    for (i = orig_length_in_bytes + 1; i % 64 != 56; i++) {
        output_buffer[i] = 0x0;
    }

// TODO: proper bit shifting here instead of this garbage <<<
    output_buffer[i] = orig_length_in_bits;
    for (++i; i % 64 != 0; i++) {
        output_buffer[i] = 0;
    }
// TODO: proper bit shifting here instead of this garbage ^^^
```

That TODO is there because as it stands, I'm only saving one byte worth of
length- the input could only be up to 256 bits (32 bytes) long. This is just
laziness on my part since my input will never be longer than that for this
problem space, but it _should_ be a little endian 64 bit (unsigned long) value
(that conversion from an `unsigned long` to a little endian long is the 'proper
bit shifting' I'm referring to).

> A reminder that also neither of these implementations support arbitrarily
> long bit streams as input, which is part of the official spec. So like, don't
> use these for anything I guess? Whatevah.

You might have noticed the return value of this padding function is something
called a `Message` which is not yet a real thing! I'll make a simple little
struct that will hold a pointer to the beginning of the padded message I just
constructed, and the size of the whole thing. I can't use `strlen()` on the padded message because it contains all those padded zeros, which would be incorrectly interpreted as terminating null bytes).

> Also like, this is one of those things about C that I feel like really screws
> beginners up. For a while it was easiest for me to think about `char*` typed
> variables as "strings" which, they are of course, but _really_ they're a pointer
> to the beginning of a contiguous memory array of indeterminate length, of which
> a null terminated string is a special case. [Here's a neat post about the
> history of null terminated
> strings.](http://queue.acm.org/detail.cfm?id=2010365)

```c
struct Message {
    unsigned char* start;
    unsigned long size;
};
```

So anyway, I malloc space for that `Message` and fill the space with both the
pointer to the beginning of the `output_buffer` and also the `padded_length` I
computed earlier.

```c
    struct Message* output_msg = malloc(sizeof(struct Message));
    output_msg->start = output_buffer;
    output_msg->size = padded_length;
    return output_msg;
}
```

And I've got my thing I need to operate on!

```c
char *md5digest(char* msg) {
    struct Message* padded_msg = md5padding(msg);
}
```

From there, the code is essentially identical to the ruby version, with obvious differences for C syntax and types, etc:

```c
char *md5digest(char* msg) {
    struct Message* padded_msg = md5padding(msg);

    unsigned long acc[4] = { 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };

    for (int chunk_index = 0; chunk_index < padded_msg->size / 64; chunk_index += 64) {
        unsigned long a,b,c,d; a = acc[0]; b = acc[1]; c = acc[2]; d = acc[3];

        unsigned long f = 0;
        unsigned long g = 0;
        for (int i = 0; i < 64; i++) {
            if (i < 16) {
                f = (b & c) | (~b & d);
                g = i;
            } else if (i < 32) {
                f = (d & b) | (~d & c);
                g = (5 * i + 1) % 16;
            } else if (i < 48) {
                f = b ^ c ^ d;
                g = (3 * i + 5) % 16;
            } else if (i < 64) {
                f = c ^ (b | ~d);
                g = (7 * i) % 16;
            }
            unsigned long to_rotate = a + f + constants[i] +
               (padded_msg->start[g*4 + 0]       |
                padded_msg->start[g*4 + 1] << 8  |
                padded_msg->start[g*4 + 2] << 16 |
                padded_msg->start[g*4 + 3] << 24);

            unsigned long new_b = b + left_rotate(to_rotate, rotate_amounts[i]);
            a = d;
            d = c;
            c = b;
            b = new_b;
        }
        acc[0] += a;
        acc[0] &= 0xffffffff;
        acc[1] += b;
        acc[1] &= 0xffffffff;
        acc[2] += c;
        acc[2] &= 0xffffffff;
        acc[3] += d;
        acc[3] &= 0xffffffff;


    }
    free(padded_msg->start);
    free(padded_msg);

    char *outstr = malloc(128);

    sprintf(outstr, "%08lx%08lx%08lx%08lx",
            bitswap(acc[0]),
            bitswap(acc[1]),
            bitswap(acc[2]),
            bitswap(acc[3])
          );

    return outstr;
}

```

A couple of things to point out! There's actually a lot _less_ fuckery going on
with this version, since C is ideal for operating on arrays of bytes in a way
ruby is most definitely _not_. Gone is that convoluted string cast to
facilitate turning a hex representation into a little endian version- instead I
simply use a little macro I defined called `bitswap` to shuffle those bytes
around directly:

```c
#define bitswap(NUM) ((NUM>>24)&0xff) | ((NUM<<8)&0xff0000) | ((NUM>>8)&0xff00) | ((NUM<<24)&0xff000000)
```

Oh and also I have that old friend `left_rotate()` defined as well:

```
unsigned long left_rotate(unsigned long x, int amount) {
    x = x & 0xffffffff;
    return ((x << amount) | (x >> (32 - amount))) & 0xffffffff;
}
```

Oh and instead of being clever with computing both `constants` and
`rotate_amounts`, I think it's much preferable to define them explicitly as
constant arrays. This will simply be loaded into memory and accessed directly,
and defining them as constant arrays I suspect will make compile time
optimizations easier.

> This is just a guess though, I honestly haven't dipped lower than C yet.
> Wouldn't mind learning more about compilers and assembly (probably x86) this
> coming year, but we'll see.

```c
static const unsigned long constants[64] =
{ 0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
 0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
 0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
 0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
 0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391 };

static const unsigned long rotate_amounts[64] =
{ 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 };
```

Now! I can port my original solution to the problem to C and see waht kinds of
/l33t p3rf gAiNs/ I've earned myself.

```c
#include <stdio.h>
#include <string.h>
#include "md5.h"

int main() {
    char door[32];
    char test[6];

    for (int i = 0; i < 7777890; i++) {
        sprintf(door, "abbhdwsy%i", i);
        char *cand = md5digest(door);

        for (int x = 0; x < 5; x++)
            test[x] = cand[x];

        if (strcmp(test, "00000") == 0)
            printf("%c", cand[5]);
    }
    printf("\n");

    return 0;
}
```

prints out:

```
801b56a7
```

Seems familiar! This looks fine. How long does it take?

```
real    0m17.296s
```

That's a LOT better than the pure ruby version, of course! And it's in the same
ballpark as the original ruby solution I started with that uses the built in
hash function, which makes sense, since they are both in C. I am not at all
surprised that the library function is slightly faster than my half assed
version, even despite the ruby interpreter's overhead, whatever that is.

I could probably work harder on my C version and shave off some of those extra
seconds, I could probably even beat the built in Ruby version if I found enough
tricks and traps to optimize it... but I've got a better idea.

<sub><a href='#toc'>toc</a></sub>
<a name=opencl />
Act III: OpenCL
==============

Strap in things are about to get _really fast_

Ok so a disclaimer before I really get into this part:

![img](http://i0.kym-cdn.com/photos/images/newsfeed/000/234/142/196.jpg)

I mean, that's not _entirely_ true of course, I am happy to report that after a
lot of research and trial and error I was able to make this thing work the way
I hoped I would be able to.

But I will refrain from explaining everything in minute detail in this section
because I don't have enough experience with OpenCL to feel completely
comfortable doing that. And to be honest, I'm really tired and I really want to
post this, and this post is already super long, and I might just write more
detailed info about OpenCL after I learn more about it. I'll cover the broad
strokes about what I learned though!

So, OpenCL is a framework for writing general purpose code that can be run on
your GPU. The GPU (graphics processing unit) is _completely separate_
physically from the CPU (central processing unit) in your computer.

> (if you have one that is! also there are now integrated graphics chipsets that
> do the work of the gpu on the cpu, and some other stuff I don't know about
>     much!).

The GPU is highly optimized for doing many many small tasks in parallel. As its
name suggests, it it mostly used for graphics processing, which is a perfect
use case for highly paralellized computations.

It's often compared to its closed source sibling CUDA, which is nvidia's
proprietary framework that does basically the same thing. Linux MDFL Linus
Torvalds is a [big fan](https://www.youtube.com/watch?v=55XVnJ_0qhg).

<hr>

I started by using
[this](https://www.fixstars.com/en/opencl/book/OpenCLProgrammingBook/first-opencl-program/)
as a template. It's a LOT of boilerplate to get the environment set up! I am
going to refrain from explaining that in detail for a couple of reasons. I
don't _really_ understand it well enough yet to provide a helpful perspective,
it's a little bit not necessary to understand the broad strokes, and also that book
does an _excellent_ job of going through [line by
line](https://www.fixstars.com/en/opencl/book/OpenCLProgrammingBook/basic-program-flow/).

I have to write _two different_ programs here- one to run on the
_host_ side and another that runs on the _device_ side. The device side code is
basically c99, but is subject to a set of restrictions that follow from the
limitations of the hardware and how the program actually runs on it.

Let's look at the kernel function from the hello world example above:

```c
__kernel void hello(__global char* string) {
    string[0] = 'H';
    string[1] = 'e';
    string[2] = 'l';
    string[3] = 'l';
    string[4] = 'o';
    string[5] = ',';
    string[6] = ' ';
    string[7] = 'W';
    string[8] = 'o';
    string[9] = 'r';
    string[10] = 'l';
    string[11] = 'd';
    string[12] = '!';
    string[13] = '\0';
}
```

Notice a few things! This function returns nothing (`void`). It actually
doesn't make any sense for a kernel function to return anything at all- where
would that return value go? Instead, we pass in a pointer to a shared memory
object (in this case `string`) which can be manipulated from within the device
code and accessed after that task has been run from the host's code.

Let's follow that backwards! Where does that pointer get 'passed in'?

The relevant line in the host code are here on line 66:

```c
/* Set OpenCL Kernel Parameters */
ret = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&memobj);
```

A few things! The return value of this function is an integer that is 0 on
success and an [error
code](https://streamcomputing.eu/blog/2013-04-28/opencl-error-codes/) on error.
It's being assigned to `ret` to capture that in case it isn't successful. What
are these arguments? [The docs can tell
us!](https://www.khronos.org/registry/cl/sdk/1.0/docs/man/xhtml/clSetKernelArg.html)

- `kernel` is the compiled kernel object that is being manipulated.

- `0` is the index of the argument I'm passing in as it related to the arg list
  of the kernel function (whose signature is just `__global char *string`, so
  there is only that one argument)

- `sizeof(cl_mem)` is the size of what is being passed in
    - `cl_mem` is the return value of
      [`clCreateBuffer`](https://www.khronos.org/registry/cl/sdk/1.0/docs/man/xhtml/clCreateBuffer.html), which I'll come back to in a sec

- and finally `(void *)&memobj` is a pointer to the memory on the host that I
  want to be copied into from the host buffer into the device buffer. It's
  being cast to a void pointer because that's the signature of `clSetKernelArg`
  I guess? Seems legit.

So where is `memobj` coming from? Line 54!

```c
/* Create Memory Buffer */
memobj = clCreateBuffer(context, CL_MEM_READ_WRITE, MEM_SIZE * sizeof(char), NULL, &ret);
```

I won't enumerate these args, but basically this function creates a memory
buffer suitable for copying into the device code. [More in the
docs!](https://www.khronos.org/registry/cl/sdk/1.0/docs/man/xhtml/clCreateBuffer.html)

When the kernel is actually
[_executed_](https://www.khronos.org/registry/cl/sdk/1.0/docs/man/xhtml/clEnqueueTask.html)
in line 70:

```c
/* Execute OpenCL Kernel */
ret = clEnqueueTask(command_queue, kernel, 0, NULL,NULL);
```

the kernel code from above is run and the memory object that was "passed in" is
manipulated on the device side.

Getting that memory back out of the device is [just as
convoluted](https://www.khronos.org/registry/cl/sdk/1.0/docs/man/xhtml/clEnqueueReadBuffer.html).

```c
/* Copy results from the memory buffer */
ret = clEnqueueReadBuffer(command_queue, memobj, CL_TRUE, 0,
MEM_SIZE * sizeof(char),string, 0, NULL, NULL);
```

> (Just as there is a `clEnqueueReadBuffer`, there is also a
> [`clEnqueueWriteBuffer`](https://www.khronos.org/registry/cl/sdk/1.0/docs/man/xhtml/clEnqueueWriteBuffer.html)
> to move data from host to device side)

The memory object was read into `string` which is now just in the host side
memory space, and lo it is done:

```c
 /* Display Result */
 puts(string);
```

```
Hello World!
```

Phew.

<hr>

So let's think for a second about the original problem space. I want to compute
a bunch of md5 hashes and then save a few that fulfill a criteria (in this case
having those five leading `0`s)

The only relation these input strings have to each other is that I want to find
a way to compute each one only once. None of the actual computations inside of
an individual kernel depend at all on any of the others. This is a perfect task
to parallelize! Everything is awesome!

Not only that, but the code I want to write for the md5 function needs to be in
C! I've basically already written it! All I need to do is make a kernel
function that computes an md5, find a way to distribute the work effectively
over the gpu cores, and I should have that leet perf gain I wanted since the
very beginning of this nerd snipe! Let's get crackin.

<sub><a href='#toc'>toc</a></sub>
<a name=crackin />
Crackin'
========

So yeah, I've basically already written this, but to get it running on the GPU
I'll have to make some small changes!

First, I need both `bitswap` and `left_rotate` completely as is:

```c
#define bitswap(NUM) ((NUM>>24)&0xff) | ((NUM<<8)&0xff0000) | ((NUM>>8)&0xff00) | ((NUM<<24)&0xff000000)

unsigned long left_rotate(unsigned long x, int amount) {
    x = x & 0xffffffff;
    return ((x << amount) | (x >> (32 - amount))) & 0xffffffff;
}
```

Next, I'll show the signature of the function!

```c
__kernel void md5thing(
        __global long* constants,
        __global long* rotate_amounts
) {
```

I'm just going to pass in the `constants` and `rotate_amounts` arrays as
globally accessibly memory. They don't need to be written to, and all the cores
can share them.

On the host side, we can pass these in:

```c
    cl_mem constantsmem = NULL;
    constantsmem = clCreateBuffer(context, CL_MEM_READ_ONLY, 64 * sizeof(long), NULL, &ret);
    ret = clEnqueueWriteBuffer(command_queue, constantsmem, CL_TRUE, 0,
            64 * sizeof(long), constants, 0, NULL, NULL);
    ret = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&constantsmem);

    cl_mem rotatemem = NULL;
    rotatemem = clCreateBuffer(context, CL_MEM_READ_ONLY, 64 * sizeof(long), NULL, &ret);
    ret = clEnqueueWriteBuffer(command_queue, rotatemem, CL_TRUE, 0,
            64 * sizeof(long), rotate_amounts, 0, NULL, NULL);
    ret = clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&rotatemem);
```

Both `constants` and `rotate_amounts` are defined elsewhere in the file in the
same way they were before as constant arrays of values.

I'm going to eschew the `Message` struct thing and just inline all the padding
and such.

```c
    unsigned long acc[4] = { 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };
    unsigned char output_buffer[64];

    char input[16] = "abbhdwsy";
    char med[16] = { 0 } ;
    int num = get_global_id(0);
    int in = 0;
    while (num != 0) {
        int rem = num % 10;
        med[in++] = (rem > 9)? (rem-10) + 'a' : rem + '0';
        num = num/10;
    }
    int thing = 8;
    while (in != 0) {
        in = in - 1;
        input[thing++] = med[in];
    }

    unsigned long orig_length_in_bytes;
    for (orig_length_in_bytes = 0; input[orig_length_in_bytes] != 0x0; ++orig_length_in_bytes);

    unsigned long orig_length_in_bits = (orig_length_in_bytes * 8) & 0xffffffffffffffff;

    unsigned long padded_length = orig_length_in_bytes;

    padded_length += 4;
    while (padded_length % 64 != 0) {
        padded_length += 1;
    }

    for (int i = 0; i <= orig_length_in_bytes; i++)
        output_buffer[i] = input[i];

    int i;
    output_buffer[orig_length_in_bytes] = 0x80;
    for (i = orig_length_in_bytes + 1; i % 64 != 56; i++) {
        output_buffer[i] = 0x0;
    }

// TODO: proper bit shifting here instead of this garbage <<<
    output_buffer[i] = orig_length_in_bits;
    i++;
    for (; i % 64 != 0; i++) {
        output_buffer[i] = 0;
    }
// TODO: proper bit shifting here instead of this garbage ^^^
```

> So hey, a gentle reminder that I'm not going to say this is the best code evah,
> but it gets the job done and boy did I learn a lot.

It's essentially the same as the vanilla C version, but I have to allocate
memory blocks statically with array notation instead of char pointers. And I
don't have library functions like `memcpy` and `strlen`, so I just do those
things manually. The _real_ magic happens here though!

```c
    char input[16] = "abbhdwsy";
    char med[16] = { 0 } ;
    int num = get_global_id(0);
    int in = 0;
    while (num != 0) {
        int rem = num % 10;
        med[in++] = (rem > 9)? (rem-10) + 'a' : rem + '0';
        num = num/10;
    }
    int intwo = 8;
    while (in != 0) {
        in = in - 1;
        input[intwo++] = med[in];
    }
```

There is my input key. And then I use
[`get_global_id(0)`](https://www.khronos.org/registry/cl/sdk/1.0/docs/man/xhtml/get_global_id.html)
to get a unique id number for that work item, turn that number into a string
with that first while loop, and then concatenate it onto the end of my original
input key.

Now, I can run this code in complete parallel over as many cores on the GPU as
I want, and each process will be running a differently numbered key!

> So, the usual shape of Open[C|G]L code is to compute values based on some 2 or
> 3 dimensional space. Consider a canvas- each pixel would be uniquely identified
> by two coordinates. Those coordinates are available inside the kernel function
> by calling `get_global_id` with `0` and `1` respectively. You'll pass in a 2
> dimensional vecotr of values representing what you're trying to transform, like a photo or a frame of a video,
> then address the vector by using those coordinates, and write back to an output
> vector. To see this in action, try playing with
> [Shadertoy](https://www.shadertoy.com/new), which is a really awesome little
> thing to play with [WebGL](https://www.khronos.org/webgl/)!

Back in the host code, when I execute the kernel this time, I'll use
[clEnqueueNDRangeKernel](https://www.khronos.org/registry/cl/sdk/1.0/docs/man/xhtml/clEnqueueNDRangeKernel.html),
which allows the code to be run across many cores in parallel!

```c
    /* Execute OpenCL Kernel */
    size_t gws[1] = { 8000000 };
    size_t lws[1] = { 2 };
    ret = clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL, gws, lws, 0, NULL,NULL);
```

That first array stands for 'global work size', and I'm telling it that I want
_one dimension_ of global work ids that go up to 8 million. This means that
calling `get_global_id()` in the kernel functions will be numbered individually
from 0 to 8 million!

That's the magic sauce. The rest of the md5 implementation is basically the
same as before.

For now, I'm going to put the test to see if it's a keeper hash _in the kernel
code_. If it matches, I'll just format and print out the complete hash:

```c
    if ((acc[0] | 0x00000fff) == 0x00000fff) {
        printf("%08lx%08lx%08lx%08lx\n",
                acc[0],
                acc[1],
                acc[2],
                acc[3]
              );
    }
```

If I compile and run this, Here's the output:

```
000008bfb72caf77542c32b53a73439b
0000004ed0ede071d293b5f33de2dc2f
0000012be6057b2554c26bfddab18b08
00000bf3f1ca8d1f229aa50b3093b2be
00000512874cc40b764728993dd71ffb
0000069710beec5f9a1943a610be52d8
00000a8da36ee9b7e193f956cf701911
00000776b6ff41a7e30ed2d4b6663351
```

Oh snap, does this look familiar?

```
00000 8 bfb72caf77542c32b53a73439b
00000 0 4ed0ede071d293b5f33de2dc2f
00000 1 2be6057b2554c26bfddab18b08
00000 b f3f1ca8d1f229aa50b3093b2be
00000 5 12874cc40b764728993dd71ffb
00000 6 9710beec5f9a1943a610be52d8
00000 a 8da36ee9b7e193f956cf701911
00000 7 76b6ff41a7e30ed2d4b6663351
```

Wait what? did it work? DID IT WORK? But... how long does it take??

```
real    0m1.802s
```

_Oh shit._ I just computed 8 million md5 hashes in _1.8 seconds_. And I am
almost sure that this is not terribly awesome OpenCL code and could probably be
attuned to go even faster than that. But 1.8 seconds is about 8 times faster
than my original solution would run, so I am pretty happy with that.

> So the TODO here is that I would like to write the chars out to a global output
> buffer and then print the output to the screen from the host's side. Also,
> there's a huge problem with the CL code as written here, and that is that all
> the work items are running in parallel and there is no guarantee that the
> output will come out "in order." I have solutions to these problems but they
> don't have anything to do with the performance gains and I am very very tired
> right now. Maybe I'll write it up later but no promises.


<sub><a href='#toc'>toc</a></sub>
<a name=coda />

Advent of Coda
==============

So, this was a major rabbit hole, but I learned a hell of a lot! I learned a
lot more about OpenCL than I was able to explain here or feel comfortable
explaining just now, but I might have more on that in the future. It's really
cool stuff!

A very cool thing / huge pain in the ass about Advent of Code is that if you
let it, almost every day can lead you down a rabbit hole like this! I just
decided to follow this one, but I traded doing the rest of the problems after
about day 9 for it. Now I have to go back and do those!

This was a really long post. I hope it was interesting. I'm glad it's done. Have a Happy New Year!

Oh one more thing, [here is the source code for this,
basically](https://github.com/jfo/md5). No warranty.  It's really messy right
now and I should really have cleaned it up but #yolo and I want to go to bed.
Also if you read _this far_ I hope the explanations above have been sufficient
to explain the context.
