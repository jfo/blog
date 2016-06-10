---
title: Sild - Reading substrings
layout: post
date: 2016-06-8
tags: rc
---

[In the last post, I made a simple little linked list](/sild-is-a-list).

I can't expect to make every single cell in a list by hand, of course. I need a
way to turn some kind of input into a set of cells that are all semantically
linked together. I need a function that reads a string and outputs a linked
list! Here's a good first go, annotated:

```c
C * read(char *s) {
    if (*s == '\0') {
        return NULL;
    } else {
        return makecell(*s, read(s + 1));
    }
}
```

This function returns a pointer to the first cell in the new linked
list. As we saw before, from there we can access further elements by traversing
the `next` members in each cell.

This function accepts a string. In C, strings are not a primitive type,
they're instead represented by a pointer address that points to the location of
the first character in the string. C strings are NULL terminated, which means
that it goes from the "starting" point, to the next null byte. The null byte
here is represented by '\0', but it could just as well be `NULL` or `0` or
`0.0` or `0x0`. They are all equal to the same thing, which is absolute 0,
which is the null byte. Functions that operate on strings implement loops that
go until they run into a null byte, and this one will do that, too.

Notice the `*s`'s. This is called 'dereferencing'. When we 'dereference' the
pointer we've been given, it returns the actual content of that memory address.
Let's say we're passing in a string like so:

```
read("a");
```

Now, it looks like that string constant is one byte long, and it is... sort of.
The _contents_ of that string are only one byte long, but it takes up two
contiguous bytes in memory, and looks something like this:

```
['a']['\0']
```

This is the difference between single and double quotes in C. A double quote
represents a string literal, and a single quote represents a single `char`.

> I'm going to change the struct that represents a cell now, so that the `val`
> member holds a `char` instead of an `int`. This will make it easier to think
> about parsing strings. From now it will look like this:

> ```c
> typedef struct C {
>     char val;
>     struct C * next;
> } C;
> ```

So, the function above would look at `"a"`, and find that the first char in the
string is `'a'`, and create a cell using `makecell()` whose `val` is `'a'`, and
whose `next` cell is...

```
read(s + 1)
```

Why are we adding `1` to a ... string?

We're not adding `1` to a string, we're adding `1` to the *address* that we were
originally given. We're saying, in effect, "Tell me what is right after the
first character in memory." This call to `read()` sees whatever the first call
saw, but starting on the second `char`. In this case, that's the `NULL` byte!
On the second call, we're returning the `NULL` pointer. So the final structure
of this linked list looks like this, it is currently just one cell long:

```c
{ 'a', 0x0 }
```

How about `read("abcde")`

```c
{ 'a', 0x7fe6514034c0 },
{ 'b', 0x7fe6514034a0 },
{ 'c', 0x7fe651403480 },
{ 'd', 0x7fe651403460 },
{ 'e', 0x0 }
```

This is a little more complicated! Each character has been loaded into a cell
whose `val` is the `char` at the location it was given, and whose `next` member
contains the memory address of the return value of the successive call to
`read()`. Those numbers are pointers that represent memory addresses, and are
the return value of `malloc()` via `makecell()`.

> You might notice that the linked list structure we're using has something in
> common with the general string structure in C itself... they are both `NULL`
> terminated! In fact, I've written a `read()` function that turns a C string
> (which takes up contiguous space in memory) to a linked list of `char`s whose
> elements could be stored in arbitrary places.

Now we're cooking with gas!

<hr>

Let's see...

```
read("a b c d e");
```

This will make a linked list that looks like this:

```c
{ 'a', 0x7fe6514034c0 },
{ ' ', 0x7fe6514034a0 },
{ 'b', 0x7fe651403480 },
{ ' ', 0x7fe651403460 },
{ 'c', 0x7fe651403440 },
{ ' ', 0x7fe651403420 },
{ 'd', 0x7fe651403400 },
{ ' ', 0x7fe6514033fe },
{ 'e', 0x0 }
```

This is doing what I told it to do. A space is indeed a `char` `' '`. But I
don't really care about space characters. If I add an `if else` clause to my
function, I can simply ignore the input if it's a space char.

```c
C * read(char *s) {
    if (*s == '\0') {
        return NULL;
    } else if (*s == ' ') {
        return read(s + 1);
    } else {
        return makecell(*s, read(s + 1));
    }
}
```

I'm going to change this from a series of if statements to a `switch`. Because
in some ways it's cleaner. The code below is functionally equivalent to the
code above, and while we're at it, let's also ignore `\n` newline `char`s in
the input:

```c
C * read(char *s) {
    switch(*s) {
        case '\0':
            return NULL;
        case ' ':
        case '\n':
            return read(s + 1);
        default:
            return makecell(*s, read(s + 1));
    }
}
```

