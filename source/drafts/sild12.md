---
title: Sild12 builtin functions 3, truth false
layout: post
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

Atom expects a single argument, so I'll add that arity check:

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
the empty list itself in used to represent falsity. I can see the elegancein
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
arguments on both sides of the fence.

Anyway, in my lisp, there will be _only one_ thing that is false, which is
nothingness in the form of the `NIL` cell contained in a list by itself, and
_everything else_ is truthy. This also has the benefit of corresponding to a
simplistic but intuitive understanding of actual reality, since everything is
something but _only_ nothing is nothing.

So for the falsy value, I'll make a new, empty list.

```c
return makecell(LIST, (V){.list = &nil}, &nil);
```

and for the truthy value, since literally anything else is truthy, I'll return
a `LABEL` cell with the string value of `"#t"`, which is the traditional way
`T` is returned in Scheme.

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

<hr>

With this basic idea of truthiness and falsiness in place, `eq` is easy enough
to implement. `eq` takes two args and returns true if they are the same atom,
and false otherwise.

```c
C *eq(C *operand) {
    arity_check("eq", 2, operand);
    operand = eval(operand);
    operand2 = operand->next;

    if (
            (
             operand->type == BUILTIN && operand2->type == BUILTIN
             &&
             (operand->val.funcval.addr == operand2->val.funcval.addr)
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
        return makecell(LABEL, (V){ "#t" }, &nil);
    } else {
        return makecell(LIST, (V){.list = &nil}, &nil);
    }
}
```

This is _pretty ugly_, but it works for now. I might like to refactor it later
on, but it covers all of my cases right now.

Separating these boolean expressions onto so many different lines makes the
code look more verbose, but it aids readability quite a bit- the groupings are
more readily obvious, and adding a case will show up more clearly in a diff.

With the addition of an idea of boolean values to the language, we're ready to
implement the foundation conditional statement that allows control flows to
actually work! That's `cond`, and it is the final of the 7 built in primitive
functions that we need to get working.

<hr>
