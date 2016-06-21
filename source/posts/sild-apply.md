---
title: Sild - apply
layout: post
date: 2016-06-21
tags: rc
---

Now I have a basic form of `eval`! In order to actually get
anything done, though, I'll also need `apply`.

`apply` is an operation that _applies_ a function to a given list of arguments.
In a lisp, the first cell in a list represents a function, and the remainder
of the cells in the list are the arguments that are being passed to it. So, for
example:

```
(+ 1 2)
```

Is a symbolic expression (S-expression) that resolves to `3`, since applying
the addition function `"+"` to the list of arguments `(1 2)` adds those two
numbers together.

If we read in that string as it is, and `debug_list` it, we get:

```c
LIST- Address: 0x7f9280c03ac0, List_Value: 0x7f9280c03aa0 Next: 0x103792030
|   LABEL- Address: 0x7f9280c03aa0, Value: + Next: 0x7f9280c03a80
|   LABEL- Address: 0x7f9280c03a80, Value: 1 Next: 0x7f9280c03a60
|   LABEL- Address: 0x7f9280c03a60, Value: 2 Next: 0x103792030
|   NIL- Address: 0x103792030
-------------------------------------------------------
NIL- Address: 0x103792030
-------------------------------------------------------
```

This is the _Sild_ data that represents the string that has been read in that
looks like the C string `"(+ 1 2)"`

This is the first time I've mentioned the name of this language when describing
how I'm writing it, and there is a good reason for that. Now that I'm getting
close to implementing a working eval/apply loop, It's important to be able to
draw a mental distinction between the program space of the running C program,
which is a Sild interpreter, and the program space of the running Sild program,
which is being interpreted by that interpreter. It's a bit of a head trip, but
consider that the cells that I've been operating on, and the lists that they
make up, are, from the Sild program's perspective, similar to the memory space
that is available to the C program. The implementation details of how the data
is stored and how it is operated on  are opaque to the Sild program and handled
by the interpreter.

Take a look at the debugged list above. It is some data stored in a linked
list. I'm working on an eval/apply loop to teach the interpreter how to
actually interpret that data _as code_. This is what people mean when they run
around banging a cow bow yelling "code is data! data is code! it's all the
same! Lisp wow! :D ". It's because, in the context of the lisp program, it is
extremely literally true that _code and data are the same thing_. They are
contained in the same data structure, the same cell structs, the same lists. The only
difference is that the 'code' is being evaluated, whereas the 'data' is _not_
being evaluated. So you could just say that "code" is data that has been or is being
evaluated, or that "data" is code that hasn't been evaluated, they're one and
the same thing! It's really the _implications_ of this that get people so
excited, and I'll come back to those in more detail later on.

What is `apply` then, in the context of the C program I'm writing? It will,
like `eval`, accept a cell, and return a cell, and need to include a switch
statement to know how to treat different cells. For now, in all three cases,
I'll simply `eval` the input and pass it back out again.

```c
C *eval(C*);

C *apply(C* c) {
    switch (c->type) {
        case LABEL:
        case LIST:
        case NIL:
            return eval(c);
    }
}
```

Note that I've had to forward declare `eval()` above `apply()` because the two
are circularly dependant upon one another.

`apply()` will be called from `eval()` whenever it runs into a `LIST`

```c
C *eval(C* c) {
    switch (c->type) {
        case LABEL:
            c->next = eval(c->next);
            return c;
        case LIST:
            c->val.list = apply(c->val.list);
            c->next = eval(c->next);
            return c;
        case NIL:
            return c;
    }
}
```

This code is functionally equivalent to what I had before, when the `LIST` case
in eval `eval`'d the `val.list` member inline.

Anything passed into the eval/apply loop will come out the other side exactly
the same, but inside the body of apply, we have the opportunity to dispatch the
list that we're evaluating into any function we want depending on the `LABEL`
that the first cell has.

