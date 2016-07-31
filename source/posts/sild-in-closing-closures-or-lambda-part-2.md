---
title: Sild - In closing, closures (or, lambdas p.2)
layout: post
date: 2016-07-31
tags: rc
---

Consider this:

```scheme
(define conser
    (lambda (x y)
        (cons (x y))))
```

And now,

```scheme
(conser 'a '(b c))
```

Will return

```scheme
'(a b c)
```

Furthermore,

```scheme
(define z '(b c))
```

And now,

```scheme
(conser 'a z)
```

Will evaluate `z` in the global env before passing it to `conser`, returning:

```scheme
'(a b c)
```

But what about this?

```scheme
(define z '(b c))

(define conser
    (lambda (x)
        (cons x z)))

(display (conser 'a))
```

You'll notice, that at the time of `conser`'s invocation, `z` is defined in the
global environment. Unlike the second example above, however, `z` is _not_
being evaluated in that environment. The `z` here is being evaluated within the
frame environment created by `apply_proc` during the evaluation `(conser 'a)`,
an environment that currently has no assignment for `z`.

And so we get:

```
Error: unbound label: z
```

This is obviously not the behavior we would expect! The interpreter _should_ be
examining the frame for `z`, and then when not finding it, trying to look it up
in the enclosing environment, which in this case is the global one!

This actually turns out to be a fairly easy fix!

Right now, `get()` looks like this:

```c
C *get(Env* env, C *key) {
    Entry *cur = env->head;

    while (cur) {
        if (scmp(key->val.label, cur->key)) {
            return copy_one_cell(cur->value);
        }
        cur = cur->next;
    }

    return NULL;
}
```

You can see right there that if a variable is not found in an environment, then
it just returns NULL, and that's it!

In a pattern that is becoming fairly familiar by now, we need yet another
linked list of environments. An environment should be linked to whatever
environment it is being evaluated inside.

Currently, an `Env` is a struct that contains just one pointer:

```c
typedef struct Env {
    struct Entry *head;
} Env;
```

We'll add a `next` member.

```c
typedef struct Env {
    struct Entry *head;
    struct Env *next;
} Env;
```

and initialize it to `NULL` in the "constructor" function:

```c
Env *new_env() {
    Env *out = malloc(sizeof(Env));
    if (!out) { exit(1); };
    out->head = NULL;
    out->next = NULL;
    return out;
}
```

Now, back in the get function, simply check and see if there is a next member
to attempt to look up a given value in if it isn't found in the provided Env:

```c
C *get(Env* env, C *key) {
    Entry *cur = env->head;

    while (cur) {
        if (scmp(key->val.label, cur->key)) {
            return copy_one_cell(cur->value);
        }
        cur = cur->next;
    }

    if (env->next) {
        return get(env->next, key);
    }

    return NULL;
}
```

The final change to hook all of this up lives back in `apply_proc()`, which
currently looks like:

```c
static C *apply_proc(C* proc, Env *env) {

    C *cur = proc->val.proc.args->val.list;
    C *curarg = proc->next;

    int arity = count_list(cur);

    int numpassed = count_list(curarg);

    if (arity != numpassed) {
        printf("arity error on proc application\n");
        exit(1);
    }

    struct Env *frame = new_env();
    C *nextarg;
    for(int i = 0; i < arity; i++) {
        nextarg = curarg->next;
        curarg->next = &nil;
        set(frame, cur->val.label, eval(curarg, env));
        curarg = nextarg;
        cur = cur->next;
    }

    C *out = eval(proc->val.proc.body, frame);

    free_cell(proc->val.proc.args);
    free(proc);
    free_env(frame);

    return out;
}
```

As you can see, the `frame` env that we've created has no `next` member yet,
since it was initialized to NULL Before we evaluate the `proc` body inside the
frame, we just have to hook up the frame to the parent environment. One line
will do it!

```c
// etc...

    frame->next = env;
    C *out = eval(proc->val.proc.body, frame);

// ...etc
```

Now, back in the example:

```scheme
(define z '(b c))

(define conser
    (lambda (x)
        (cons x z)))

(display (conser 'a))
```

The frame created to evalute `conser` in will have access to the global env
when it can't find the `z` variable inside of the frame, and it will find it, and lo

```c
(a b c)
```

<hr>

Not quite done! Consider this.

```scheme
(define conser
    (lambda (a)
        (lambda () (cons a '(hello)))))
```

`conser`, now, is a function that takes an argument and _returns a function_
that, when invoked, will cons that original argument onto the list `'(hello)`.