It's easy to think of switch statements as a simple refactor of `if` and `else
if` and `else` clauses when dealing with the various possible states of a
single variable being compared to constant values, and they do often play
that role, but there are some subtle differences and weird little gotchas.
Look at this:

```c
int main() {
    int x = 1;
    switch(x) {
        case 1:
            printf("%i", x);
        case 2:
            printf("%i", x);
        case 3:
            printf("%i", x);
        default:
            printf("%i", x);
    }
    return 0;
}
```

At a glance, you would expect this code to print out `x` once, no matter what
it is. But it does not!

If `x` is 1, then this will print `1111`.

`2` will output `222`.

`3` will print `33`,

and any other value will print `x` one time.

Under the hood, a switch statement produces jump instructions that act like
simple `goto` statements. If `x` is 2 at the switch, then it will jump to the
point in the code where this case is stated. After that, it will execute all
the remaining lines in the switch unless you break it off, either explicitly
with a `break` statement, like this:

```c
int main() {
    int x = 1;
    switch(x) {
        case 1:
            printf("%i", x);
            break;
        case 2:
            printf("%i", x);
            break;
        case 3:
            printf("%i", x);
            break;
        default:
            printf("%i", x);
            break;
    }
    return 0;
}
```

Or implicitly, with a return statement, as I've done above with the `read` function.

<hr>

The `print_list()` function I've been using so far has been useful, but I'd like
more information about the cells that a list is composed of. Here is a function
called `debug_list()`, which has the same basic structure as `print_list`, but
prints out all of the information for each cell.

```c
void debug_list(C *c) {
    printf("Address: %p, Value: %c, Next: %p\n", c, c->val, c->next)
    if (c->next) {
        debug_list(c->next);
    }
}
```

So something like `debug_list(read("abcd"))` would output something like

```
Address: 0x7fb9cbc033f0, Value: a, Next: 0x7fb9cbc033e0
Address: 0x7fb9cbc033e0, Value: b, Next: 0x7fb9cbc033d0
Address: 0x7fb9cbc033d0, Value: c, Next: 0x7fb9cbc033c0
Address: 0x7fb9cbc033c0, Value: d, Next: 0x0
```

Notice that, as you would expect, each cell's `next` member is the same as the
next cell's `Address`, with the exception of the last cell, whose `next` member
is, again, the `NULL` pointer.

<hr>

It's all well and good to be able to read in individual chars as values for
each cell, but it's not very practical in the long run to only have single char long
labels for everything. I need to be able to read in arbitrarily long strings, instead.

First, I'll have to adjust the `val` member once again, to be a C string (a pointer to a char) instead of a `char` by itself.

```c
typedef struct C {
    char * val;
    struct C * next;
} C;
```

The final new read function will look like this (let's work backwards):

```c
C * read(char *s) {
    switch(*s) {
        case '\0':
            return NULL;
        case ' ': case '\n':
            return read(s + 1);
        default:
            return makecell(read_substring(s), read(s + count_substring_length(s) + 1));
    }
}
```

As you can see, I need two new functions. `read_substring()` and
`count_substring_length()`.

```c
char *read_substring(char *s) {
    int len = count_substring_length(s);
    char *out = malloc(len + 1);
    for (int i = 0; i < len; i++) {
        out[i] = s[i];
    }
    out[len] = '\0';
    return out;
};
```

This function is manually copying the substring into a new, `malloc()`ed
location, and returning the pointer to that location. I need to know how much
space to allocate, though, and that's where `count_substring_length()` comes in.

```c
int count_substring_length(char *s) {
    int i = 0;
    while (s[i] != ' ' && s[i] != '\0' && s[i] != '\n')
        i++;
    return i;
}
```

This function is very simple, it just increments a counter `int i` for every
character in a string that is not a space, a newline character, or a `NULL`
byte. What you get back is a number that is equal to the amount of bytes needed
to store the substring in question, including the one slot for the `'\0'` which
will terminate the new string.

I'll use that `count_substring_length()` in a couple of places. Once in the
`read_substring()` function itself, for the aforementioned allocation, and
another time in the succession call to `read()` at the tail of the switch
statement, when I need to know how much to increment to pointer so that I'm
starting at the _end_ of the substring that I just processed. This will make
more sense with an example. Let's make a list out of `"red balloons"`.

`read("red balloons")` will look at the first char it was given. It is the
default case in the switch, so it will

```c
return makecell(read_substring(s), read(s + count_substring_length(s) + 1));
```

The first `read_substring` will first pass the string into
`count_substring_length` to figure out the allocation.

`count_substring_length` will increment until it hits a terminal char, in this
case a space. "red" is the substring, which is 3 bytes long.

Back in `read_substring()`, `malloc()` will allocate space for those 4 bytes,
plus 1 more for the terminating `'\0'` in the copied string, and then, one by
one, copy each char of the substring into the newly `malloc()`'ed space, then
tagging the end of it with a `'\0'`, then returning that pointer, which is
loaded into the new cell's `val` member in the call to `makecell()`. Having
read in the substring, the read function needs to know how far ahead to skip in
the input string `"red balloons"` to get past the substring it's processed, so
it counts ahead again, in the line

```c
return makecell(read_substring(s), read(s + count_substring_length(s) + 1));
```

and adds one more to get past the terminating space. The next call to `read()`
will then see `"balloons"` by itself, and then read in *that* substring, and
finally we'll end up with a list of just two elements, instead of an element
for each char as we had before.

```
Address: 0x7ffb21c033f0, Value: red, Next: 0x7ffb21c033e0
Address: 0x7ffb21c033e0, Value: balloons, Next: 0x0
```

Now, we have a way to turn some input (a random string) into a linked list
structure that contains a bunch of cells that contain substrings of that
original string. We also have a couple of functions that can operate on the
resulting linked list. Those functions, as they develop, will serve as the
prototypes for _all_ functions that operate on these lists.