Let's pretend that we want a function in Sild land that takes any number of
arguments and returns `NIL`. We'll call it `/dev/null`, since the language right
now doesn't care about forward slashes and just sees them as a regular
character. All we have to do to achieve this is to check the value of the label
at the head of the list when it is passed into `apply()`, and return `&nil` if
and only if the `val.label` equals `"/dev/null"`.

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
            if (!strcmp(c->val.label, "/dev/null")) {
                return &nil;
            }
        case LIST:
        case NIL:
            return eval(c);
    }
}
```

I'll have to `#include <string.h>` at the top of the file to use `strcmp()`.

> `strcmp()` is kind of a strange looking function, but if the two strings are
> the same it returns `0`, which is falsy in C. If we want to know if the
> strings were the same we can take the negation of the call to `strcmp` and
> we'll get a `true` boolean if the two strings are equal.

So, an expression like this:

```c
(/dev/null anything can go here it does not matter)
```

Evaluates to the empty list, which I haven't yet mentioned explicitly but will
come into play a lot later, and is a `LIST` typed cell whose `val.list` member
points to `NIL`!

```c
LIST- Address: 0x7f9211403540, List_Value: 0x100d86038 Next: 0x100d86038
|   NIL- Address: 0x100d86038
-------------------------------------------------------
```

It doesn't matter how deeply nested the `/dev/null` list is, and it doesn't matter how many cells are underneath it!

```c
"(this is outside (/dev/null and (anything (can go here) (it (doesn't matter)))))"
```
Evals to:

```c
"(this is outside ())"
```

So far, all the data in the running program has been persistent implicitly. But
now, we have a situation where the cells that were inside the list that was
evaluated to `NIL` are no longer referenced by anything. Recall that when these
cells were generated with `makecell()`, they were given memory via `malloc`. It
is the programmer's (my) responsibility to `free` that memory when it is no
longer in use. This is as simple as calling `free()` on the pointer that was
originally malloc'd. I'll add this inside the `"/dev/null"` conditional block:

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
            if (!strcmp(c->val.label, "/dev/null")) {
                free(c);
                return &nil;
            }
        case LIST:
        case NIL:
            return eval(c);
    }
}
```
BUT! This action ONLY frees the _head_ of this list- only a single cell.
Everything that operates on cells has to operate recursively, just like the
debug and print list functions! This pattern is likely starting to look familiar:

```c
void free_cell(C *c) {
    switch (c->type) {
        case LABEL:
            free(c->val.label);
            free_cell(c->next);
            free(c);
            break;
        case LIST:
            free_cell(c->val.list);
            free_cell(c->next);
            free(c);
            break;
        case NIL:
            break;
    }
}
```

Each case frees any subnodes in the linked list from the given cell that's been
passed in, as well as any cells that are further along in the list.

I'll now free the cell at the head of the list before returning `&nil` in the
apply function:

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
            if (!strcmp(c->val.label, "/dev/null")) {
                    free_cell(c);
                    return &nil;
            }
        case LIST:
        case NIL:
            return eval(c);
    }
}
```

The execution will appear to be the same, but under the hood, the memory that
was holding those cells will now be available for reuse.

This is the first actual Sild function! It's not super useful, is it? I'll add another!

<hr>

I'm not going to keep this function around (or the one that returns only `NIL`,
either), but let's say we have a C function that takes two strings and returns
a new string that is a concatenation of them. There is probably a library
function that does this, but for the sake of demonstration, let's say it looks
like this:

```c
// wrote this in a hurry and there is probably something wrong with it
char *concat(char *string1, char *string2) {
    int s1len = strlen(string1);
    int s2len = strlen(string2);
    int length = s1len + s2len;
    char *out = malloc(length + 1); // malloc'ing a new string to output

    for (int i = 0; i < s1len; i++) {
        out[i] = string1[i];
    }

    for (int i = 0; i < s2len; i++) {
        out[i + s1len] = string2[i];
    }
    return out;
}

```
So calling it would look like this:

```c
int main() {
    printf("%s", concat("thing1" , "thing2")); // prints "thing1thing2"
    return 0;
}
```

> The `val.label` members of the cell structs are currently only strings
> (`LABELS`), so I needed a function that would operate on strings to demonstrate
> anything at all.

