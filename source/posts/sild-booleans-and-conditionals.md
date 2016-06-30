---
title: Sild - booleans and conditionals
layout: post
date: 2016-06-29
tags: rc
---

The first function I implemented was the identity function `quote`, and relies on
nothing else. Anything passed in is returned unchanged.

The next three functions were `LIST` operations, `car`, `cdr`, and`cons`, and
those rely on the `LIST` structures that have been central to this whole
project.

The next two functions I'll implement are `atom` and `eq`. These functions
return boolean values based on some criteria evaluated against the thing that
is passed into them; a sense of true/false doesn't really exist yet in Sild, so
that's going to be something I have to think about. Let's looks at `atom` first.

`(atom something)` returns `true` if the 'something' passed in is an atom _or_
the empty list. But what is an atom? Well, _everything_ is an atom, _except_
for a list _with something in it_. So right now that looks something like this:

```c
(atom)                                                    // arity error
(atom (quote LABEL))                                      // true
(atom (quote ()))                                         // true
(atom (quote (whatever list of however (many (depths))))) // false af
```

I'll start by making a function body that returns what it is given and and
registering `atom` in the reader.

```c
C *atom(C *operand) {
    return operand;
}
```

and

```c
C* categorize(char **s) {
    char *token = read_substring(s);
    if (scmp(token, "quote")) {
        return makecell(BUILTIN, (V){ .func = {token, quote} }, read(s));
    } else if (scmp(token, "car")) {
        return makecell(BUILTIN, (V){ .func = {token, car} }, read(s));
    } else if (scmp(token, "cdr")) {
        return makecell(BUILTIN, (V){ .func = {token, cdr} }, read(s));
    } else if (scmp(token, "cons")) {
        return makecell(BUILTIN, (V){ .func = {token, cons} }, read(s));
    } else if (scmp(token, "atom")) {
        return makecell(BUILTIN, (V){ .func = {token, atom} }, read(s));
    } else {
        return makecell(LABEL, (V){ token }, read(s));
    }
}
```

`atom` expects a single argument, so I'll add that arity check:

```c
C *atom(C *operand) {
    arity_check("atom", 1, operand);
    return operand;
}
```

And then I'll evaluate the operand:

```c
C *atom(C *operand) {
    arity_check("atom", 1, operand);
    operand = eval(operand);
    return operand;
}
```

And now, the test for truthiness. Remember, the _only_ thing that is _not_ an
atom is a non-empty `LIST`. I can check for that case with this expression:

```c
(operand->type == LIST && operand->val.list->type != NIL)
```

In context, that would look like this:

```c
C *atom(C *operand) {
    arity_check("atom", 1, operand);
    operand = eval(operand);

    if (operand->type == LIST && operand->val.list->type != NIL) {
        return false;
    } else {
        return true;
    }
}
```

So anything passed into `atom` will return true except for a non empty list.

But this doesn't work! Sild doesn't have a sense of truthiness or falsehood _at
all_ yet. These booleans being returned are C, not Sild, and in actuality this won't
even compile, since `true` and `false` live in `<stdbool.h>`, which I'm not
including.

Traditionally in Lisp, the atom "T" is used to denote generic truthiness, and
the empty list itself in used to represent falsity. I can see the elegance in
this- though I haven't yet formally decided how to represent either of these
things, it is arguable that the `NIL` cell that terminates every list is
adequate to represent falsehood. Since the `NIL` cell is foundationally
terminal and can't hold a next cell, it also makes sense that to hold falsehood
I have to have a container for it, which I also already have in the form of a
`LIST`.

