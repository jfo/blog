---
title: Sild - we're gonna Make it after all
layout: post
date: 2016-07-05
tags: rc
---

[...if only there were a way to automate all those compilation
steps...](/sild-arity-checking-and-rich-error-messaging/)

```make
cc utils.c -o
cc cell.c -o
cc eval.c -o
cc builtins.c -o
cc print.c -o
cc read.c -o
cc utils.o cell.o eval.o builtins.o print.o read.o main.c -o sild
```

I could put this all into a shell script, maybe? Sure, but then I would be
recompiling everything every single time I wanted to make a new build. Once
again, not a big deal on a project of this small size, but bad practice.
Luckily, in true Unix fashion, there is a tool just for this problem, and it's
called `make`!

<hr>

Make is... well I don't know. It's pretty great! Also it's a huge nightmare!
It's a very easy tool, in the sense that its basic usage is pretty easy to
explain, but it's ultimately not very simple, as it's easy all the way to
gordion knotsville. Easy is nice, but we want
[simple](http://www.infoq.com/presentations/Simple-Made-Easy)!

Anyway, I just want a way to make my build work.

Running the `make` command looks for a `makefile` in the working directory. a
makefile can be named `makefile`, `Makefile`, or `GNUMakefile` in the case of
gnu make. Usually they're called `Makefile` since this appears near the
beginning of a directory listing (since it is capitalized), but I hate capital
letters, so I'm naming mine `makefile`.

When `make` is invoked, it looks for a makefile, and if it finds one, it
executes the _default target_ in that makefile. A make _target_ is a rule that
described how to `make` that target file, and generally looks like this:

```make
target_name : dependencies
	commmands to create target
```

So, for a single file, the target would look pretty familiar (it has no
dependencies except for its own .c file)

```make
thing : thing.c
	cc thing.c -o thing
```

The _default rule_ will implicitly be the first rule in the file and, a note
about formatting, that indent under the target/dependency declaration _must_ be
a hard tabstop character, or make will get wicked confused, as it used hard
tabs to signal that that line is an actual command to execute in the shell.

Let's say `thing` depends on something else, some object file or another...

```make
thing : thing.c lib.o
	cc -o thing thing.c lib.o
```

(I think it looks better to put the target at the beginning of the command if
there are multiple dependencies...)

But where does lib.o come from? Ostensibly, it comes from some file called
lib.c! For that, we'll need another target.

```make
thing : thing.c lib.o
	cc -o thing thing.c lib.o

lib.o: lib.c
	cc -c lib.c
```

Now, in order to execute `thing`, make will look at its dependency list and
recursively execute any subcommands that it needs to to keep all of its
dependencies up to date. This is the clever part of make! Let's say you compile
the `thing` target, and out of that you are going to get both a `lib.o` file
and the final executable `thing` file. Then you update `thing.c`, but don't
change `lib.c`, which is the only thing `lib.o` depends on. the next time you
run `make`, the program knows that, since lib.c is older than the thing that is
being recompiled that depends on it, that it doesn't need to be recompiled
itself, and the existing object file is ok to be linked! This is very cool! For
big projects this cleverness can save a massive amount of time in the
compile/test/edit cycle! And its convenient even in a small project like this.

<hr>

So, as I factored out the libraries from my old big sild.c file, I added a rule
for each new library in my makefile. Right now, it looks like this:

```make
sild: read.o print.o builtins.o eval.o cell.o util.o sild.c
	cc read.o print.o builtins.o eval.o cell.o util.o sild.c -o sild

util.o: util.c
	cc util.c -c

cell.o: cell.c
	cc cell.c -c

eval.o: eval.c
	cc eval.c -c

builtins.o: builtins.c
	cc builtins.c -c

print.o: print.c
	cc print.c -c

read.o: read.c
	cc read.c -c
```

This worked, but I don't like it. I felt like there was something I was missing
about make, something I didn't quite get! That is awfully repetitive, not very
DRY code, there must be a better way!

Make supports variables internal to itself, I can start by defining `CC` (for
'C compiler) to point to my compiler of choice, which is clang, which is
invoked on my machine via `cc`

```make
CC = cc
```

Now, I replace all the `cc` calls in my rules with a variable expansion of that var:

```make
CC = cc

sild: read.o print.o builtins.o eval.o cell.o util.o sild.c
	$(CC) read.o print.o builtins.o eval.o cell.o util.o sild.c -o sild

util.o: util.c
	$(CC) util.c -c

cell.o: cell.c
	$(CC) cell.c -c

eval.o: eval.c
	$(CC) eval.c -c

builtins.o: builtins.c
	$(CC) builtins.c -c

print.o: print.c
	$(CC) print.c -c

read.o: read.c
	$(CC) read.c -c
```

Now, if I want to change my compiler, I just change one line.

It's useful to have a `clean` target to remove all the artifacts from a build. The commands to do that now would be like this:

```make
clean:
	rm sild *.o
```

I've also added those to my .gitignore file, as I don't need to commit any of
these artifacts since they are derivable from the source code.

```make
sild
*.o
```

`clean` is the traditional name for this task, but it presents a little bit of
a problem. What if there is a file named "clean" in the working directory? Make
might not execute these commands if it looks at the `clean` file and sees that
it doesn't need to be updated. By declaring `clean` as a `.PHONY` target, this
problem is resolved.

```make
.PHONY: clean
clean:
	rm sild *.o
```

There are other reasons to use .PHONY targets. Anytime you're defining a rule
that executes arbitrary commands that don't result in an artifact, you should
declare it .PHONY.

I can also add a `CFLAGS` variable that holds some options I want to pass to
all of my compiler invocations.

```make
CFLAGS = -Wall -Werror
```

These flags tell the compiler to report more errors than it normally would.
It's a good idea to do this to have extra insight into how the compiler is
viewing your code.

And then in each of the rules:

```make
...
builtins.o: builtins.c
	$(CC) $(CFLAGS) builtins.c -c
...
```

ONe of the benefits of modularizing everything is that you don't have to look
at all the stuff you're not working with. I am keeping everything in a top
level directory right now. This isn't so great! It is better to hold all your
source code in a `src` or `source` directory and then build artifacts outside
of that directory. Here, all of my source files are living in `src`, and all my
object files are being built to a directory called `obj`, which I have also
added to my .gitignore.

```make
CC = cc

sild: obj/read.o obj/print.o obj/builtins.o obj/eval.o obj/cell.o obj/util.o sild.c
	$(CC) obj/read.o obj/print.o obj/builtins.o obj/eval.o obj/cell.o obj/util.o sild.c -o sild

obj/util.o: util.c obj
	$(CC) util.c -c -o obj/util.o

obj/cell.o: cell.c obj
	$(CC) cell.c -c -o obj/cell.o

obj/eval.o: eval.c obj
	$(CC) eval.c -c -o obj/eval.o

obj/builtins.o: builtins.c obj
	$(CC) builtins.c -c -o obj/builtins.o

obj/print.o: print.c obj
	$(CC) print.c -c -o obj/print.o

obj/read.o: read.c obj
	$(CC) read.c -c -o obj/read.o

obj:
	mkdir obj

.PHONY: clean run
clean:
	rm sild
	rm -r obj
```

This works, but is getting pretty ugly and verbose and unmaintainable. If I
want to change where I build to, for example, I have a lot of search and
replacing to do. I can do better!

I did a lot of research on this one, and I had that experience where someone on
stack overflow asked this _exact same question_ and someone gave them the
_exact answer_ that you are looking for. Terrific! The original poster edited
their question with their working solution, you can find it just under "[Here
is the working makfile:](
http://stackoverflow.com/questions/5178125/how-to-place-object-files-in-separate-subdirectory)"

Let's look at what that means for my makefile!

```make
SHELL = /bin/sh
```
I'll add this as a best practice, in case the working shell is something other
than bash, which is what I'm expecting.

These are the same as before:

```make
CC = cc
CFLAGS = -Wall -Werror
```

Here I'll define a var `OBJDIR` for use in the target rules. The `vpath` is
telling make "look in this path for this type of file when searching for
dependencies.

```make
OBJDIR=obj
vpath %.c src
```

And one that represents all of the dependencies that need to be built for the
main executable. Notice I'm using the `addprefix` make function to prepend all
of these names with the `OBJDIR` variable:

```make
objects = $(addprefix $(OBJDIR)/, util.o cell.o eval.o builtins.o print.o read.o main.o)
```

Now, the dependencies of the executable can be expanded from the var that was
constructed above.

```make
sild: $(objects)
	$(CC) $(CFLAGS) -o sild $(objects)
```
Much cleaner!

Here's the beastly rule:

```
$(OBJDIR)/%.o: %.c $(OBJDIR)
	$(CC) -c $(CFLAGS) $< -o $@
```

This rule make my head hurt, but it's basically saying "define a target
filename.o for every .c file in src/".

`%.c` is associated with `src` in the vpath assignment, and then:

```
$<     refers to the dependency names.
@<     refers to the target name.
```

The `OBJDIR` target needs to know how to create itself, here that is as simple
as a `mkdir`:

```make
$(OBJDIR):
	mkdir $(OBJDIR)
```

And Bob's your uncle!

```make
.PHONY: clean
clean:
	rm sild
	rm -r obj
```

<hr>

I'll be honest, learning about `make` was an unwelcome detour from the business
of writing this interpreter. I found it pretty counterintuitive, at least until
I had a handle on how to refactor out libraries like I described in the last
post. `make` is a great tool, don't get me wrong, but it felt pretty archaic to
be registering all my source files one by one and describing the commands
needed to build them individually.

This makefile is a lot better than what I started with, though, and if I want
to add a new dependency to the executable I only have to add it in _one place_,
which was really the goal! I will likely not be touching this makefile again
except to do just that; I don't plan on adding any other built executable
targets to this.
