---
title: Sild - header files and a refactoring
layout: post
date: 2016-07-03
tags: rc
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

[C header file guidelines.](http://umich.edu/~eecs381/handouts/CHeaderFileGuidelines.pdf)

and this:

[Best C coding practices for header files](https://guilhermemacielferreira.com/2011/11/16/best-c-coding-practices-header-files/)

But ultimately the set of golden rules came from friend [Andrew
Kelley](https://github.com/andrewrk), and they boiled down to something like this.

> 1. Each .o file is produced independently from all other .o files via a
> separate invocation of the compiler...

`.o` stands for "object" file. An object file is compiled C code, and is
non-executable. Let's say I have a .c file with some functions inside of it,
and call

```
$ cc myfile.c
```

By default I'm going to get a file called `a.out` that _is_ an executable. I can
explicitly set a target with the `-o` flag, which specifies the output file name:

```
$ cc myfile.c -o myfile
```

This is the _only_ line that has been in my makefile this entire time, as a
matter of fact. (I'll get way deep into makefiles in a while!)

```make
sild: sild.c
	cc sild.c -o sild
```

And when I run make, it compiles `sild.c` into `sild` as an executable, and I
can run it, yay!


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
arbitrary C code into a lump of machine instructions, what I want is an _object
file_: a `.o` file! I could do that with the `-c` flag:

```
$ cc -c myfile.c
```

By default, this will compile to an object file of the same name: `myfile.o`
which contains that arbitrary machine code  and anything else you define in
there, like constants or variables or whatever!

> 1. ... So really, in C, your goal is merely to produce a bunch of .o files to
>    link together into a final library or executable. The reason you might have
>    more than one .o file is for your own abstraction benefit.

<hr>

Ok, so let's see. I have already separated my code into some sections, and my
goal is to abstract those sections into libraries. I'll start with an easy one!
At the very top of `sild.c`, I have my replacement `strcmp()` function that I
called `scmp()`.

```c
/* ----------*/
/* utilities */
/* ----------*/

int scmp(char *str1, char *str2) {
    int i;
    for (i = 0; str1[i] != '\0'; i++) {
        if (str1[i] != str2[i] || str2[i] == '\0') {
            return 0;
        }
    }
    if (str2[i] == '\0') {
        return 1;
    } else {
        return 0;
    }
}
```

This is a great place to start since this doesn't depend on any other standard
libraries or even any functions within my own code. I can pull it straight out
into another file called `utils.c`. This file will NOT have a main() function,
and I will want to compile it on its own as an object file, with a command like:

```
cc utils.c -c
```

... which yields an object file `utils.o'. Since this doesn't depend on
anything, that's all I have to do! Just the body of that function will
successfully compile.

But when I go back and try to compile the sild.c file, as you would expect, I
get an error:

```
Undefined symbols for architecture x86_64:
    "_scmp", referenced from:
    _eq in sild-XPBvI6.o
    _categorize in sild-XPBvI6.o
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

This is basically the same error as before: the compiler sees that functions
inside of sild.c call `scmp()`, but it doesn't know where that function is, it
doesn't know how to link them together.  This is where I was tempted to do this
in `sild.c` at the very top:

```c
#include <stdio.h>
#include <stdlib.h>
#include "utils.c"
```

(Angled brackets search the system libraries path first, and quotes search the
current directory the file is actually in first, for a matching name.)

This works! Because the `#include` direction instructs the compiler to simply
insert the contents of that file right at that line before compiling the whole
file together. (`#include`, like `#define` and other octothorpe beginning
thingers, are compiler preprocessor commands.) You can _just compile that main
file_ and it will work as you expect.

```
cc sild.c -o sild
```

But, this is bad news bears, and scales terribly! Consider this:

```c
#include <stdio.h>
#include <stdlib.h>
#include "utils.c"
#include "utils.c"
```

On a compilation attempt, gives the following error:

```
In file included from sild.c:5:
./utils.c:5:5: error: redefinition of 'scmp'
int scmp(char *str1, char *str2) {
    ^
./utils.c:5:5: note: previous definition is here
int scmp(char *str1, char *str2) {
    ^
```

And of course it does! It's inlining the file twice! Just as if I had typed in
the same function twice, C will complain that it has been redefined, which is a
no no.

This may seem like a contrived example, but consider including utils.c in a
file that also includes another file that _also_ include utils.c, both for valid
reasons (in that they both use the function in utils.c independently). Boom,
suddenly you've got the very same problem! You've inlined the same code more
than once and everything sucks. The answer to this problem, is header files!

As Andrew said:

> Most C programmers would find this odd, typically you include .h files and
> compile .c files independently into .o files, then link them all together.

I didn't really understand this advice fully for a while, so let me explain
what that means.

Take utils.c for example! A corresponding header file for this library would be
called `utils.h`, and it would include the function _prototype_ for any code
the library contains that will be called from outside that library's source
file. A prototype simple states the returning type, the name, and the argument
types. The arguments can be unnamed at this point, or they can have their name
in the prototype for clarity, but it doesn't matter. Basically, you just copy
the first line of the function.

```
int scmp(char*, char*);
```

The actual _definition_ of the function still happens in the `.c` file, but
declaring the function in the header allows the compiler to know about it.

We replace the `#include "utils.c"` with `#include "utils.h" in `sild.c`, and
we get the following, same error as before, when we weren't including anything
at all and had just taken the function body out.

```
Undefined symbols for architecture x86_64:
    "_scmp", referenced from:
    _eq in sild-XPBvI6.o
    _categorize in sild-XPBvI6.o
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

And of course we do! The function prototype is not the function definition!
This brings us to this foundational rule of thumb:

2. Every .c and .h file should be able to be compiled into an object file on its own.

And what Andrew had to say about this was:

> The idea is to include as little as possible (because this improves compile
> time) while still including what you depend on (this prevents shifting
> downstream dependencies from breaking upstream code). So, step 1, can you avoid
> including it? Then don't include it. Step 2, can you only include it in the .c
> file and not in the .h file? Then only include it in the .c file. Step 3, looks
> like your .h file depends on it, so you'll have to include it in your .h file.

Let's say I try to compile sild.c into it's own object file without include the
header file from utils.h:

```
cc -c sild.c
```

I get a new, different error, actually a warning:

```
sild.c:225:14: warning: implicit declaration of function 'scmp' is invalid in C99 [-Wimplicit-function-declaration]
     scmp(operand->val.label, operand2->val.label)
      ^
      1 warning generated.
```

But if I compile sild.c into am object file and include utils.h, it works, and
I get sild.o out of it.

Further, to pass this sniff test, both `utils.c` and `utils.h` should be able
to be compiled into an object file. They both do, because there is only one
function that depends on nothing else.

So great, but how do I get an executable out of this? I first compile the
libraries into their object files, then link those all together and bundle them
with the c file that has `main()` inside of it. Those commands look like this:

```
cc -c utils.c
```

yields utils.o, and

```
cc utils.o sild.c -o sild
```

Will link that library into the executable. Success!

_What about the header file itself?_

The header file itself doesn't need to get bundled into this. Basically, when
the header file states the function prototype, it tells the compiler that that
function is going to exist, so the compiler assigns it an address, like setting
aside a house for it. When the function is defined, it will move into that
house. As long as the executable knows where to find that function when it is
run, it will be fine!

<hr>

Here are some other considerations. What if `scmp()` depended on some helper
function that also would live in utils.c, but this helper function didn't need
to be exposed to the consumers of the utils library? What if it looked something like this:

```c
// utils.c

int helper_function(char *string) {
    int result;
    // stuff
    return result
}

int scmp(char *str1, char *str2) {
    int thing_i_need = helper_function(str1);
    // stuff that uses thing_i_need
    // ...
    return // whatever
}
```

In this case, `helper_function()` does not need to live in the header file at
all. It is an implementation detail that lives inside the black box that is
`utils.c`, and as such, it should be marked _static_, like this:

```c
static int helper_function(char *string) {
    int result;
    // stuff
    return result
}
```

Which tells the compiler that it is not needed outside of its defining module,
effectively limiting that function's scope to it's translation unit (the object
file that that c file is compiled into)!

> 3. ...oh yeah, and if a function is only used in this file, mark it as static and
> don't give it a prototype in the .h file. this will optimize better and keeps
> things more encapsulated

Header guards
-------------

It is traditional to wrap .h files inside of _header guards_ so that they are
only processed once no matter how many files `#include` them. A header guard
looks like this:

```c
#ifndef UNIQUENAME_GUARD // if UNIQUENAME_GUARD is not defined
#define UNIQUENAME_GUARD // define it (to nothing, but it is still defined)

// ...header file prototypes, constants, etc

#endif // end the if block
```

All of the standard library headers have this, for example, `stdio.h` starts with:

```c
#ifndef _STDIO_H_
// ...some stuff
#define _STDIO_H_
// ...some stuff
#endif /* _STDIO_H_ */
```

Guard constants that start with underscores are reserved for system library
usage.

Not processing all these prototypes multiple times is good for compiler
performance. It doesn't really matter so much in a small project like mine, but
in a bigger project with giant header files, that type of optimization can
really make a difference, and it is good practice to do it.

So, `utils.h` will look like this:

```c
#ifndef UTILS_GUARD
#define UTILS_GUARD

int scmp(char*, char*);

#endif
```

<hr>

And that's that! To recap:

1. Every .c file gets a .h file that exposes the function prototypes of its
   public facing functions.
2. Every .c and .h file should be able to compile into an object file
   independantly of all other files while using the `-c` flag.
3. functions etc should be marked static if they are not being used outside of
   their compilation unit.
4. .h files should include header guards as a general rule.

I went through `sild.c` and factored out 6 distinct units in this way.

1. utils.c has scmp().
2. cell.c has all the cell structures and con/destructors.
3. eval.c has eval/apply and exposes eval.
4. builtins.c has all of the builtin functions.
5. print.c has all of the debug/print functions.
6. read.c contains the reader and exposes `read()`.

One thing I want to point out is that struct and union prototypes should
include their member declarations if their internals need to be accessed
outside of the compilation unit. In my case, they did, so cell.h has those, and
cell.c includes its own .h file since it needs access to those definitions as
well.

<hr>

The only thing left in sild.c is the main() function, so I'll rename that to main.c

Now, to get an executable, I would compile each library module (including
main.c itself) into an object file and then link them all together, just like
Andrew said originally.

```
cc utils.c -o
cc cell.c -o
cc eval.c -o
cc builtins.c -o
cc print.c -o
cc read.c -o
cc main.c -o
cc utils.o cell.o eval.o builtins.o print.o read.o main.o -o sild
```

These are a lot of commands to run every time I want to get a new executable!
If only there were a way to further automate this build process...

<hr>

Very big thanks to Andrew Kelley for his extremely well reasoned and cogently
worded answers to my noob C questions. I was very surprised how much of a mind
bender resolving dependencies in C turned out to be, and though I'm sure there
is still a lot to learn about this, I feel very good about the practices
presented in this post being a reasonable starting point. I can also see how
undisciplined dependancy management can be a hell of a noose, an intuition that
was born out in my research. This is a hard problem!
