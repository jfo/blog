---
title: What I did before Hacker School
layout: post
---

I wrote a [post](/corridor) about going to the Recurse Center (née Hacker School) the night
before I started my batch. I stand behind it, there were some good feels in there.
But I never wrote about _how I got there_. Which, if I were me reading my own
post a year prior, I would, like, you know, really wanted to have known _that_. I've been
meaning to write this post for _years_ now, which is ridiculous, but better
late than never?

<hr>

In the Spring of 2013, I couldn't `ls`. I hadn't programmed anything since a
Qbasic class I took in probably 4th grade, and the only program I could remember was

```basic
10 PRINT "HELLO"
20 GOTO 10
```

Or something.

The very first thing that got my wheels turning on this- it was around January
of 2013 or so, maybe... I was working on permutations of different four voiced
chordal structures on the guitar, mostly by hand and in my head, trying to come
up with a relatively complete set. Any shape would have one of

```
7  different chord qualities
4  different inversions (including root position)
12 different root notes
4  different voicings
```

The specifics of these, while interesting and  maybe blogelaboutable, are not
pertinent right now. Just ... I wanted to figure out a lot of different
permutations. For any given chord, I could see how it fell along these
dimensions easily, but I was trying to figure out _everything_ because I am a
commited completest sometimes, and also I wanted to build some practice plans
around them.

