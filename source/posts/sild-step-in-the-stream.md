---
title: Sild - step in the stream
layout: post
date: 2016-07-07
tags: rc
---

Alright! I've got a nicely refactored `src` directory and a `makefile` that I'm
not embarassed to show people. I'd like to turn my attention to the input mode
for this interpreter.

So far, Ive just been sending in C strings to be read by the reader. This is
working fine for the small examples I've been showing, but I would like the
input mode to both be more robust and also to support reading files directly
into it. As written, I _could_ make a buffer, read some amount of a file into
it as a string, and then read that string using the existing read function.
This would work fine and is a straightforward way to read a file into the
program space. But it comes with some pitfalls! How big does this buffer need
to be? It would need to be as big as the biggest sild form I want to read in.
How big is that? I have no idea. A program could conceivably be hundreds of
lines of one parenthetical form, I would have to read ahead to allocate the
appropriate amount of buffer memory, or else build a buffer that could resize
itself if it needed to. There's nothing wrong with this idea, but I would
prefer a read function that reads in real time and doesn't have any need to
muck around with buffer reallocation, and I had already spent so much time
optimizing the read function to operate in constant time on strings- why would
I want to undermine that?

Enter the Stream
----------------

So C has this funny typedef called a `FILE*`, which is a file pointer. This is
how files are represented in I/O. In some ways, the functions that operate on
them act a lot like string functions- except that instead of a NULL byte
(`'\0'`) being the terminal character, the file ends with an `EOF` (end of
file) byte, which is a constant defined in `<stdio.h>` that usually equals
`-1`. (The standard dictates that `EOF` must be negative, but does not dictate
the value- though it is usually -1).

But, `FILE` pointers are _not_ strings. They are in fact structs that contain
quite a bit of metadata about the chunk of memory that the FILE object was
initialized to. Though the inner workings of a FILE object are implementation
specific, here is an example of what is in my computer's `<stdio.h>` where
`FILE` is typedeffed

```c
typedef	struct __sFILE {
	unsigned char *_p;	/* current position in (some) buffer */
	int	_r;		/* read space left for getc() */
	int	_w;		/* write space left for putc() */
	short	_flags;		/* flags, below; this FILE is free if 0 */
	short	_file;		/* fileno, if Unix descriptor, else -1 */
	struct	__sbuf _bf;	/* the buffer (at least 1 byte, if !NULL) */
	int	_lbfsize;	/* 0 or -_bf._size, for inline putc */

	/* operations */
	void	*_cookie;	/* cookie passed to io functions */
	int	(*_close)(void *);
	int	(*_read) (void *, char *, int);
	fpos_t	(*_seek) (void *, fpos_t, int);
	int	(*_write)(void *, const char *, int);

	/* separate buffer for long sequences of ungetc() */
	struct	__sbuf _ub;	/* ungetc buffer */
	struct __sFILEX *_extra; /* additions to FILE to not break ABI */
	int	_ur;		/* saved _r when _r is counting ungetc data */

	/* tricks to meet minimum requirements even when malloc() fails */
	unsigned char _ubuf[3];	/* guarantee an ungetc() buffer */
	unsigned char _nbuf[1];	/* guarantee a getc() buffer */

	/* separate buffer for fgetln() when line crosses buffer boundary */
	struct	__sbuf _lb;	/* buffer for fgetln() */

	/* Unix stdio files get aligned to block boundaries on fseek() */
	int	_blksize;	/* stat.st_blksize (may be != _bf._size) */
	fpos_t	_offset;	/* current lseek offset (see WARNING) */
} FILE;
```

As you can see, the FILE struct has a lot of extra stuff in it that the library
functions operate on and with. Now, it's not super important to understand the
details of the inner workings of a FILE object in order to use it, in fact, it
is actively discouraged. Everywhere I see info on the FILE object, I am
implored to "let the library functions handle interactions" with it, and stuff
like that. Hey, fine with me! The basic idea is that you `fopen()` a file,
which returns a pointer to a FILE object, which has a member `_p`_ that is a
pointer to the beginning of the chunk of memory that the actual file lives on
in the system. From there, you use library functions to interact with that
file- retrieving information from it, writing to it, whatever.