I spent a long time thinking about the best way to do this, and it is far
from an open and shut case, and I'm not at all convinced the way I chose to do
it is the best way, but it is a good place to start and is conceptually
pleasing. People get _really_ hot about it, see
[this](https://github.com/hylang/hy/issues/373) and note that there are solid
arguments on both sides of the fence. Should "empty" values of any type
represent falsity, like `0` or `""`? Should there be special singleton values
to represent true and false?

Anyway, in my lisp, there will be _only one_ thing that is false, which is
nothingness in the form of the `NIL` cell contained in a list by itself, and
_everything else_ will be truthy. This also has the benefit of corresponding to a
simplistic but intuitive understanding of actual reality, since everything is
something but _only_ nothing is nothing.

So for the falsey value, I'll make a new, empty list.

```c
return makecell(LIST, (V){.list = &nil}, &nil);
```

and for the truthy value, since literally anything else is truthy, I'll return
a `LABEL` cell with the string value of `"#t"`, which is the traditional way
`T` is returned in Scheme, and I've gotten used to it. Really, this value is
arbitrary, it could be anything and still work.

```c
return makecell(LABEL, (V){ "#t" }, &nil);
```

It is important for me to note here that I _will_ have to change this later on.
It's fine for now as a generic truthy value, but when I start evaluating
`LABEL`s then this will have to become a special case. Just keep that in mind!

The final function looks like this:

```c
C *atom(C *operand) {
    arity_check("atom", 1, operand);
    operand = eval(operand);

    if (operand->type == LIST && operand->val.list->type != NIL) {
        return makecell(LIST, (V){.list = &nil}, &nil);
    } else {
        return makecell(LABEL, (V){ "#t" }, &nil);
    }
}
```
Whoops, I lied a little... forgot to clean up after myself!

```c
C *atom(C *operand) {
    arity_check("atom", 1, operand);
    operand = eval(operand);

    C *out;
    if (operand->type == LIST && operand->val.list->type != NIL) {
        out = makecell(LIST, (V){.list = &nil}, &nil);
    } else {
        out =  makecell(LABEL, (V){ "#t" }, &nil);
    }
    free_cell(operand);
    return out;
}
```

<hr>

With this basic idea of truthiness and falsiness in place, `eq` is easy enough
to implement. `eq` takes two args and returns true if they are the same atom,
and false otherwise.

```c
C *eq(C *operand) {
    arity_check("eq", 2, operand);
    operand = eval(operand);
    operand2 = operand->next;

    C *out;
    if (
            (
             operand->type == BUILTIN && operand2->type == BUILTIN
             &&
             (operand->val.func.addr == operand2->val.func.addr)
            )
            ||
            (
             operand->type == LABEL && operand2->type == LABEL
             &&
             scmp(operand->val.label, operand2->val.label)
            )
            ||
            (
             operand->type == LIST && operand2->type == LIST
             &&
             (operand->val.list == &nil && operand2->val.list == &nil)
            )
       )
    {
        out = makecell(LABEL, (V){ "#t" }, &nil);
    } else {
        out = makecell(LIST, (V){.list = &nil}, &nil);
    }
    free_cell(operand);
    return out;
}
```

This is _pretty ugly_, but it works for now. I might like to refactor it later
on, maybe to use a switch statement, but it covers all of my cases.

Separating these boolean expressions onto so many different lines makes the
code look more verbose, but it aids readability quite a bit- the groupings are
more readily obvious, and adding a case will show up more clearly in a diff.

With the addition of an idea of boolean values to the language, we're ready to
implement the foundational conditional statement that allows control flows to
actually work! That's `cond`, and it is the final of the 7 built in primitive
functions that I need to get working.

<hr>

`cond`, like `quote`, is special. It doesn't evaluate everything
passed in to it before returning, but only when it needs to evaluate it. It's
going to take _at least_ one argument, but should be able to accept a variable
number of arguments that will implicitly be in pairs. It will evaluate the
first argument, and if it sees a truthy value, (anything but `()`), it will
free any remaining arguments and evaluate and return the second argument. If it
sees a falsey value, it will free the first and second arguments, _without
evaluating the second argument_, and call itself again on the next pair,
numbers 3 and 4. Finally, if it is passed a single argument, it will evaluate
and return that argument.

I'll start by once more declaring a pass through function and registering it
inside of `categorize`.

```
C *cond(C *operand) {
    return operand;
}
```

and

```c
.
.
} else if (scmp(token, "cond")) {
        return makecell(BUILTIN, (V){ .func = {token, cond} }, read(s));
.
.
```

Ok. This function doesn't really have an arity check in the same way the others
do, but I can put one in manually.

```c
C *cond(C *operand) {
    if (operand->type == NIL) {
        fprintf(stderr, "\nArityError: cond expected at least 1 argument, got none.");
        exit(1);
    }
    return operand;
}
```

Next, for the case of if I have only a single argument, `cond` will just eval
and return it.

```c
C *cond(C *operand) {
    if (operand->type == NIL) {
        fprintf(stderr, "\nArityError: cond expected at least 1 argument, got none.");
        exit(1);
    } else if (operand->next->type == NIL) {
        return eval(operand);
    }
    return operand;
}
```

In that case, it doesn't have to clean anything up since the eval call will do
that for it.

And now, if there are two arguments, it evaluates the first to see if it is
falsey. If it is NOT falsey, it frees any other operands and evaluates the
second, returning its result. To do this, it deconstructs the arguments and
isolates them from each other. This looks like a lot is going on, but it's
fairly straightforward.

Heavily annotated:

```c
C *cond(C *operand) {
    if (operand->type == NIL) {
        fprintf(stderr, "\nArityError: cond expected at least 1 argument, got none.");
        exit(1);
    } else if (operand->next->type == NIL) {
        return eval(operand);
    }
    // assigning 3 operands to their own vars.
    C *op1 = operand;
    C *op2 = operand->next;
    C *op3 = operand->next->next;

    // isolating the first two arguments
    op1->next = &nil;
    op2->next = &nil;
    op1 = eval(op1);
    if !(op1->type == LIST && op1->val.list->type == NIL) {
        // free the boolean expression statement
        free_cell(op1);
        // free anything else that was passed in
        free_cell(op3);
        // return the evalled second arg.
        return eval(op2);
    } else {
        // won't need these anymore!
        free_cell(op1);
        free_cell(op2);

        if (op3->type != NIL) {
            return cond(op3);
        } else {
            // if the op3 type is NIL, you've reached the end of the cond form
            // without encountering any true predicates, and should return the
            // empty list.
            out = makecell(LIST, (V){.list = &nil}, &nil);
        }
    }
}
```

Yay! YAY!!

A historical note: I read somewhere that traditionally, `cond` is a macro that
resolves to nested `if` statements. That means that something like:

```
(cond a 1
      b 2
      c 3
      4)
```

Would end up being represented like:

```
(if a 1 (if b 2 (if c 3 4)))
```

I think it might be somehow "purer" to implement it that way, but, meh. `cond`
can be used here as a simple if statement- when passed three arguments it
functions exactly the same way as `if` would:

```
(cond condition if-statement else-statement)
```

So I'm happy with that.

<hr>

```c
C *apply(C* c) {
    switch (c->type) {
        case BUILTIN:
            return c->val.func.addr(c->next);
        case LIST:
            return apply(eval(c));
        case LABEL:
            exit(1);
        case NIL:
            return makecell(LIST, (V){.list = &nil}, &nil);
    }
}
```

There are a couple of things I'd like to refactor before moving on.

First, attempting to apply either a `LABEL` or `NIL` should result in an error.
I'll add those cases in `apply`:

```c
C *apply(C* c) {
    switch (c->type) {
        case BUILTIN:
            return c->val.func.addr(c->next);
        case LIST:
            return apply(eval(c));
        case LABEL:
            fprintf(stderr, "\nError: attempted to apply non-procedure %s\n", c->val.label);
            exit(1);
        case NIL:
            fprintf(stderr, "\nError: attempted to evaluate an empty list: ()\n");
            exit(1);
    }
}
```

this is the first time I'm really tightening up evaluation rules- I've
implemented some of the builtin functions I want to be part of the language,
currently they are the only functions available to be applied. This will
change, but for now, that's it!

Furthermore, back when I was evaluating entire ASTs to change everything to
`chicken`, it made sense to eval recursively. This is no longer ideal- I should
be able to evaluate only the cells I need to evaluate without worrying about
what they are connected to. this is pretty simple- I just remove the `c->next =
eval(c->next)` lines inside `eval`, going from this:

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

to this:

```c
C *eval(C* c) {
    switch (c->type) {
        case BUILTIN:
        case LABEL:
            c->next = c->next;
            return c;
        case LIST:
        {
            C *out = apply(c->val.list);
            out->next = c->next;
            free(c);
            return out;
        }
        case NIL:
            return c;
    }
}
```

This necessitates only minor tweaks to the builtins that accept more than one
argument (excluding cond, which already deals with its own evaluation rules),
`eq` and `cons` now need to manually evaluate their second arguments. Easy peasy!


<hr>

Also, this

```c
return makecell(LIST, (V){.list = &nil}, &nil);
```

business is turning into a bit of a pattern. We know that it means return
false, or the empty list, basically, but it's a little bit verbose and unclear.
I'll make a couple of little helper functions to replace these calls!

```c
C *empty_list() {
    return makecell(LIST, (V){.list = &nil}, &nil);
}

C *truth() {
    return makecell(LABEL, (V){ "#t" }, &nil);
}
```

Now, in `atom`, `eq`, and now in `apply`, I can have a little more clarity into
what I'm seeing being returned!

This introduces one small bug I missed earlier- if the program attempts to free
a `truth` cell, it will choke on the string `"#t"` in its `val.label` member,
because it was passed in as a string literal and not as a malloc'd address. An
ugly but simple tweak to the `truth()` function can fix this:

```c
C *truth() {
    char *tru = malloc(sizeof(char) * 3);
    tru[0] = '#'; tru[1] = 't'; tru[2] = '\0';
    return makecell(LABEL, (V){ tru }, &nil);
}
```

Now, when that pointer is freed in `free_cell`, it will free the malloc'd address correctly!
