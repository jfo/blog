---
title: Sild6 error handling
layout: post
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

At the very least, I need to guarantee somehow that the number of open and
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

Derr, still doesn't work. If you look at the `read` ase for `')'`, you can see
why. This reader never goes past the first closing paren, because there is not
a call to `read` inside that case to move forward! This is the intended
behavior... I'm returning `&nil` there, which is what I want.

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
