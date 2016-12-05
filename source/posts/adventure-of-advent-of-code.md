---
title: Adventure of Advent of Code
layout: post
date: 2016-12-4
tags: rc
---

So there is this thing that [Eric Wastl](http://was.tl/) puts together
once a year called the "[Advent of Code](http://adventofcode.com/)." Every day
at 12 am EST a new puzzle is unlocked. It's fun, you should totally try it!
This is its second year. You can read more about it [here](http://adventofcode.com/2016/about).

The puzzles are all different from each other day to day- and in fact the
puzzle _inputs_ are different from user to user. You could copy someone's
solution, but you'd still have to run it on your own input data.

I did 6 days last year before getting distracted and falling "behind." This
year, I'm doing it a little differently, here's how.

How I'm doing Advent of Code this year
---------------------------------

AoC is a really good opportunity for learning things!

- new problem solving techniques and algorithms
- practice ingesting different input data into usable structures and models in different ways
- trying out new programming languages and paradigms
- seeing how _other people solve the same problems_ in [creative and clever ways](https://www.reddit.com/r/adventofcode/comments/5g80ck/2016_day_3_solutions/daq7nqd/)!
- competing with the world or your friends or also yourself for solving the problems "best" or "fastest"

Last year, I sort of felt like if I couldn't compete and keep up to get on the
leaderboard, it wasn't worth doing it. That was wrong, of course! It is easy to
feel like you've "fallen behind" though, and doing all the puzzles right when
they are posted at midnight my time for 25 straight days is _very difficult_ to
sustain. So,

**Things I DON'T care about this year**:

- *Competing*. It's just not going to happen. I've done all the problems so far
  right at midnight, but I'm going to have to burst that bubble soon, maybe
  I'll do it tonight.
- *Writing clean, maintainable code for all the problems*. Sure, that would be nice, but it's not a priority.
- *Tests*. The puzzle is itself a test, after all, and the server knows the
  solution, so solve the problem, and you know your program passed its tests!

These programs are by definition one offs- there are a lot more things that I
would like to take into consideration if I were writing a "real" program, or a
service or something... input sanitation... edge case checking, stuff like
that. I'm just not going to worry about any of that as long as it works on the
input I was provided.

**Things I DO care about this year**:

- *Solving all the puzzles, eventually.* I think that this is a reasonable
  goal. The problems get really difficult later on, so I doubt I'll be able
  to keep doing them all the day they come out, but I'm a lot more confident
  this year that I can finish them all, at some point.
- *Learning a lot!* Which is really the whole point! I initially thought I
  would try to solve everything in Rust, but I threw that idea out the window
  within 30 seconds of the first problem being put up because I wanted to do it
  as fast as I could.

So I'm going to solve the problem in the way I can think of fastest first,
probably in Ruby. Then, if I feel led to, I'm going to solve the problem in the
fastest or most elegant way I can think of later, maybe using Rust (or clean nice
Ruby). So far, this has been a really great way to do these problems! I don't
know Rust well enough to enjoy both solving the problem and reading docs at the
same time, but I do want to keep learning it. I _do_ know Ruby well enough to
toss off a solution in whatever random way might occur to me, but I don't have
too much interest in polishing it up once I've finished it.

In the past few days, following this process, a neat thing has been happening!

A neat thing that's been happening
----------------------------------

Because I have told myself that the first iteration doesn't have to look nice,
or be efficient, or really anything at all, I've been able to just jump right
in with writing dumpster fire procedural code that still spits out the answer I
want! Look at this hot garbage from [day 2 part 2](http://adventofcode.com/2016/day/2):

```ruby
@input = File.open('./inputs/2.txt', "r").readlines.each {|l| l.chomp!}.collect! {|e| e.split('')}
@keypadtwo = [[2,3,4], [6,7,8], ["A","B","C"]]
def two
    x = 0
    y = 1
    acc = []

    uplock = false
    downlock = false
    rightlock = false
    leftlock = true
    @input.each do |elem|
        elem.each do |e|
            case e
            when 'U'
                next if (leftlock || rightlock || uplock)
                if downlock
                    downlock = false
                    next
                end
                if y == 0 && x == 1
                    uplock = true
                    next
                end
                y -= 1
            when 'D'
                next if (leftlock || rightlock || downlock)
                if uplock
                    uplock = false
                    next
                end
                if y == 2 && x == 1
                    downlock = true
                    next
                end
                y += 1
            when 'R'
                next if (uplock || downlock || rightlock)
                if leftlock
                    leftlock = false
                    next
                end
                if y == 1 && x == 2
                    rightlock = true
                    next
                end
                x += 1
            when 'L'
                next if (uplock || downlock || leftlock)
                if rightlock
                    rightlock = false
                    next
                end
                if y == 1 && x == 0
                    leftlock = true
                    next
                end
                x -= 1
            end
            x = 0 if x == -1
            x = 2 if x == 3
            y = 0 if y == -1
            y = 2 if y == 3
        end

        if uplock
            acc << 1
        elsif downlock
            acc << 'D'
        elsif rightlock
            acc << 9
        elsif leftlock
            acc << 5
        else
            acc << @keypadtwo[y][x]
        end
    end

    acc.join
end

p two
```

The specifics of this problem are not important right now, and in fact you'd
need to solve the first part to see them on the link above. But, I mean, even
just looking at the shape of that you can tell that it's some... not very great
or sophisticated code! There is a ton of repetition, the whole boolean "lock"
construct smells dubious... (even if you don't know what it does!) This is the
kind of code I would have written a few years ago- it fulfills the task,
but boy howdy is it ugly, and has a ton of nooks and crannies in it where a
simple typo could make everything bad in really funny ways.

But! *Why* it looks like that is what I'm interested in. It's like a rough
sketch- it's me thinking about the problem as "[easily](https://www.infoq.com/presentations/Simple-Made-Easy)" as I can.
That code might look (and be) "bad" code, but it's as clear a procedural
representation of the problem as I could come up with in only a couple of
minutes. Once I've solved the problem I can be confident that I really do understand
it, and then I can take my time in implementing either an efficient or elegant
solution for teh learns. Ideally both!

Here's my Rust for that very same problem:

```rust
use std::io::prelude::*;
use std::fs::File;
use std::collections::HashSet;
use std::iter::FromIterator;


static GRID : [&'static[i32; 5]; 5] = [
    &[0, 0, 1, 0, 0],
    &[0, 2, 3, 4, 0],
    &[5, 6, 7, 8, 9],
    &[0,10,11,12, 0],
    &[0, 0,13, 0, 0],
];

fn main() {
    let allowedarr = [
        (0,2),(1,1),(1,2),(1,3),
        (2,0),(2,1),(2,2),(2,3),
        (2,4),(3,1),(3,2),(3,3),
        (4,2)
    ];
    let allowed = HashSet::<_>::from_iter(allowedarr.iter());

    let mut f = File::open("../inputs/2.txt").unwrap();
    let mut s = String::new();
    f.read_to_string(&mut s).unwrap();
    let len = s.len();
    s.truncate(len - 1);

    let keys: String = s
        .split("\n")
        .map(|tokenlist|
            tokenlist.chars().fold((2,0), |coord, dir| {
                let newcoord = match dir {
                    'U' => (coord.0 - 1, coord.1),
                    'D' => (coord.0 + 1, coord.1),
                    'R' => (coord.0, coord.1 + 1),
                    'L' => (coord.0, coord.1 - 1),
                    _ => panic!("Malformed input")
                };
                if allowed.contains(&newcoord) { newcoord } else { coord }
            })
        )
        .map(|coord| GRID[coord.0 as usize][coord.1 as usize])
        .map(|e| format!("{:x}", e))
        .collect::<Vec<String>>()
        .join("")
        .to_uppercase();

    println!("{}", keys);
}
```

So... I don't really know yet if this is "good Rust" because I don't know Rust
super well yet, but I can say for certain that it's much better written than
the first one!It uses a completely different boundary checking method, and is
much more functional. Again,the specifics of the problem are not that important
here, but you can see that my thinking is clearer. Basically it just pulls in
the input and then chains together a lot of functions to turn that input into
the desired answer! Yay functions!

Here's where something else neat happened.


Something else neat that happened.
-------------------------------

Take a look at my ruby solution for the
next day's second problem:

```rb
@input = File.open('./inputs/3.txt', "r")
.readlines
.collect! {|e|
    e.split(' ')
    .map! {|e|e.to_i}
}

p (0..2).map{|i|
    @input.map {|e| e[i]}
    .each_slice(3)
    .to_a}
.flatten(1)
.select {|e| e.inject(:+) > e.max * 2 }
.count
```

It's functional af! The whole thing is just one chain of methods that spits out
the answer! It reminds me of the
[scalding](https://github.com/twitter/scalding) code I've written at work to
produce big data jobs. It also looks like (shocker) the Rust code I wrote the
day before. This is a very clear cross pollination of the different things I'm
looking at right now, and that's really exciting!

I was thinking about going through all these solutions in greater detail- but I
think a much more important take away than my implementations here is just that
AoC provides a _ton_ of opportunities for learning new things, and that if
you're interested in that, and puzzles, and or programming, then you should
totally give it a try! And you shouldn't feel bad about what you use or how you
use it, and just have fun solving the puzzles you can solve! And THEN, search
the [subreddit](https://www.reddit.com/r/adventofcode/) or talk to other people
doing the challenges and see what they did! It's really amazing how many
different ways people find to solve these problems!