Will this work?

```scheme
(define conser
    (lambda (a)
        (lambda () (cons a '(hello)))))

(define myconser (conser '1))

(display myconser)
```

yields a procedure that takes no arguments but _contains a closed over variable
`a`_ whose definition lives in the invocation of `conser` from the line:

```
(define myconser (conser '1))
```

... and it looks like this:

```scheme
(PROC () (cons a (quote (hello))))
```

This is what we would expect, but if we try to apply that function:

```
(display (myconser))
```

```
Error: unbound label: a
```

Yikes! What's the problem exactly?

```c
// etc...

    frame->next = env;
    C *out = eval(proc->val.proc.body, frame);

// ...etc
```

This `->next` member is referring to the environment that the PROC is being
_evaluated inside of_. But that is not what we want here! We want access to the
_environment inside of which the procedure was **defined**!_

Oh, if only we had a reference to that lying around!

_But wait!_

I had mentioned in the last post that it was _absolutely vital_ to hold a
reference to a procedure's enclosing environment _inside the proc object
itself_. Well, this is why.

So, instead of this inside of apply_proc:

```c
    frame->next = env;
    C *out = eval(proc->val.proc.body, frame);
```

We want this!

```c
    frame->next = proc->val.proc.env;
    C *out = eval(proc->val.proc.body, frame);
```

::jazz hands::

BUT OH NO!

```scheme
(define conser
    (lambda (a)
        (lambda () (cons a '(hello)))))

(define myconser (conser '1))

(display myconser)
```

Is now crashing!

I have written this interpreter to always clean up after itself when it is done
evaluating an expression. By design, the only persistent memory objects are
explicitly `defined` in the sild code. The implicit temporary assignments in
the frame environments used to evaluate the lambda procedures are destroyed
after the lambda is evaluated.

The pertinent line above, in `apply_proc`, is:

```c
free_env(frame);
```

This _is_ the behavior I wanted! But in the case of `conser`, I need to persist the
environment that `myconser` was _defined_ in so that when I try to evaluate
`myconser`, I can still look up `a` in that enclosing environment. Currently,
the procedure I am trying to apply contains a _danging pointer_ to the
environment that it was defined in, because that environment was `free`'d right
after evaluation. That's why the program crashes; it encounters a
[segfault](https://en.wikipedia.org/wiki/Segmentation_fault).

This is a
[_closure_](https://simple.wikipedia.org/wiki/Closure_(computer_science)), that
enclosing environment, and maintaining them correctly is _difficult_, and non
trivial.

For now, simply removing that line will achieve what I want.

```scheme
(define conser
    (lambda (a)
        (lambda () (cons a '(hello)))))

(define myconser (conser '1))

(display (myconser))
```

Can now look up `a` and displays:

```scheme
(1 hello)
```

\o/

A preliminary coda
----------------

So... this fixes the problem with the segfault, yes, but it introduces a new
problem- a giant memory leak. Now, everytime I evaluate a procedure and create a
frame environment to help me with that, I have one more Env that may or
may not be referenced anywhere. If I have a long enough running program, these
will eventually fill up all the memory available, and the program will die.

To _really_ solve this problem, I would have to implement a garbage collector
inside the language! I only really want to hang onto frame environments that
are referenced somewhere... if they are not referenced anywhere then I could
safely free them. This is a big project all on it's own and there are [many ways](https://spin.atomicobject.com/2014/09/03/visualizing-garbage-collection-algorithms/)
to implement GC. If Sild were to ever be a real, useful language, it would need
to be garbage collected, somehow! (It would also need a standard library of
some sort, or at the very least, you know, numbers...)

As I was doing this project, this is the point when I decided I was "done."

Not really _done_ done, I would very much like to implement a garbage
collector! (and also numbers...) and likely will! But not right now.

My initial goal for was to implement a very basic interpreted lisp
that could express quote, car, cons, cdr, eq, atom, cond, define, display, and
lambda. I was able to do that! I learned an enormous amount along the way, and
the scope of the project creeped appropriately in order to accomodate those
goals.

Garbage collection, a standard library, and numerical support would be
incredibly interesting projects! But they are in a different category than what
I've done so far. As are a repl, and better error handling, tail call
optimization, and a test suite...  these are all things I'd like to do, but not
right now.

I've recorded this whole process in painstaking detail for my future self, and
for anyone else who might be interested in the subject. I hope it's been
interesting! I plan to write some more posts about Sild, but for now, this
feels like the right place to stop. So, if you've gotten this far, thanks for
reading!