I can add another conditional in the `apply()` function to check for the
`concat` LABEL:

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
            if (!strcmp(c->val.label, "/dev/null")) {
                free_cell(c);
                return &nil;
            } else if (!strcmp(c->val.label, "concat")) {
                C *out = makecell(LABEL, (V){concat(c->next->val.label, c->next->next->val.label)}, &nil);
                free_cell(c);
                return &nil;
            }
        case LIST:
        case NIL:
            return eval(c);
    }
}
```

What if I `eval` this:

```
((concat some things) are (concat bet ter) than (concat no things))
```

I get back:

```
((somethings) are (better) than (nothings))
```

Wowza!

<hr>

There are some problems here, though! First and foremost- did I really want a
`LIST` with one cell in it whose value is the concatenated output? No, I did
not. I wanted a `LABEL` cell whose value was the concatenated output.

Also, this function as written makes a lot of assumptions! consider the line:

```c
C *out = makecell(LABEL, (V){concat(c->next->val.label, c->next->next->val.label)})
```

This only gets triggered if and only if `c` is a `LABEL` with the value `"concat"`,
, but it also totally assumes that:

- there are two cells after it, and
- they are both `LABEL` cells.

If I try to eval any of these forms, for example:

```
(concat)
(concat thing)
(concat (ohh a list))
(concat thing1 (nope a list))
```

The program just blows up!

These:

```
(concat thing1 thing2 thing3)
(concat thing1 thing2 (ohhh a list))
```

work, but really shouldn't. They _should_ be an arity error. "Arity" means
"number of arguments", and I'm passing 3 arguments into a function that is only
designed to handle 2. Note that in C land, I'm only using the first two, but
I shouldn't be allowed to do this from Sild's perspective, either.

Furthermore, considering that I really want `concat` to return a LABEL cell,
not a LIST cell at all, I _should_ also be able to do something like this:

```
(concat (concat hi mom) (concat hi mom))
```

But as written, the `concat` case in `apply` doesn't `eval` its argument list.

<hr>

To fix all of these problems, a good first step is to pull out the `concat`
conditional block into it's own function, so `apply` will look like this:


```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
            if (!strcmp(c->val.label, "/dev/null")) {
                    free_cell(c);
                    return &nil;
            } else if (!strcmp(c->val.label, "concat")) {
                return concat_two_labels(c);
            }
        case LIST:
        case NIL:
            return eval(c);
    }
}
```

And I'll have a new function `concat_two_labels()` that will take the head of
the list and return a new cell.

```c
C *concat_two_labels(C *c) {
    C *out = makecell(LABEL, (V){ concat(c->next->val.label, c->next->next->val.label) }, &nil);
    free_cell(c);
    return out;
}
```

This function has three responsibilities.

1. To verify that the arguments passed in are the right type and there are the
   right number
2. To operate on those input args and return a new cell that represents the output
   of the function
3. To clean up after itself and `free_cell()` any cells that don't need to be
   maintained.

As written it already almost fulfills the last two of those obligations, and the first
task is fairly straightforward... if pretty ugly.

```c
C *concat_two_labels(C *c) {

    if (
        c->next->type != LABEL
        ||
        c->next->next->type != LABEL
        ||
        c->next->next->next->type != NIL
    ) {
        exit(1);
    }

    C *out = makecell(LABEL, (V){concat(c->next->val.label, c->next->next->val.label)}, &nil);
    free_cell(c);
    return out;
}
```

Now all of those arity and type error cases will exit the program! For now,
just exiting with that error code will be fine; later on I'll want to set up
some more informative error messaging.

Ah! And what about

```c
(concat (concat hi mom) (concat hi mom))
```

That's actually pretty easy, I just also have to eval the arguments before operating on them!

```c
C *concat_two_labels(C *c) {
    C *operand = eval(c->next);

    if (
        operand->type != LABEL
        ||
        operand->next->type != LABEL
        ||
        operand->next->next->type != NIL
    ) {
        exit(1);
    }

    C *out = makecell(LABEL, (V){ concat(operand->val.label, operand->next->val.label) }, &nil);

    free_cell(c);
    return out;
}
```

Because `eval` operates on all linked cells to the end of a list, we can be
sure that all of the operands will be evaluated. We can also move the arity
check above the eval call, to prevent unnecessary evalling if there are too
many arguments.

```c
C *concat_two_labels(C *c) {
    if (c->next->next->next->type != NIL) {
        exit(1);
    }

    C *operand = eval(c->next);

    if (operand->type != LABEL || operand->next->type != LABEL) {
        exit(1);
    }

    C *out = makecell(LABEL, (V){ concat(operand->val.label, operand->next->val.label) }, &nil);

    free_cell(c);
    return out;
}
```
Hmm, but now, evalling:

```c
(concat hi (concat hi mom))
```

exits with a code of 1. That's because `concat` is still returning LIST cells! After evaluating its operands, the top level list is seeing:

```c
(concat hi (himom))
```

And choking on the second operand being a `LIST`. This is the desired behavior
for the arity check, so that's good! But we want the result of the call to the
`concat_two_labels()` function to _replace_ the cell that called it, not become the value of that cell.

Let's look back at `eval()` again:

```c
C *eval(C* c) {
    switch (c->type) {
        case LABEL:
            c->next = eval(c->next);
            return c;
        case LIST:
            c->val.list = apply(c->val.list);
            c->next = eval(c->next);
            return c;
        case NIL:
            return c;
    }
}
```

In the LIST case, we can see that we are assigning the output of apply to the
`LIST` cell's `val.list` member. This is where that's happening! In reality, we
don't know what kind of cell we're going to get back, the return value of an
arbitrary function could be any type of cell. We need to create a new cell out
of the return value, stitch it into the list where this function call used to
live, and free the cell that contained the function call. That's going to look
like this (when declaring variables in a switch body, you have to wrap the case
inside curly braces to create a lexical scope that the compiler can
understand):

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
            return out;
        }
        case NIL:
            return c;
    }
}
```

