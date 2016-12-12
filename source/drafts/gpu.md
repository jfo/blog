---
title: gpu
layout: post
---

introduction, link back to advent post

http://adventofcode.com/2016/day/5

what's an md5 hash? luckily, ruby has it's own builtin md5 library, natch.

My door input was `abbhdwsy`. With two small lines, I can compute the MD5 hash
for that input like this:

```ruby
require 'digest'

puts Digest::MD5.hexdigest("abbhdwsy")
```

That gives me:

```
b0d0113e0f3745b2eb8d0db1b6aad818
```

But, the problem states that I need to to compute the md5's for that input
_plus some numbers_

That might look like this, right?

```ruby
require 'digest'

puts Digest::MD5.hexdigest("abbhdwsy0")
```

Yields:

```
7e51386949e56ddab4f31c503de50f83
```

That's... really really different!

Maybe I'd like to get a few more of these?

```ruby
require 'digest'

puts Digest::MD5.hexdigest("abbhdwsy1")
puts Digest::MD5.hexdigest("abbhdwsy2")
puts Digest::MD5.hexdigest("abbhdwsy3")
puts Digest::MD5.hexdigest("abbhdwsy4")
puts Digest::MD5.hexdigest("abbhdwsy5")
```

This gives me:

```
917b4f767f6713624ae0e4b4a4cd3cc9
1e2ec6125cc3e05cfd556134ae10e8ac
475a5869d93ec860881f9805460dc8fe
41ceab0f4edefdb821d47e8682adef7a
3c91defeee434cf792491e1d0e58876a
```

Again, look how different all those hashes are!

You may have noticed that my strategy here is to increment the number that I'm
appending to my unique input. This seems like it might take a while to do
manually, oh if only there were a way to automate it!

```ruby
require 'digest'

i = 0
loop do
    puts Digest::MD5.hexdigest("abbhdwsy" + i.to_s)
    i += 1
end
```

I increment that `i` value on each loop, and append it to the static input by
calling `to_s` on it! Easy peasy. This, as you would expect, fills my screen
with hashes, all different, all unique, like a snowflake, or a little baby!

> Lol jk no they are not unique! They are... _mostly_ unique, of course, but
> although MD5 hashes are guaranteed to be reproducible for any
> given input, they are decidely _not_ guaranteed to always be unique. When two
> different inputs result in the same hash, it's called a _hash collision_, and
> you can read a lot more about that
> [here](http://www.mscs.dal.ca/~selinger/md5collision/) amongst other places.

From here, it's a pretty straightforward exercise to collect the hashes I need
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
password. I can do this by hand, of course, or I can write a little map to do
it for me!

```ruby
puts acc.map {|e| e[5]}.join
```

This returns `801b56a7`, which is, in fact, my password.

<hr>

What is an md5 hash, anyway? and how is it computered? Let's make a crappy ruby version of md5

wow that's hella slow, but why? (we'll come back to why actually later, (because the ruby version is written in C of course!))

what's the bottleneck? It's the md5 computation. Let's look at just that. (in ruby)
how long does it take to compute, say, a million md5s?
What is a way we could speed this up? yes! parallelism in ruby land
