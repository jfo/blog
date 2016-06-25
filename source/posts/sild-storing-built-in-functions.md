---
title: Sild - storing built in functions
layout: post
date: 2016-06-25
tags: rc
---

It is silly to spend all of this evaluation time unnecessarily comparing
strings to each other. For these builtin functions, I should really only have
to do that once, at read time. Instead of storing the information about which
builtins are which in labels, which are expensive to resolve, why can't I just
store the function itself somehow, _in_ the cell? It turns out I can totally do
that, using **function pointers**!

<hr>

This _completely blew my mind_ when I finally figured out how it works... and I
think this is the point when I really grew to like C a LOT. It's not the
easiest language to work with, and has mountains of idiosyncrises, but if you
really grok what's going on in a C program, you really grok it!

We've been dealing a lot with pointers, and pointers are simply memory
addresses. A function is just a wrapper over some generic computation, the
instructions for which are just data like everything else, so it shouldn't be
surprising that you can have a pointer to where that data lives in a program.
What _is_ surprising to me, is that you can invoke a function from a pointer to
that function _in the same exact syntax_ as invoking the function itself! _This
is bonkers!_

An example will be much better, I think.

```c
#include <stdio.h>

void happy_birthday_mom() {
    printf("%s\n", "happy birthday, Mom!");
}

int main() {
    happy_birthday_mom();
    return 0;
}
```

Here I am printing out a happy birthday message to my Mom, because it is
actually her birthday the day I am writing this and she is sure to see this
heartfelt message on my computer screen thousands of miles away.

I can _dereference_ the happy birthday function, just like I could any other variable
that takes up memory space!

```c
#include <stdio.h>

void happy_birthday_mom() {
    printf("happy birthday, Mom!\n");
}

int main() {
    void (*meta_happy_birthday_mom)() = &happy_birthday_mom;
    meta_happy_birthday_mom();
    return 0;
}
```

And this _totally works_! The syntax is really hard to read, but this is what
assigning a variable to a function pointer looks like!

```c
//    pointer to a function          getting function address
void (*meta_happy_birthday_mom)() = &happy_birthday_mom;
//^return type                   ^arg type signature
```

If the function looked like this;

```c
int happy_birthday_mom(int age1, int age2) {
    printf("happy birthday, Mom! You don't look a day over %i%i!!\n", age1, age2);
    return 0;
}
```

then the function pointer declaration would look like this:

```c
int (*meta_happy_birthday_mom)(int, int) = &happy_birthday_mom;
```

I also discovered during this process that the dereferencing operator is
unneccesary in this case, so you can just assign the funciton directly to the
declared function pointer like this:

```c
int (*meta_happy_birthday_mom)(int, int) = happy_birthday_mom;
```

I am not sure why this is, or why dereferencing it gives the same address, but
it does. Indeed, all three of these print the same address (which will of
course be different each time the program is run):

```c
printf("%p\n", meta_happy_birthday_mom); // 0x107401ea0
printf("%p\n", happy_birthday_mom);      // 0x107401ea0
printf("%p\n", &happy_birthday_mom);     // 0x107401ea0
```

I will assume it is conventional _not_ to use the dereference operator, since
it is, strictly speaking, unneccessary.

<hr>

What does this mean for Sild? Well, since I know for sure that these built in
functions are going to exist in the language, I can simply store a _pointer_ to
those functions _inside the cell itself!_ That way, I can call every
builtin the same way, and I never have to check against a whole bunch of
strings each time I see a builtin! KILLIN!

This will entail adding a new type to the `CellType` enum:

```c
enum CellType { NIL, LABEL, LIST, BUILTIN };
```

As soon as I do this, I get a bunch of compilation warnings telling me
_exactly_ where I need to handle this new case in all of the switch statements
in the program. Yay switch statements! I'll address all of them in a moment,
but it's nice to have them listed and have full confidence I won't miss any!

I'll add a new possible `val` type in the `val` member's union `(V)`:

```c
typedef union V {
    char * label;
    struct C * list;
    struct C *(*func)(struct C*);
} V;
```

Remember, the signature goes something like

```c
return type (*name)(argument_types)
```

All of the builtin functions have had the same signature so far, they accept a
pointer and return a pointer. They all have to share that or this technique
won't work.