I thought, wouldn't it be nice to have all these in a spreadsheet or something?
That would take forever to write out. This is like, the perfect thing to make a
computer do for me, right? I called my old buddy
[Yuri](http://stacoscimus.com/), a fine musician and bash scriptor, and he
recited a one liner over the phone that did exactly what I wanted:

```bash
echo {A,Bb,B,C,Db,D,Eb,E,F,Gb,G,Ab}{M7,m7,7,m7b5,dim7,mM7,M7#5}_{0,1,2,3}_{drop2,drop2/3,drop2/4,drop3/4}
```

This was completely incomprehensible to me at the time, as I was
still afraid of opening the terminal, but that didn't matter, because _it
totally worked_. I had my giant list of voicings; I had my wheels turning!

<hr>

Sometime a few weeks after that I stumbled on an article about the then new to
NY [App Academy](http://www.wired.com/2013/03/free-learn-to-code-boot-camp/). I
hadn't heard of the bootcamp model before then, but was heartened to learn
about their "you don't owe us until you get a job" payment structure. There was
no way I could afford a 10-15 thousand dollar course up front, but this seemed
doable. The very next day I applied, and they wrote back promptly with
instructions on preparing for and taking an initial coding challenge. What they
sent wasn't _quite_ as fleshed out as what they have available now, but basically
it was this:

http://prepwork.appacademy.io/coding-test-1/

I spent a couple of weeks going through those materials and completed the
challenge. They again got back promptly, this time asking me to do a
second one. At this point, I was pretty chuffed! I had begun to start
thinking about this path as something that might be not only _possible_ but
_really fun_. I hadn't told anyone but Yuri about _any_ of this yet.

I went through the materials for the second challenge:

http://prepwork.appacademy.io/coding-test-2/

I bought the books they recommended:

https://pine.fm/LearnToProgram/

http://peterc.org/beginningruby/

I worked through them voraciously. I think they also recommended tryruby.com,
and I found that to be really helpful, as well. As was Why's poignant guide,
which is still a really sweet anomaly of a pedagogical sugar cube.

http://poignant.guide/

> it is particularly awesome that this is still available, as the author has
> since disappeared from public (internet public, at least), life. There is a
> longform article about it
> [here](http://www.slate.com/articles/technology/technology/2012/03/ruby_ruby_on_rails_and__why_the_disappearance_of_one_of_the_world_s_most_beloved_computer_programmers_.html)_

It was a lot all at once, and it was very overwhelming at times. When I looked
at the [curriculum](http://www.appacademy.io/curriculum), I saw a _whole bunch
of idk_. But I had told myself that I was at least going to try it. I had been
asked to do a second test, so I must not be abysmal, right?

It was also during this period that I experienced my first real nerd snipe. On
some message board or another, I found a link to the [Cue programming challenge](http://techcrunch.com/2013/03/08/programming-challenges-benefit-job-seekers-and-employers/). I had been tackling little puzzles using my nascent ruby, and as I read the first problem, I remember thinking "wow that seems really hard, but I guess if I started by..."

I stayed up all night solving the three problems. Each solution would unlock
the next tier. It was wicked fun! After putting in the last solution, I got a
prompt asking me to send in my resume. This is when I really decided that being
a programmer was something that I was capable of, and that it was something
that I would enjoy.

There was no deadline for the second challenge, so I spent about 3 months
working through all those resources. I didn't want to half ass it.

> I want to note here that all of this was Ruby. That's why I learned Ruby first.
> I really like Ruby. I still like Ruby; it's still the first thing I reach for
> when just sketching out ideas. I would recommend Python or Ruby as a
> great first language to anyone. Certainly not Java. What are CS programs
> thinking, with Java as a first language? That's awful. It's like learning to
> ride a bike by building a motorcycle. I mean, sure the motorcycle is faster
> and better for driving on enterprise freeways and all, but ffs just ride a
> trike around the cul-de-sac for a little while first, you know?

Finally, I took the second challenge, and though I don't think I _bombed_ it,
exactly, I didn't do that great, either. I wasn't invited to an interview. This
was a huge disappointment, but not really a surprise; I had been programming
for about a month, after all, and programming is hard, right? That had always
been my understanding.

I had been doing research about other bootcamps and programs this whole time.
Most of them were pay up front, which made them impossible for me to attend.
But one of them wasn't, because one of them was Hacker School.

I don't remember how I found them first. There aren't _that_ many things
online. I do remember finding this video:

https://www.youtube.com/watch?v=Jds52EW1yzM

And being really inspired by it.

> Yay Bethany! I work with her now, Isn't that a hoot?

And then I read their manual:

https://www.recurse.com/manual

Which really, really resonated.

RC has (and had) very different application criteria.

https://www.recurse.com/apply/retreat

Some semi-open ended get to know you prompts, a basic Fizzbuzz code screen, and
linking to a project that you built from scratch. I hadn't built any projects
from scratch, so I spent a few weeks building a program that could compute some
of the chord structures that Yuri's bash one liner could output, and display
them via ASCII art.

https://github.com/urthbound/chorder

RC at the time had a three step process.  Initial application screening, and
then two skype interviews- the first just a chat about your background and
goals and the second a pairing session with one of the facilitators on
something that you were working on.

I submitted this stuff, along with a lot of ideas I had about what I might work
on while I was there, and waited. I got a first interview. I talked to
[Mary](http://maryrosecook.com/) for a while. It went ok; she was very nice. I
wasn't invited to do a second interview. I was even more disappointed this
time, I had started to develop an attachment to the idea of this possibility.

I had asked explicitly if it was possible to reapply, and she had said that
people often do improve and get in on a second attempt, so I sent Mary a follow
up email, asking for feedback.

A few days later she wrote back. Posted with her permission:

> Hi Jeff,

> You seemed to be focused on building things, rather than learning to program.
> We love it when people make stuff at Hacker School.  But, we try to admit
> people who are obsessed with programming for its own sake.  Having the goals
> for the "thing" be important as well as the learning goals can mean that the
> learning goals suffer.
>
> Best,
>
> Mary

This made me _very, very_ happy. She had no way of knowing this, but I had gone
_way_ out of my way to emphasize the projects I had ideas about working on, because
I thought that that would show that I had direction, and plans! The truth is
that when I _really_ get interested in something, I just kind of want to dive in and
meander around in it and try to learn about it through trial and error, but I
had spent so many years in institutions where this approach is looked down on!

I decided then that I would reapply for both App Academy and the Recurse Center
for their next cohorts. I figured I had about 4 or 6 months to focus on
learning as much as I could before then. (They hadn't started their
[overlapping batches](https://www.recurse.com/blog/36-overlapping-batches) yet).

<hr>

A couple of things, here.

First, _Thank you, Mary_. She didn't have to get back to me, she didn't have to
give me that feedback. Without it I would have felt a _lot_ more discouraged. I
almost definitely wouldn't have reapplied to either program, and it's
debateable whether or not I would have continued to pursue programming _at
all_. At this point, I had invested only a couple of months in it, and it was a
pretty off the wall lark to begin with. That email really contributed to
getting me where I'm at today, which is a place that was _completely
incomprehensible_ to me a few years ago. She knows this; I've told her.

Second, _they don't give feedback like this to applicants anymore._ There are
very good reasons for this, most notably that the volume of applicants has
increased quite a bit, but also that since my batch, they've switched to having
alumni volunteers conduct a lot of the interviews. The facilitators spent an
enormous amount of time conducting interviews before this change, and to add
the overhead of providing focused, thoughtful feedback for _every single
application_ was not possible. This is a bummer, yes, but I do understand it.

Third, and most importantly, this timeline allowed me to set aside the myriad
doubts and worries I had about the whole endeavor for a few months, and to just
focus on programming _only_. I decided that I would spend that time, that 4-6
months, learning as much as I could, and if I didn't get in again, well, then
I'd reassess. Normally I wouldn't have been able to do this!

<hr>

And so I spent those 4 months _working my ass off_. I treated it very much like
a job, I spent at least 8 hours a day studying. I found out about the [Wix
lounge](http://www.wix.com/lounge/new-york) which, at the time, was free to
anyone anytime working on pretty much anything. This was pretty wild, but such
a godsend! To have a place to go to for this expressed purpose was so helpful
to help me focus!

Nobody was supporting me during this period. I had no trust fund, and no
savings, and no work save the work I made or found for myself. I did random
photography and music gigs, and I had spent the year previous building up my
[teaching business](https://www.yelp.com/biz/guitar-from-the-ground-up-new-york), and I
had just enough clients to keep my rent paid. I had to be frugal, and I was
still struggling financially, but I didn't have to work too many _hours_. I had
a _lot_ of time, and I spent it at the Wix lounge, drinking their free coffee
and learning to program.

I spent a few weeks doing the Ruby Koans.

http://rubykoans.com/
https://github.com/urthbound/koans

I had this idea that Rails was the "way in". That's what most of the bootcamps
taught, after all, and I had already invested a relatively significant amount
of time learning Ruby, so  I spent a month or so working through Michael
Hartl's Rails tutorial

https://www.railstutorial.org/

This was interesting and I learned a lot, but I didn't have a way to
contextualize anything yet. By the end I felt like I was just typing things in
until they worked. That's... _a_ way to learn things?

The page that I hosted the final product on is still up, as it turns out! You
can sign up for an account

https://derplederp.herokuapp.com/

I named it "Derple Derp" so that my screen didn't just always say "SAMPLE APP"
in giant letters while I was working on it.

Sometime in here I read
[Code](http://www.amazon.com/Code-Language-Computer-Hardware-Software/dp/0735611319)
which was a seminal step. Please read this book, at least the first half, it is
amazing. It starts from nothing, from `1` and `0`, and explains what code _is_
and how it _works_ and it's just really good and it made me understand a lot of
things that I didn't think were accessible to me, is all. Fundamental things
about computing and about encoding and about logic. I wrote a
[post](/the-story-so-far) around this time about where I was at, and going back
and reading it now makes me appreciate the value of writing posts at all if
only for my future self. I'll never have access to that perspective again!
