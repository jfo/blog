---
title: Sild16 save the environment
layout: post
---

A lot of refactoring, and makefiling, and shuffling things around in the last
few posts, but I'm to a point where I feel comfortable moving on!

The next basic function in the pipe is `define`; it is going to take two arguments, and look something like this:

```
(define whatever '(1 2 3))
```

where `whatever` is any arbitrary `LABEL` and the second argument is
anything at all. `define` will evaluate the second argument and store it in
some environment under the label given as the first argument, and after this,
all references in the code to the label `whatever` should be evaluated to the
second argument. So, for instance:

```
(cons '0 whatever)
```

Should return

```
(0 1 2 3)
```

I know that in order to save that association, I'm going to need a place to
store it, and for that, I'll need some concept of an 'environment'. I don't
really know what it's going to look like yet, but I know it's going to need a
header file, and I have a general idea of what its interface is going to look
like. I know I'm going to have some sort of struct called an Env, I know I'm
going to need a setter function that takes an `Env` and a key value pair, and a
getter that takes an `Env` and a key and returns a value- and I know I'll need
a deletion function too. This is basically a miniature little CRUD interface!
(set = Create, get = Read, delete+set = Update, delete = Delete)

```c
#ifndef ENV_GUARD
#define ENV_GUARD

typedef struct _Env Env;

C *set(Env*,C *key, C *value);
C *get(Env*, C *key);
C *delete(Env*, C *key);

#endif
```

A couple of things to note here! Unlike the `cell.h` file, which defines the
structs in full, I don't plan on interacting with an Environment except through
the api that I'm defining here. Much like how the `FILE` object is opaque to
the consumer of `stdio.h`, I want the interaction to be constrained to these
basic functions. I am free then, to change the internal workings of the
implementation of those functions and the underlying env struct however I want,
and I won't have to go through my other code and update it all, as long as it
still conforms to this basic api.

I'll jump a little bit now, before implementing something for this, to where it
will be used in the evaluation code! `eval` currently looks like this:

```c
C *eval(C* c) {
    switch (c->type) {
        case LIST:
        {
            C *out = apply(eval(c->val.list));
            out->next = c->next;
            free(c);
            return out;
        }
        case LABEL:
        case BUILTIN:
        case NIL:
            return c;
    }
}
```

Where evaluating a `LABEL` simply returns itself. This is silly- I want a label
to return what it has been assigned to, or else throw an error! This is where I
will be `get()`ting a value from an `Env`

```c
#include "eval.h"

C *eval(C* c) {
    switch (c->type) {
        case LIST:
        {
            C *out = apply(eval(c->val.list));
            out->next = c->next;
            free(c);
            return out;
        }
        case LABEL:
            return get(env, c);
        case BUILTIN:
        case NIL:
            return c;
    }
}
```

Immediately we see a big problem with this- there is no `Env` to pass through
to this getter function! I haven't added that bit yet! And sure enough:

```c
src/eval.c:37:24: error: use of undeclared identifier 'env'
    return get(env, c);
           ^
```

Get ready for a big, but boring changeset. In order to have access to that
Environment (whatever it turns out to be!) in all of these calls to `eval` and
all the builtin functions, I have to add an `Env` parameter to _every
single function signature_ and pass it through to every single call to eval.
I'm not going to show that, but you can see it [here](https://github.com/urthbound/sildpost/commit/38483fea3045683f5ddd0525f24bdb4d444cdca9)

One operative part is creating a NULL `Env` n `evalfile` and passing it through into `eval`:

```c
    Env * env = NULL;
    while((c = read(fp)) != &nil) {
        c = eval(c, env);
        print(c);
        free_cell(c);
    }
```

and that I've set the `get()` function to simply return an empty list for _any_ label.

```c
C *get(Env* env, C *key) {
    return empty_list();
}
```

Since `get` inside of `eval` is just returning an empty list, I can eval something like this:

```scheme
(cons something somethingelse)
```

And it will evaluate both of those labels to an empty list and return:

```scheme
(())
```

Ah, I should remember to clean up the label cell that I fetched!

```
C *eval(C* c, Env *env) {
    switch (c->type) {
        case LIST:
        {
            C *out = apply(eval(c->val.list, env), env);
            out->next = c->next;
            free(c);
            return out;
        }
        case LABEL:
        {
            C *out = get(env, c);
            free_one_cell(c);
            return out;
        }
        case BUILTIN:
        case NIL:
            return c;
    }
}
```
