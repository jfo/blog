---
title: Sild is a lisp dialect
layout: post
---

I read somewhere that you're not really a lisp programmer until you've
implemented your own interpreter. Fair enough, I guess, and although that's
exactly the kind of sweeping, obnoxious statement that makes people not want to
talk to you at parties... it really stuck with me. People who like lisp
_really_ like lisp, and I wanted to see what all the fuss was about, but for a
long time I just didn't know where to start. I've played around quite a bit
with Scheme through a couple of abortive attempts at SICP, and I enjoyed those
"the [thing]er schemer" books very much! I even implemented a toy interpreter
in Ruby a while back, which was edifying, but I've always found building your
own data structures in a higher level language to feel kind of...  pointless?
It's great for learning concepts, for sure, but you're building abstractions on
top of the (probably) better and (definitely) more efficient abstractions of
your host language. I wanted to try to implement something on the bare metal of
the machine; I wanted to build my own abstraction from the memory on up. Lisp,
after all, is a pretty simple idea, at it's core... you're basically just
writing human readable AST's!

<u>**Some history** : _wtf is LISP_</u>


**Lisp ex nihil**

Ok,so, Lisp stands for "LISt Processor." One day I was thinking about _just
that_, and I decided I just needed to start from there.

So! Making a list in C is pretty simple, actually. We need some type of data
structure, we'll call it a node for now, that can hold only two things: a
value, and a pointer to the location of the next node.

In C


sections notes;

what is a list.
a string is a kind of a list, as is an array when we declare it, but that always
assumes consecutive memory spaces, which is also why they have to be the same
size. We want to malloc our own list.

a linked list has two things in it, a value, ad a pointer to the next cell. If
the pointer to the next cell is null, then that is the end of the list.

make out of a struct.

```c
struct cell {
    char value;
    struct cell * cell;
}
```

Now this looks something like

```
[1][->]
```

Let's start by ingesting a list of chars. It seems like it would be simpler to
start with numbers, but really because we are starting from a string, we are
already dealing with chars, we just want to get them into a linked list from a
C string.

`a b c d`

we want a function that reads each character, and copies it into our linked
list structure.

that's nice, but we want more than just the basic character set by itself. it
would be better if the value in our cell could be a raw c string, and let's
also change the name of the value to `label`, since we are only dealing with
strings right now and that is more accurate.

```c
struct cell {
    char* label;
    struct cell * next;
}
```
