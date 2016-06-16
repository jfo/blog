---
title: Sild - match those parens
layout: post
date: 2016-06-16
tags: rc
---

I mentioned that this isn't a very resilient reader right now.

```c
"1 2 3"
```

Is read in as

```c
LABEL- Address: 0x7f91eac03a70, Value: 1 Next: 0x7f91eac03a50
LABEL- Address: 0x7f91eac03a50, Value: 2 Next: 0x7f91eac03a30
LABEL- Address: 0x7f91eac03a30, Value: 3 Next: 0x10d177028
NIL- Address: 0x10d177028
-------------------------------------------------------
```

Which is accurate- it is just three atoms in isolation (remember, right now,
all atoms are simpy LABELs, the language doesn't know about any other types, so
currently a LABEL is just a string that could be any characters except for
whitespace and parens).

And

```c
"(1 2 3)"
```

is read as

```c
LIST- Address: 0x7f9780403a90, List_Value: 0x7f9780403a70 Next: 0x10bec2028
|   LABEL- Address: 0x7f9780403a70, Value: 1 Next: 0x7f9780403a50
|   LABEL- Address: 0x7f9780403a50, Value: 2 Next: 0x7f9780403a30
|   LABEL- Address: 0x7f9780403a30, Value: 3 Next: 0x10bec2028
|   NIL- Address: 0x10bec2028
-------------------------------------------------------
NIL- Address: 0x10bec2028
-------------------------------------------------------
```

Which is also correct. The final `NIL` that comes from the `'\0'` byte at the
end of the input string is a little bit offputting, but acceptable for now.

But what about

```c
"(1 2 3"
```

? This is _clearly_ a syntax error, and yet...)

```c
LIST- Address: 0x7fb983403a90, List_Value: 0x7fb983403a70 Next: 0x10c690028
|   LABEL- Address: 0x7fb983403a70, Value: 1 Next: 0x7fb983403a50
|   LABEL- Address: 0x7fb983403a50, Value: 2 Next: 0x7fb983403a30
|   LABEL- Address: 0x7fb983403a30, Value: 3 Next: 0x10c690028
|   NIL- Address: 0x10c690028
-------------------------------------------------------
NIL- Address: 0x10c690028
-------------------------------------------------------
```

Harumph. At the very least this should blow up completely.

What about

```c
"1 2 3))))))"
```

gives

```c
LABEL- Address: 0x7fe913403a70, Value: 1 Next: 0x7fe913403a50
LABEL- Address: 0x7fe913403a50, Value: 2 Next: 0x7fe913403a30
LABEL- Address: 0x7fe913403a30, Value: 3 Next: 0x1052df028
NIL- Address: 0x1052df028
-------------------------------------------------------
```

Psh.

<hr>

I need to guarantee somehow that the number of open and
closing parens are equal at the end of the input. A simple solution is to
create a global counter and increment it when I see an opening paren, decrement
when I see a closing paren, and check that it is `0` at the end of the string.

```c
int list_depth = 0;
C * read(char **s) {
    switch(**s) {
        // now I have a reason to give '\0' its own case
        case '\0':
            if (list_depth != 0) {
                // this may not be very informative as of yet but it gets the jorb done
                exit(1);
            } else {
                return &nil;
            }
        case ')':
            list_depth--;
            (*s)++;
            return &nil;
        case ' ': case '\n':
            (*s)++;
            return read(s);
        case '(':
            list_depth++;
            (*s)++;
            return makecell(LIST, (V){.list = read(s)}, read(s));
        default: {
            return makecell(LABEL, (V){read_substring(s)}, read(s));
        }
    }
}
```

So let's try

```c
"(1 2 3"
```

```c
shell returned 1
```

OOOOOK.

How about...

```c
"1 2 3))))"
```

```c
LABEL- Address: 0x7fa219403a70, Value: 1 Next: 0x7fa219403a50
LABEL- Address: 0x7fa219403a50, Value: 2 Next: 0x7fa219403a30
LABEL- Address: 0x7fa219403a30, Value: 3 Next: 0x102f17030
NIL- Address: 0x102f17030
-------------------------------------------------------
```

Derr, still doesn't work. If you look at the `read` case for `')'`, you can see
why. This reader never goes past the first closing paren, because there is not
a call to `read` inside that case to move forward! This is the intended
behavior... I'm returning `&nil` there, which is what I wanted.

There are two cases in which the string can be in an erroneous form.

1- a closing paren occurs without a preceding opening paren
2- the end of the string is reached and the `list_depth` count is _not_ 0.

I need to verify that _each_ char in the string satisfies that neither of these
conditions are met. I can pull that out into a helper function, that looks like this:

```c
// this var still needs to be global so that read() can increment / decrement it
int list_depth = 0;
void verify(char c) {
    if (
            (c == ')' && list_depth == 0)
            ||
            (c == '\0' && list_depth != 0)
       )
    {
        exit(1);
    }
}
```

And now I can call it in the `read()` function:

```c
C * read(char **s) {
    char current_char = **s;

    verify(current_char);

    switch(current_char) {
        case ')': case '\0':
            list_depth--;
            (*s)++;
            return &nil;
        case ' ': case '\n':
            (*s)++;
            return read(s);
        case '(':
            list_depth++;
            (*s)++;
            return makecell(LIST, (V){.list = read(s)}, read(s));
        default: {
            return makecell(LABEL, (V){read_substring(s)}, read(s));
        }
    }
}
```

This function has no return value, it simply exits with a generic `1` exit code
if any of these conditions exist.

<hr>

There is another possible error case hiding in this program.

`malloc()` _can fail_. If it fails, say if the system isn't able to provide the requested memory, or whatever, it returns a `NULL` pointer. No bueno. Wherever I call `malloc`, I should also check to see that it returned a valid memory address.

Right now, that would be in `makecell()`

```c
C *makecell(int type, V val, C *next) {
    C *out = malloc(sizeof(C));

    if (!out) { exit(1); }

    out->type = type;
    out->val = val;
    out->next = next;
    return out;
};
```

And in `read_substring()`

```c
char *read_substring(char **s) {
    int l = 0;
    while (is_not_delimiter((*s)[l])) { l++; }
    char *out = malloc(l);

    if (!out) { exit(1); }

    for (int i = 0; i < l; i++) {
        out[i] = *((*s)++);
    }
    out[l] = '\0';
    return out;
};
```

This failure case is unlikely, but it needs to be accounted for.

This is _very basic_ error handling. I've just guaranteed that in these cases
of obvious catastrophic failures- syntax errors or malloc failures, the the
program will stop running. It doesn't report any information to the user, it's
not very helpful, but it is a step in the right direction.

I can add at least a little bit of messaging before each exit to give some
context as to the failue. `fprintf()` can be used to write a formatted string
to an arbitrary stream, I'll pass in `stderr` as it is the appropriate standard
stream for messaging errors.

In `verify()`:

```c
fprintf(stderr, "Syntax Error: mismatched parens");
exit(1);
```

and in `makecell()` and `read_substring()`, respectively:

```c
fprintf(stderr, "System Error: makecell failed to allocate memory.");
fprintf(stderr, "System Error: read_substring failed to allocate memory.");
```

<hr>

Traditionally, a LISP cell is known as a `cons` cell, its value is referred to
as `car`, and its `next` member is referred to as `cdr` (pronounced 'cutter').
The reasons for this are [historical](https://en.wikipedia.org/wiki/CAR_and_CDR#Etymology):

> Lisp was originally implemented on the IBM 704 computer, in the late 1950s.
> The 704 hardware had special support for splitting a 36-bit machine word into
> four parts, an "address part" and "decrement part" of 15 bits each and a
> "prefix part" and "tag part" of three bits each.

> Precursors[1] [2] to Lisp included functions:

> ```
> car (short for "Contents of the Address part of Register number"),
> cdr ("Contents of the Decrement part of Register number"),
> cpr ("Contents of the Prefix part of Register number"), and
> ctr ("Contents of the Tag part of Register number"),
> ```
> each of which took a machine address as an argument, loaded the corresponding
> word from memory, and extracted the appropriate bits.  A machine word could
> be reassembled by cons, which took four arguments (a,d,p,t).  The prefix and
> tag parts were dropped in the early stages of Lisp's design, leaving CAR,
> CDR, and a two-argument CONS.

I've eschewed this naming convention internally in the cell structure so far,
because I want to avoid confusion with the functions of the same names that I
will be implementing later on, but, the cell struct could easily have looked like
this.

```c
typedef struct Cons {
    enum CellType type;
    union V car;
    struct Cons * cdr;
} Cons;
```

<hr>

This program now does a pretty good job of turning a parenthetical abstract
syntax tree expressed in traditional LISP syntax from a string of `char`s into
a data structure that is easy to work with inside of the program. Let's recap a
little bit.

- All data is represented as a series of cells.
- cells have two parts, a `value` and a pointer to the `next` cell in the list
  (and a type signature, but I consider that metadata!).
    - The value of a cell can be one of two things: an atom (currently just a
      `LABEL`, represented as a string), or another `LIST` represented as a pointer
      to the first cell of a sub list.
        - lists can be nested to arbitrary depths and end when a cell inside of
          it points to `NIL` as its next value. `NIL` is a special value that
          only exists in one place in memory; since all `NIL` cells are the
          same, we can point to the same location to represent `NIL` anywhere.