I'll have to tweak `concat_two_labels` a little bit- in recursive calls, if I
expect functions to clean up after themselves, it can result in the program
attempting to `free` the same memory more than one time. I'll need a little
helper function that knows how to free a single cell, only recursively if that
cell is a LIST. That looks like this:

```c
void free_one_cell(C *c) {
    switch (c->type) {
        case LABEL:
            free(c->val.label);
            free(c);
            break;
        case LIST:
            free_cell(c->val.list);
            free(c);
            break;
        case NIL:
            break;
    }
}
```

And I'll change that call in `concat_two_labels`:

```c
C *concat_two_labels(C *c) {
    if (c->next->next->next->type != NIL) {
        exit(1);
    }

    C *operand = eval(c->next);

    if (operand->type != LABEL || operand->next->type != LABEL) {
        exit(1);
    }

    C *out = makecell(LABEL, (V){ concat(operand->val.label, operand->next->val.label) }, &nil);

    free_one_cell(c);
    return out;
}
```

I also need to `free()` the parent pointer of the actual LIST cell that I started with back in eval.

```c
C *eval(C* c) {
    switch (c->type) {
        case LABEL:
            c->next = eval(c->next);
            return c;
        case LIST: {
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

With these tweaks, I can eval something like this:

```c
(concat (concat hi mom) (concat hi mom))
```

And get this back:

```
himomhimom
```
THAT'S REALLY COOL!!!

<hr>

Ok, this is a _really_ long and convoluted post, so if you made it to the end
you deserve something neat, and boy do I have it, cause this is about to
get _really really awesome_.

There is a case we haven't covered, and it lives in `apply()`

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
            if (!strcmp(c->val.label, "/dev/null")) {
                    free_cell(c);
                    return &nil;
            } else if (!strcmp(c->val.label, "concat")) {
                return concat_two_labels(c);
            }
        case LIST:
        case NIL:
            return eval(c);
    }
}
```

In fact, there are three cases we haven't covered fully. If you try to `apply()` a LABEL
that doesn't have a corresponding function case, you fall through to returning
the evaluation of that label, which currently just returns the cell as is.