Next, I can move all of the string checking against these builtins back up into
the `read` function. Here is what it looks like right now:

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
            // this is where the determination must be made as to whether a
            // given string is a builtin or not.
            return makecell(LABEL, (V){read_substring(s)}, read(s));
        }
    }
}
```

To do this, I'll first pull that `LABEL` makecell into a helper function, and
call it `categorize`:

```c
C* categorize(char **s) {
    return makecell(LABEL, (V){read_substring(s)}, read(s));
}
```

Next I'll read the substring in once for the function and add comparison `scmp`
tests to see if the string is in fact a `BUILTIN` or just a regular, generic
`LABEL`. I can pretty much lift this if/else branching straight from the apply
function I had been writing before!

```c
C* categorize(char **s) {
    char *token = read_substring(s);
    if (scmp(token, "quote")) {
        return makecell(BUILTIN, (V){ .func = quote }, read(s));
    } else if (scmp(token, "car")) {
        return makecell(BUILTIN, (V){ .func = car }, read(s));
    } else if (scmp(token, "cdr")) {
        return makecell(BUILTIN, (V){ .func = cdr }, read(s));
    } else if (scmp(token, "cons")) {
        return makecell(BUILTIN, (V){ .func = cons }, read(s));
    } else {
        return makecell(LABEL, (V){ token }, read(s));
    }
}
```

This is pretty dense and ugly, but it means I only have to check for these
strings ONCE instead of _every single time_ I eval the builtin functions.
Unfortunately, there is no easy way to map a string to its counterpart function
without some sort of key/value expression, and this is the simplest way to do
that. If this were a more introspective language, you could perhaps do
something like `&asfunc(char *name)` or something... but this is C, so SOL. If
you go check out the commits where this is happening, you'll notice some pretty
haphazard forward declarations of these builtin functions so that the `reader`
knows they exist. This is decidedly suboptimal, and I'll be cleaning up things
like that aggressively when I refactor this into a proper program structure
with headers and all that jazz. Up till about now though, it's just been
simpler to keep everything in a single big file- and it's not even really that
big! Only 344 lines at this point!

Anyway, this totally breaks right now. Of course it does! I haven't told any of
the rest of the program how to deal with this strange new type, the `BUILTIN`!

```c
sild.c:51:13: warning: enumeration value 'BUILTIN' not handled in switch [-Wswitch]
    switch (c->type) {
            ^
sild.c:68:13: warning: enumeration value 'BUILTIN' not handled in switch [-Wswitch]
    switch (c->type) {
            ^
sild.c:97:13: warning: enumeration value 'BUILTIN' not handled in switch [-Wswitch]
    switch (l->type) {
            ^
sild.c:122:13: warning: enumeration value 'BUILTIN' not handled in switch [-Wswitch]
    switch (l->type) {
            ^
sild.c:294:13: warning: enumeration value 'BUILTIN' not handled in switch [-Wswitch]
    switch (c->type) {
            ^
sild.c:316:1: warning: control may reach end of non-void function [-Wreturn-type]
}
^
sild.c:319:13: warning: enumeration value 'BUILTIN' not handled in switch [-Wswitch]
    switch (c->type) {
            ^
sild.c:333:1: warning: control may reach end of non-void function [-Wreturn-type]
}
^
8 warnings generated.
```

These are basically all the same warning. Everywhere I have a switch that
operates on a `CellType` enum, I have to account for the new `BUILTIN` type.
So, one by one.

`free_cell` and `free_one_cell` just need to be told how to free a `val.func`
member:

```c
.
.
.
case BUILTIN:
    free(c->val.func);
    free_cell(c->next);
    free(c);
    break;
.
.
.
```

`debug_list` and `print` both want to know how to display the new value. For now, I'll display the address of the function for both. This isn't ideal, but I'll come back to it in a second.

For `debug_list`:

```c
.
.
.
case BUILTIN:
    printf("BUILTIN- Address: %p, func: %p Next: %p\n", l, l->val.func, l->next);
    debug_list_inner(l->next, depth);
    break;
.
.
.
```

and for `print`:

```c
.
.
.
case BUILTIN:
    printf("%p", l->val.func);

    if (l->next->type != NIL)
        printf(" ");

    print_inner(l->next, depth);
    break;
.
.
.
```

After handling all these, I'm left with the big ones, `eval` and `apply`:

```c
sild.c:316:13: warning: enumeration value 'BUILTIN' not handled in switch [-Wswitch]
    switch (c->type) {
            ^
sild.c:338:1: warning: control may reach end of non-void function [-Wreturn-type]
}
^
sild.c:341:13: warning: enumeration value 'BUILTIN' not handled in switch [-Wswitch]
    switch (c->type) {
            ^
sild.c:355:1: warning: control may reach end of non-void function [-Wreturn-type]
}
^
4 warnings generated.
```

Apply looks like this, currently:

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL: {
            C *outcell;
            if (scmp(c->val.label, "quote")) {
                outcell = quote(c->next);
            } else if (scmp(c->val.label, "car")) {
                outcell = car(c->next);
            } else if (scmp(c->val.label, "cdr")) {
                outcell = cdr(c->next);
            } else if (scmp(c->val.label, "cons")) {
                outcell = cons(c->next);
            } else {
                exit(1);
            }
            free(c);
            return outcell;
        }
        case LIST:
            return apply(eval(c));
        case NIL:
            exit(1);
    }
}
```

All of those `scmp`s are unnecessary! I've already done that work in `read`!
Instead, I can _call the cell's function pointer on its `next` member_. This
is awesome! So sleek!

```c
C *apply(C* c) {
    switch (c->type) {
        case BUILTIN:
            return c->val.func(c->next);
        case LIST:
            return apply(eval(c));
        case LABEL:
            // falling through
        case NIL:
            exit(1);
    }
}
```

Notice that `LABEL` will now fall through to the `NIL` case and exit, because
we're no longer implementing these builtin functions using `LABELS`. I will
change this in a later post, but for now it is alright that it would exit here.

And finally, in `eval`, I want the `BUILTIN` to act the same as a regular label:

```c
C *eval(C* c) {
    switch (c->type) {
        case BUILTIN:
        case LABEL:
            c->next = eval(c->next);
            return c;
        case LIST:
        {
            C *out = apply(c->val.list);
            out->next = eval(c->next);
            free(c);
            return out;
        }
        case NIL:
            return c;
    }
}
```

And that's it!

<hr>

Well, almost. I still have account for the weird way I'm outputting the
`BUILTIN` cells in debug and print.

This is a little bit of a problem, actually, because once the program is
running we don't really know which pointers are which functions!

Consider this:

```
(quote (cons (quote theng) (quote (thing thang))))
```

prints out something like:

```c
(0x104174be0 (0x104174920 theng) (0x104174920 (thing thang)))
```

You may be able to tell, with these side by side, that `cons` is at
`0x104174be0` and `quote` is at `0x104174920`. But these are ephemeral
locations- they will change each time the program is run. How can I know which
`BUILTIN` cell is which?

I can fix this by making the thing storing the function pointer into a struct
that holds both a function pointer and a string representation of which
function it is.

So instead of:

```c
typedef union V {
    char * label;
    struct C * list;
    struct C *(*func)(struct C*);
} V;

typedef struct C {
    enum CellType type;
    union V val;
    struct C * next;
} C;
```

I'll have something like:

```c
struct funcval {
    char *func_name;
    struct C *(*func)(struct C*);
};

typedef union V {
    char * label;
    struct C * list;
    struct funcval func;
} V;

typedef struct C {
    enum CellType type;
    union V val;
    struct C * next;
} C;
```

I have to go through the program and adjust every call to the `val.func` member
depending on whether I'm trying to get at the `name` or the `addr`. This is a
little hairy, but it's not difficult and I won't show the details. Suffice to
say following the compiler errors is enough to make this all work. I end up with things that look like 

```c
case BUILTIN:
    free(c->val.func.addr);
    free(c->val.func.name);
    free(c);
    break;
```

But now I can print out builtins with their proper names:

```c
(quote (cons (quote theng) (quote (thing thang))))
```

Yields, as you would expect:

```c
(cons (quote theng) (quote (thing thang)))
```

The fact that these functions are builtin is opaque to the user's perspective-
it is an implementation detail.
