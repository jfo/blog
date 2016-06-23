---
title: Sild - implementing some built in functions
layout: post
date: 2016-06-23
tags: rc
---

This post is part of a series of posts that began [here](/sild-is-a-lisp-dialect/).

Now that the eval apply loop actually _works_, I need to write some basic
functions that operate on lists in the same way my example functions
(`/dev/null` and `concat`) did. Those were just examples, I'm not going to keep
them around.

I'm going to implement the 7 most basic operations in lisp, as per Paul
Graham's essay ["The Roots of
Lisp"](http://www.paulgraham.com/rootsoflisp.html). I recommend reading that,
it is very thorough in describing these functions.

One function can operate on anyting at all:

1. **quote**: the identity function, expects one cell of any type and returns
   whatever is passed to it unchanged.

Three functions operate on lists:

2. **car**: expects a list, returns the first element of the list.
3. **cdr**: expects a list, returns the list without the first element.
4. **cons**: expects a cell of any type and a list. Returns the list with the
   cell at its beginning.

Three functions depend on a notion of true/false in the language (which we
haven't really addressed yet):

5. **eq**: expects two cells; returns true if they have the same value or are
   both the empty list.
6. **atom**: expects one cell, returns true if a cell is an atom or the empty list.
7. **cond**: expects a series of lists of two elements. It evaluates the first
   of each pair and returns the second of the first one that returns true.

One depends on setting up an environment inside the evaluating framework:

8. **define**: Expects a label and any other single thing, and stores that
   thing in the evaluating environment under that label. Subsequent appearances
   of that label, when evall'ed, will be resolved to a copy of that master
   value.

And the last is the most powerful of all- which depends on all the other
functions and makes application of arbitrary, composed functions possible, and
which I'll describe in much greater detail later on.

9. **lambda** the ultimate :)

Let's make some of them! Specifically, the first four!

<hr>

The implementation of all these functions will follow the same basic pattern.
All of them will accept a cell and return a cell:

```c
C *feel_the_func(C *c) {
};
```

They'll all perform a simple arity check against the number of inputs _before_
evaluating them:

```c
C *feel_the_func(C *c) {
    // arity check
}
```

Then they'll evaluate the operands (except for quote) and perform a type check
against the resulting inputs if necessary

```c
C *feel_the_func(C *c) {
    // arity check
    // eval operands
    // argument type check
}
```

Then operate on the inputs! This can mean creating and destroying cells, or
simply stitching together the inputs in a new way and returning that.

```c
C *feel_the_func(C *c) {
    // arity check
    // eval operands
    // argument type check
    // operate on inputs
}
```

Then clean up after themselves using `free_cell` and/or `free_one_cell`, if neccessary!

```c
C *feel_the_func(C *c) {
    // arity check
    // eval operands
    // argument type check
    // operate on inputs
    // clean up
}
```

and finally return a pointer to their computed value.

```c
C *feel_the_func(C *c) {
    // arity check
    // eval operands
    // argument type check
    // operate on inputs
    // clean up
    // return value
}
```

I'll start with `quote`, arguably the simplest function there is. It will
accept the first operand to the function:

```c
C *quote(C *operand) {

    // arity check
    if (operand->type == NIL || operand->next->type != NIL) {
        exit(1);
    }

    // operate on inputs
    // don't need to do anything for this

    // clean up
    // nothing here, either!

    // return value
    return operand;
}
```