Here is a tiny program that opens a file, and prints each character to stdout,
and then exits.

```c
#include <stdio.h>

int main() {
    FILE *fp = fopen("test.txt", "r");
    char current_char;

    while ((current_char = getc(fp)) != EOF)
        printf("%c", current_char);

    fclose(fp);

    return 0;
}
```

So, `fopen` opens a new stream connected to a FILE object in read mode (the
second argument to fopen is the mode, "r" is read mode!) and associates it with
the file `test.txt` which is in the working directory, assigning that pointer
to the `fp` variable (which seems to be customary, and stands for 'file
pointer'). In the while loop, each iteration reassignes the var `current_char`_
to the next character in the stream by grabbing it using `getc()`, which
implicitly advances the pointer to the next position after returning the
current character. Eventually, the `EOF` value is reached, and the while loop
exits. I then `fclose()` the connection to the file because I clean up after
myself.

A FILE, despite its name, is actually usually referred to as a stream
in C, for "historical reasons" (as vaguely stated in the [GNU
manual](ftp://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_chapter/libc_12.html))

This "stream" idea is a more flexible interpretation of what is happening with
regard to FILE objects, as they serve as a universal interface to many UNIX
systems and IO devices- consider that the same abstraction is in play when a
device interface is represented as a 'device file' in `/dev/*`. I wrote about
that while playing with monomes [here](/monome-part-mono/). This is a FILE in
name only, and actually serves as a powerful abstraction api over top of the
device that it is meant to represent.

Further, we've already interfaced quite a bit with standard streams such as
standard out (`stdout`) and standard error (`stderr`), which are both FILE
pointers despite not _really_ being files in the sense of "a location of static
memory on disk".

I'm sure there is plenty more interesting stuff to learn about `FILE`s and
streams! I fully intend to learn those things! But this is enough to refactor
my read function to accept streams instead of strings!

This was actually _way easier_ to do than I thought it would be. Once I had
sorted out the details of what interacting with a stream actually entails,
modifying `read` to accept a stream was pretty straightforward! In fact, the
unified diff is actually a great illustration of the changes I had to make:

```diff
-C * read(char **s) {
-    char current_char = **s;
+C * read(FILE *s) {
+    char current_char = getc(s);

     verify(current_char);

     switch(current_char) {
-        case ')': case '\0':
+        case ')': case '\0': case EOF:
             list_depth--;
-            (*s)++;
             return &nil;
         case ' ': case '\n':
-            (*s)++;
             return read(s);
         case '(':
             list_depth++;
-            (*s)++;
             return makecell(LIST, (V){.list = read(s)}, read(s));
         default: {
+            fseek(s, -1, SEEK_CUR);
             return categorize(s);
         }
     }
```

I only have to dereference the current char at the beginning of the function,
which implicitly advances the pointer, so I can remove all the conditional
`(*s)++`* businesses. This does mean that I have to _explicitly_ retract the
pointer before passing it into categorize, because categorize expects to see
the _first_ char in a substring. I do that with:

```c
fseek(s, -1, SEEK_CUR);
```

Which takes a FILE pointer (s), and moves it the offset `-1` positions from
`SEEK_CUR`_, which is an enum that `fseek` interprets to mean 'the file
pointer's current position.

Naturally, the helper functions that `read()` uses will also have to be
converted to accepting FILE pointers in a very similar way:

```diff
+#include <stdio.h>
 #include <stdlib.h>

 #include "util.h"
@@ -10,16 +11,19 @@
 /* ------ */

 static int is_not_delimiter(char c) {
-    return (c != ' ' && c != '\0' && c != '(' && c != ')');
+    return (c != ' ' && c != '\0' && c != '(' && c != ')' && c != EOF);
 };

-static char *read_substring(char **s) {
+static char *read_substring(FILE *s) {
     int l = 0;
-    while (is_not_delimiter((*s)[l])) { l++; }
+    while (is_not_delimiter(getc(s))) { l++; }
     char *out = malloc(l);
     if (!out) { exit(1); }
+
+    fseek(s, -l - 1, SEEK_CUR);
+
     for (int i = 0; i < l; i++) {
-        out[i] = *((*s)++);
+        out[i] = getc(s);
     }
     out[l] = '\0';
     return out;
@@ -40,7 +44,7 @@ static void verify(char c) {
     }
 }

-static C* categorize(char **s) {
+static C* categorize(FILE *s) {
     char *token = read_substring(s);
     if (scmp(token, "quote")) {
         return makecell(BUILTIN, (V){ .func = {token, quote} }, read(s));
@@ -61,24 +65,22 @@ static C* categorize(char **s) {
     }
 }
```

I've added `EOF` to the list of delimiters, and replaced all the string pointer
dereferencings with calls to `getc()`. I've also changed the function prototype
in `read.h` to reflect the new typing. Overall, this actually makes things a
lot more readable, I think!

<hr>

So, back in `main.c`, the diff looks pretty simple!

```diff
 int main() {

-    char *a_string = "(cons ((cond car) (quote (1))) (cdr (quote (2 3 4 5))))";
+    FILE *input = fopen("./test.sld", "r");

-    C *a_list          = read(&a_string);
+    C *a_list          = read(input);
     C *an_evalled_list = eval(a_list);
                          print(an_evalled_list);
                          /* debug_list(an_evalled_list); */
    return 0;
}
```

Now, a file called `test.sld` will open, and be read just like the string was
read, in constant time and with _no buffering_.

<hr>

I will next modify read to only grab the next form in a stream, instead of
reading in the whole thing at once. I've implicitly been creating a top level
sild list out of all the forms in a string, but this is not really what I want.
A Sild file is an ordered series of atoms and lists, yes, but other than being
next to each other they aren't actually connected in the same structure. I want
read to take in a stream, return the next form in the stream, and advance the
pointer past it so that the next time it is called, it returns the next form
after that! For this, our old friend `list_depth`, that helped identify whether
or not the pointer was currently inside of a list or not. This should happen
inside of categorize. Basically, an atom should be stitched to the next form if
and only if it is inside of a list, which we'll know if the list_depth is > 0.

```c
static C* categorize(FILE *s) {
    char *token = read_substring(s);
    C *out;

    if (scmp(token, "quote")) {
        out = makecell(BUILTIN, (V){ .func = {token, quote} }, &nil);
    } else if (scmp(token, "car")) {
        out = makecell(BUILTIN, (V){ .func = {token, car} }, &nil);
    } else if (scmp(token, "cdr")) {
        out = makecell(BUILTIN, (V){ .func = {token, cdr} }, &nil);
    } else if (scmp(token, "cons")) {
        out = makecell(BUILTIN, (V){ .func = {token, cons} }, &nil);
    } else if (scmp(token, "atom")) {
        out = makecell(BUILTIN, (V){ .func = {token, atom} }, &nil);
    } else if (scmp(token, "eq")) {
        out = makecell(BUILTIN, (V){ .func = {token, eq} }, &nil);
    } else if (scmp(token, "cond")) {
        out = makecell(BUILTIN, (V){ .func = {token, cond} }, &nil);
    } else {
        out = makecell(LABEL, (V){ token }, &nil);
    }

    if (list_depth > 0) {
        out->next = read(s);
    }

    return out;
}
```

Now, I've been ok with having this global var hanging around, but _no more_.
What if I want to call `read` recursively on multiple streams? Suddenly I have
to figure out when and where to reset list_depth to 0 in order to read
everything in accurately. This is no good! I'll instead pass depth as an
argument to all of the reader family functions, which avoids maintaining the
global var list_depth completely! Just like in the print functions, depth will
be a local variable to whatever frame is running it, allowing me to leverage
the C stack to keep track of local depth for me!

```c
static C * read_inner(FILE *s, int list_depth) {
    char current_char = getc(s);

    verify(current_char, list_depth);

    switch(current_char) {
        case '\0': case EOF:
            return &nil;
        case ')':
            return &nil;
        case ' ': case '\n':
            return read_inner(s, list_depth);
        case '(':
            return makecell(
                    LIST,
                    (V){.list = read_inner(s, list_depth + 1)},
                    (list_depth > 0 ? read_inner(s, list_depth) : &nil)
                    );
        default:
            fseek(s, -1, SEEK_CUR);
            return categorize(s, list_depth);
    }
}

C * read(FILE *s) {
    return read_inner(s, 0);
}
```

Just like `debug_list` and `print`, I've not changed the interface to these
functions at all, but wrapped them in a helper that always initializes to a
depth of 0.

Now, given a filename, I can write a little function that iterates through all
the forms in a file, evaluates them, and frees the result before moving on to
the next one!

```c
void eval_file(const char *filename) {
    FILE *fp = fopen(filename, "r");

    C * c;
    while((c = read(fp)) != &nil) {
        c = eval(c);
        print(c);
        free_cell(c);
    }

    fclose(fp);
}

int main() {
    eval_file("./test.sld");
    return 0;
}
```

Notice that `eval_file` knows to terminate on `read` returning a `&nil` cell,
which it does at the top level only if it runs into a terminal char, in this
case being `EOF`. Reusing that sentinal node ftw!

If `test.sld` looks like this:

```
(car (quote (1 2 3)))
(cdr (quote (1 2 3)))
```

Running it will read, evaluate, and print each form in turn, and output the following:

```
1
(2 3)
```

Alright! I can now run sild files directly through the interpreter! This is a
big step! Only one more thing to do with this, which is to adjust the main
function to accept arbitrary filenames to be run through this function.

<hr>

`main()` always implicitly accepts two arguments when an executable is invoked
from the command line, despite the fact that the function signature as been
declared so far doesn't seem to accept any. The real function prototype looks like this:

```c
int main(int argc, char *argv[]);
```

Though the names of these arguments are arbitrary, these are the customary
names. `argc` means "argument count" and is an integer representing the number
of arguments passed to the executable on invocation. This number is always at
least 1, because the first argument to an executable is the name by which it
was invoked. `argv` is a null terminated array of strings that are the actual
arguments passed to main. They could be anything! What you do with them is up
to the program.

Here is a program that prints out the arguments passed to it.

```c
#include <stdio.h>

int main(int argc, char *argv[]) {

    for (int i = 0; argv[i] != 0x0; i++) {
        printf("%s\n", argv[i]);
    }

    return 0;
}
```

So compiling this into an executable called `a.out` and then executing that would do this:

```
$ ./a.out derp thing otherthing 1 2 3 -f -r -g stuff
./a.out
derp
thing
otherthing
1
2
3
-f
-r
-g
stuff
```

Notice there is nothing _inherently_ special about flag arguments, to use them
as options etc, they have to be pulled out of the argument list by some helper
function or something. I haven't looked yet, but I bet there are a bunch of
libraries to healp with that! Immediate edit:
[yup!](http://www.gnu.org/software/libc/manual/html_node/Getopt.html#Getopt)

Using a loop really similar to that one, I can take in a list of file names and
evaluate them in order, using my new `eval_file()` function!

```c
int main(int argc, char *argv[]) {
    for (int i = 1; argv[i] != NULL; i++) {
        eval_file(argv[i]);
    }

    return 0;
}
```

Notice that I'm starting with an index of 1, because I don't want to try and
eval the executable, which is the index of 0 in argv!

Final touch- what if I don't pass anything at all? Usually this would open a
repl to the language, but I haven't implemented that yet, so I'll exit with an
error if the argument count is equal to only 1.

```c
int main(int argc, char *argv[]) {
    if (argc == 1) {
        fprintf(stderr, "Error, no file names given and repl not yet implemented.\n");
        exit(1);
    }

    for (int i = 1; argv[i] != NULL; i++) {
        eval_file(argv[i]);
    }

    return 0;
}
```

Now, when I `make` the project, I end up with an executable that can be run
just like I would expect it to be run.

```bash
$ ./sild test.sld
```

Will evaluate the file!
