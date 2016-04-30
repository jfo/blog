---
title: Sild13 a refactoring party
layout: post
---

I've now implemented the following built in functions:

- quote
- car
- cdr
- cons
- atom
- eq
- cond

And they work. Great! We're getting closer to something useful, but before
moving on, this is a great time to stop for a refactoring!

Up until now, the entire program has lived in one big file `sild.c`, which has
everything I've written from top to bottom in rough dependency order and a
`main()` function at the end. The file is 475 lines long, which is pretty long!
I can do better; I need to find a way to separate this file into logical units
that `#include` each other, and the `.c` file that contains `main` shouldn't
have that much else inside of it.

I struggled with this one for quite a while, actually! There are a lot of ways
to get C code into the final executable that are bogus, on one iteration I was
inline `including` `.c` files into the files they depend on, which totally
works, but is a _major giant_ antipattern for lots of reasons that I had no
idea about. I was thinking like Ruby, where you just `require` a file, and it
is read in, and everything is fine. C doesn't work that way! To start with, the
whole concept of header files was new to me- I had touched them in Objective-C
and was taught that they "define an interface" to a library. This is true! But
also pretty vague! Does a .c file always include its own header? do all
functions need to be defined in the header, or just the ones you want to
expose? Do you fully define structs and unions in the header file, or simply
typedef them? Do you initialize global variables in the header file? How the
hell does all this get linked together, really? Lots of questions, I had.  I'll
skip the details of a lot of my mis-adventures, and instead focus on what I
eventually found to be a reasonable set of rules of thumb for good compilation
practices.


There is a lot of weird info on the interwebs about this, too...
and nothing was one hundred percent clearly the "best way" to factor out code
into libraries. I found this to be helpful:

http://umich.edu/~eecs381/handouts/CHeaderFileGuidelines.pdf

and this:

https://guilhermemacielferreira.com/2011/11/16/best-c-coding-practices-header-files/

But ultimately the set of golden rules came from friend [Andrew
Kelley](https://github.com/andrewrk), and they boiled down to something like this.

1. Each .o file is produced independently from all other .o files via a
separate invocation of the compiler...

`.o` stands for "object" file. An object file is compiled, and usually
non-executable. Let's say I have a .c file with some functions inside of it, and call

```
$ cc myfile.c
```

By default I'm going to get a file called `a.out` that is an executable. I can
explicitly set a target with the `-o` flag, which specifies it.

```
$ cc myfile.c -o myfile.
```

This is the _only_ line that has been in my makefile this entire time, as a
matter of fact. (I'll get way deep into makefiles in a minute!)

```
cc sild.c -o sild
```

And when I run make, it compiles sild.c into sild as an executable, and I can
run it yay!


BUT, if I take out the `main` function, and try to compile _that_, I get a
nasty compiler error:

```
Undefined symbols for architecture x86_64:
  "_main", referenced from:
     implicit entry/start for main executable
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

The compiler is trying to make an executable, but an executable needs to know
where to start, which is implicitly a `main` function. If I want to compile
arbitrary C code into machine instructions, what I want is an object file: a
`.o` file! I could do that with the `-c` flag:

```
$ cc -c myfile.c
```

By default, this will compile to an object file of the same name: `myfile.o`
which contains arbitrary machine code wrapped up in functions, and anything
else you define in there, etc!

1. ... So really, in C, your goal is merely to produce a bunch of .o files to link together into a final library or executable. The reason you might have more than one .o file is for your own abstraction benefit.