Thats it! Now I have to register this label as a function in `apply`.

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL: {
            if (!strcmp(c->val.label, "quote")) {
                C *outcell = quote(c->next); // passing in the first operand instead of the operator
                free(c); // free the operator!
                return outcell;
            } else {
                exit(1);
            }
        }
        case LIST:
            return apply(eval(c));
        case NIL:
            exit(1);
    }
}
```

You can see that since I'm passing the first operand into the function call, I
have to free the operator itself before passing back the return value. The
enclosing list cell is freed back up in `eval`:

```c
C *eval(C* c) {
    switch (c->type) {
        case LABEL:
            c->next = eval(c->next);
            return c;
        case LIST:
        {
            C *out = apply(c->val.list);
            out->next = eval(c->next);
            free(c); // here!
            return out;
        }
        case NIL:
            return c;
    }
}
```

So without comments, quote looks like this:

```c
C *quote(C *operand) {
    if (operand->type == NIL || operand->next->type != NIL) {
        exit(1);
    }
    return operand;
}
```

Pretty simple! Now evalling:

```c
(quote thingy)                           => thingy
(quote ())                               => ()
(quote (really (anything anywhere)))     => (really (anything anywhere))
```

`quote` is an _immensely_ powerful part of lisp. The why behind that will
become apparent shortly!

<hr>

How about another!

```c
C *car(C *operand) {
    // arity check, must accept one thing only
    if (operand->type == NIL || operand->next->type != NIL) {
        exit(1);
    }

    // eval the operand
    operand = eval(operand);

    // operand type check: can only operate on lists
    if (operand->type != LIST) {
        exit(1);
    }

    // clean up the cells we don't need, recursively, everything that is not
    // the first element in the list.
    free_cell(operand->val.list->next);

    // disconnect the first cell in the list from the rest of the list
    C* outcell = operand->val.list;
    outcell->next = &nil;

    // free the enclosing list
    free(operand);

    // return the newly liberated single cell
    return outcell;
}
```
and register it in apply:

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL: {
            // moving outcell declaration out here
            C *outcell;
            if (!strcmp(c->val.label, "quote")) {
                outcell = quote(c->next);
            } else if (!strcmp(c->val.label, "car")) {
                outcell = car(c->next);
            } else {
                exit(1);
            }
            // c is always freed here
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

Now we can call `car` on a list from within a Sild form and get back the first
element of that list.

```c
(car (this is a list))
```
```c
shell returned 1
```

Hmm. Some better error messaging would be nice here... (I know I know! I'll get
to it!) but what is going on?

Well inside of `car`, the operand is being evaluated, which is what we want.
But when it tries to eval the list, it breaks, because `this` is not a
function (it is currently an unbound label).

This is why `quote` is so important!!

```c
(car (quote (this is a list)))
```

returns

```c
this
```

A lot of lisp tutorials will say that the `quote` function "stops evaluation."
Strictly speaking, this is true in practice, but I think it is misleading to
speak about the function as if it does something different than other forms...
it does not, _really_. `quote` forms are still evaluated, but the _operands_ to them are
_not_. In this way, `quoted` cells _could_ represent truly arbitrary data.

<hr>
How about `cdr`?

```c
C *cdr(C *operand) {
    // arity check
    if (operand->type == NIL || operand->next->type != NIL) {
        exit(1);
    }

    // eval the operand
    operand = eval(operand);

    // operand type check
    if (operand->type != LIST || operand->val.list->type == NIL) {
        exit(1);
    }

    C *garbage = operand->val.list;
    operand->val.list = operand->val.list->next;

    // clean up the car cell we don't need, non-recursively.
    free_one_cell(garbage);

    return operand;
}
```


```c
(car (car (cdr (cdr (car (cdr (cdr
    (quote
        (((boop) doop (doop doop (woot!))) waaaat)))))))))
```
```
woot!
```

<hr>

Ok, now for `cons`. Notice that in this case, none of the argument cells has to
be cleaned up, because the function is meant to return the same information,
but organized differently. It's to turn `a, (b c d)` into `(a b c d)`:

```c
C *cons(C *operand) {
    // arity check
    if (operand->type == NIL ||
        operand->next->type == NIL ||
        operand->next->next->type != NIL) {
        exit(1);
    }
    // eval the operand
    operand = eval(operand);

    // operand type check
    if (operand->type == LIST || operand->next->type != LIST) {
        exit(1);
    }

    // shuffling them around and returning the new list
    C *operand2 = operand->next;
    operand->next = operand2->val.list;
    operand2->val.list = operand;
    return operand2;
}
```

<hr>

These are some pretty rudimentary operations in lisp! This is a good place to
stop and do some refactoring.

Here's what `apply` looks like now:

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL: {
            C *outcell;
            if (!strcmp(c->val.label, "quote")) {
                outcell = quote(c->next);
            } else if (!strcmp(c->val.label, "car")) {
                outcell = car(c->next);
            } else if (!strcmp(c->val.label, "cdr")) {
                outcell = cdr(c->next);
            } else if (!strcmp(c->val.label, "cons")) {
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

`strcmp` is a real bottleneck, and hugely overkill for what it's doing here.
The function iterates through the entirety of at least one of the strings and
returns `0` if they are equal, `-1` if string one is "less" than string 2, and
`1` if string 2 is "less" than string 1. I don't have to go through the whole
string if at any point they differ, because I only care about whether or not
the are the same string completely. I can write a simple function that does
this a lot more efficiently for my use case.

```c
// checks if two strings are equal, aborts at first sign they are not.
int scmp(char *str1, char *str2) {
    int i;
    for (i = 0; str1[i] != '\0'; i++) {
        // if ANY of the chars are different, or if the end of the second
        // string is reached before the first, abort and return false
        if (str1[i] != str2[i] || str2[i] == '\0') {
            return 0;
        }
    }
    // if the end of the first string is reached and it is also the end of the
    // second, they are the same! return true.
    if (str2[i] == '\0') {
        return 1;
    } else {
        // if there is more of the second string, return false.
        return 0;
    }
}
```

And I can use this function in apply:

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

This allows me to dispense with the odd `!` boolean flip in the comparison, as
well. Faster and more readable ftw!

_But wait, there's more!!_

I can do away with _all_ of the string comparisons for built in functions in
the application step! Next post I'll explain it!