So this:

```c
(a b c d)
```

returns just a single cell, the LABEL:

```c
a
```
The appropriate thing to do if you're trying to apply a function that doesn't
exist is to throw an error. Let's add that now.

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
            if (!strcmp(c->val.label, "/dev/null")) {
                free_cell(c);
                return &nil;
            } else if (!strcmp(c->val.label, "concat")) {
                return concat_two_labels(c);
            } else {
                exit(1);
            }
        case LIST:
        case NIL:
            ;
    }
}
```

Once again, this is piss poor error messaging, but we'll come back to that
later on. Also notice I've taken out the base case fall through, because I want
to account for all the cases now. The compiler complains about this, but it is
only a warning so #yolo.

Now if I try to eval `(a b c d)`, the program exits, because `a` is not a function.

But what if I try to apply a list? Surely I can do that, right? Yes. Yes I can.
But I need to evaluate it first!

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
            if (!strcmp(c->val.label, "/dev/null")) {
                    free_cell(c);
                    return &nil;
            } else if (!strcmp(c->val.label, "concat")) {
                return concat_two_labels(c);
            } else {
                exit(1);
            }
        case LIST:
            return apply(eval(c));
        case NIL:
            ;
    }
}
```

Ok, this is where things get wild. Because with this code, what happens if I evaluate:


```
((concat con cat) two words)
```

Tracing this would look something like:

`read()` reads in the string and parses it into this structure:

```c
LIST- Address: 0x7fce9bc034e0, List_Value: 0x7fce9bc034c0 Next: 0x108eab048
|   LIST- Address: 0x7fce9bc034c0, List_Value: 0x7fce9bc03430 Next: 0x7fce9bc03490
|   |   LABEL- Address: 0x7fce9bc03430, Value: concat Next: 0x7fce9bc03410
|   |   LABEL- Address: 0x7fce9bc03410, Value: con Next: 0x7fce9bc033f0
|   |   LABEL- Address: 0x7fce9bc033f0, Value: cat Next: 0x108eab048
|   |   NIL- Address: 0x108eab048
|   -------------------------------------------------------
|   LABEL- Address: 0x7fce9bc03490, Value: two Next: 0x7fce9bc03470
|   LABEL- Address: 0x7fce9bc03470, Value: words Next: 0x108eab048
|   NIL- Address: 0x108eab048
-------------------------------------------------------
NIL- Address: 0x108eab048
-------------------------------------------------------
```

We then pass that into `eval`.

`eval` sees a list, and passes that into `apply`.

`apply` sees that the first cell in the list is itself a list, so it evaluates
that list and THEN applies it. So, 

```c
(concat con cat)
```

Turns into `concat`, it replaces the evaluated cell with the result of that
evaluation:

```
(concat two words)
```

Now apply can evaluate the top level list, and print out the result.

```
twowords
```

**THIS IS THE CODE IS DATA THING. THE PROGRAM IS ABLE TO CONSTRUCT ITSELF!**

Alone, `con` and `cat` are two LABEL cells that don't do anything. both

```
(con two words)
```

and

```
(cat two words)
```

Would fail, as `cat` and `con` is not mapped to a function- they are `unbound
LABELS` but concatanating them together yields a LABEL cell that the
interpreter knows how to read!

Ohhhhhhhhhhh noooooooooo waayyyyyyyyy

```c
((concat /dev /null) (concat mic drop))
```

```
```

```
((concat c (concat o (concat n (concat c (concat a t))))) (concat o h) (concat y (concat e (concat a h))))
```

<hr>

Finally, I'll throw an error in apply under the `NIL` case, because `NIL` is
not, and will never be, a function that can be applied to arguments.

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
            if (!strcmp(c->val.label, "/dev/null")) {
                free_cell(c);
                return &nil;
            } else if (!strcmp(c->val.label, "concat")) {
                return concat_two_labels(c);
            } else {
                exit(1);
            }
        case LIST:
            return apply(eval(c));
        case NIL:
            exit(1);
    }
}
```

And that's it! the eval/apply loop is finished!
