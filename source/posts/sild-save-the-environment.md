---
title: Sild - save the environment
layout: post
date: 2016-07-16
tags: rc
---

A lot of refactoring, and makefiling, and shuffling things around in the last
few posts, but I'm to a point where I feel comfortable moving on!

The next basic function in the pipe is `define`; it is going to take two
arguments, and look something like this:

```
(define whatever (quote (1 2 3)))
```

where `whatever` is any arbitrary `LABEL` and the second argument is
anything at all. `define` will evaluate the second argument and store it in
some environment under the label given as the first argument, and after this,
all references in the code to the label `whatever` should be evaluated to the
second argument. So, for instance:

```
(cons (quote 0) whatever)
```

Should evaluate `(quote 0)` to `0` and `whatever` to `(1 2 3)`, and then cons
them together to return:

```
(0 1 2 3)
```

I know that in order to save that association, I'm going to need a place to
store it, and for that, I'll need some concept of an 'environment'. I don't
really know what it's going to look like yet, but I know it's going to need a
header file, and I have a general idea of what its interface is going to be.  I
know I'm going to have some sort of struct called an Env, I know I'm going to
need a setter function that takes an `Env` and a key value pair and returns
void, and a getter that takes an `Env` and a key and returns a value- and I
know I'll need a deletion function too, or at least a way to free a whole env
up at once. This is basically a miniature little CRUD interface!  (set =
Create, get = Read, delete+set = Update, delete = Delete)

```c
#ifndef ENV_GUARD
#define ENV_GUARD

typedef struct _Env Env;

C *set(Env*,C *key, C *value);
C *get(Env*, C *key);
C *delete(Env*, C *key);

#endif
```

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
all the builtin functions, I have to add an `Env` parameter to _every single
function signature_ and pass it through to every single call to eval.  I'm not
going to show that, but you can see it
[here](https://github.com/urthbound/sildpost/commit/38483fea3045683f5ddd0525f24bdb4d444cdca9)

One operative part is creating a NULL `Env` in `evalfile` and passing it
through into `eval`:

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

<hr>

`Env` has been typedeffed, so I can pass pointers to it around, but I haven't
defined what an `Env` is, yet. Let's start with this:

```c
struct Env {
    char *key;
    C *value;
};
```

Which is super reductive, but will illustrate a point! Now, I'll set `get` to
return `truth` if the key passed in matches the key in the env, and the empty
list otherwise:

```c
C *get(Env* env, C *key) {
    if (scmp(key->val.label, env->key)) {
        return truth();
    } else {
        return empty_list();
    }
}
```
Back in the `eval_file` function, I'm going to have to actually pass in a real
live `Env` now, instead of just a NULL pointer, since I will be dereferencing
it. BUT, I can't assign values to the `Env` from there, since I haven't made
the internals public (for good reasons!). I'll introduce a `new_env()` function
to `env.c` and `env.h` that will return a pointer to an env, and I'll set a key
for it!

```c
Env *new_env() {
    Env *out = malloc(sizeof(Env));
    if (!out) { exit(1) };
    out->key = "derp";
    out->value = NULL;
    return out;
}
```

Looks a lot like `makecell`, doesn't it?

This Env only has one key: 'derp'. When `get` tries to evaluate LABELS, it will
return truth for only labels with the label `derp` and empty lists for
everything else.

Back in eval_file:

```c
void eval_file(const char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        fprintf(stderr, "Error opening file: %s\n", filename);
        exit (1);
    }

    C * c;
    Env *env = new_env();

    while((c = read(fp)) != &nil) {
        c = eval(c, env);
        print(c);
        free_cell(c);
    }

    fclose(fp);
}
```
Now, if I evaluate something like this:

```
(cons something somethingelse)
(cons derp somethingelse)
```

I get back:

```
(())
(#t)
```

Which is exactly what I wanted to happen!

If I:

```
(cons somethingelse derp)
```

I'll get an error, which makes sense, since that evaluates to

```
(cons () #t)
```

Which shouldn't work, since I can't cons something _onto_ something that isn't
a list.

<hr>

Ok, so, this is pretty contrived. I really need a way to `set` values in an
Env, and to search through the entries to try and find a match. First of all,
that struct definition of Env is completely useless for this, as it only holds
one key value pair. That's really an `Entry`, which I will define internally
above `Env`

```c
typedef struct Entry {
    char *key;
    C *value;
} Entry;
```

Env, now, should just hold a single thing: a pointer to the first entry in a
dictionary!

```c
struct Env {
    struct Entry *head;
};
```

Now, I can change what was `new_env` to `new_entry` and add a new `new_env`:

```c
static Entry *new_entry() {
    Entry *out = malloc(sizeof(Entry));
    if (!out) { exit(1); };
    out->key = "derp";
    out->value = NULL;
    return out;
}

Env *new_env() {
    Env *out = malloc(sizeof(Env));
    if (!out) { exit(1); };
    out->head = new_entry();
    return out;
}
```

This works!

```
(())
(#t)
```

Now, as I'm passing around Env pointers outside of this file, I'm really
passing around a pointer to a pointer of the first entry in a list of entries!
Just like I did in the first few posts defining cells, I'm going to use a
singly linked list structure to define these Entrys. That means they need to
have a reference to the next cell in the series:

```c
typedef struct Entry {
    char *key;
    C *value;
    struct Entry *next;
} Entry;
```

Let's make two entries!

```c
static Entry *new_entry() {
    Entry *out = malloc(sizeof(Entry));
    if (!out) { exit(1); };
    out->key = "derp";
    out->value = NULL;
    out->next = NULL;
    return out;
}

static Entry *new_entry2() {
    Entry *out = malloc(sizeof(Entry));
    if (!out) { exit(1); };
    out->key = "another";
    out->value = NULL;
    out->next = new_entry();
    return out;
}

Env *new_env() {
    Env *out = malloc(sizeof(Env));
    if (!out) { exit(1); };
    out->head = new_entry2();
    return out;
}
```

Boy, that's ugly! Now, the Env looks like this:

```
Env
  \
   Entry[another] -> Entry[derp] -> NULL
```

I need to adjust the get function to traverse this list, and to know how to
handle a NULL pointer.

```c
C *get(Env* env, C *key) {
    Entry *cur = env->head;

    while (cur) {
        if (scmp(key->val.label, cur->key)) {
            return truth();
        }
        cur = cur->next;
    }
    return empty_list();
}
```

I'm going to skip the sentinel node this time, because I'm only implementing
that method that looks through everything, and I can keep that as is!

Now, both `"derp"` and `"another"` will return `#t`, and still everything else
will return an empty list.

```
(cons another somethingelse)
(cons derp literallyanything)
```

Will yield;

```
(#t)
(#t)
```

This is getting interesting, eh?

<hr>
Let's look back at those `new_entry` functions. I can totally generalize that!

```
static Entry *new_entry(char *key, C *value) {
    char *keyval = malloc(sizeof(key));
    if (!keyval) { exit(1); };
    strcpy(keyval, key);

    Entry *out = malloc(sizeof(Entry));
    if (!out) { exit(1); };

    out->key = keyval;
    out->value = value;
    out->next = NULL;
    return out;
}
```

Now, I can make those entries using this function inside of `new_env` itself.

```
Env *new_env() {

    struct Entry *entry1 = new_entry("one", NULL);
    struct Entry *entry2 = new_entry("two", NULL);
    entry1->next = entry2;

    Env *out = malloc(sizeof(Env));
    if (!out) { exit(1); };
    out->head = entry1;
    return out;
}
```

And I get the same effect!

<hr>

We're getting close, now! Back in the `get` function, I'm just returning true
if I find a match, but what I really want is arbitrary values being assigned
and returned.

```diff
 C *get(Env* env, C *key) {
     Entry *cur = env->head;
     while (cur) {
         if (scmp(key->val.label, cur->key)) {
-            return truth();
+            return cur->value;
         }
         cur = cur->next;
     }
     return NULL;
 }
```

and down in `new_env()`:

```diff
 Env *new_env() {

-    struct Entry *entry1 = new_entry("one", NULL);
-    struct Entry *entry2 = new_entry("two", NULL);
+    struct Entry *entry1 = new_entry("one", truth());
+    struct Entry *entry2 = new_entry("two", truth());
     entry1->next = entry2;

     Env *out = malloc(sizeof(Env));
     if (!out) { exit(1); };
     out->head = entry1;
     return out;
 }
```

This works great for something like:

```
one
two
anything
```

which yields:

```
#t
#t

Error: unbound label: anything

shell returned 1
```

Just as we want, but what about this?

```
one
one
```

Can you guess? When `eval` looks at the first `one`, it retrieves the cell
pointer to the `Entry`'s `value` member. Remember that eval as I've written it
always cleans up after itself:

```c
        case LABEL:
        {
            C *out = get(env, c);
            if (out) {
                free_one_cell(c); // right here!
                return out;
            } else {
```

Which means that the second time I try to evaluate `one`, it tries to clean up after itself and blows up, because that pointer has already been freed:

```c
sild(76627,0x7fff7b607000) malloc: *** error for object 0x7f88f0403380: pointer being freed was not allocated
*** set a breakpoint in malloc_error_break to debug

Command terminated
```

When I fetch a value from the Environment, I need to be fetching a _copy_ of
it, so that when it passes through the rest of the evaluation, and gets cleaned
up afterwards, the original entry is still intact and can be fetched again.

this function will live back in `cell.c`, and will look exactly like
`free_cell` and `free_one_cell`, which look like this:

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
        case BUILTIN:
            free(c->val.func.name);
            free_cell(c->next);
            free(c);
            break;
        case NIL:
            break;
    }
}

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
        case BUILTIN:
            free(c->val.func.name);
            free(c);
            break;
        case NIL:
            break;
    }
}
```

This is some wordy code, but it's necessary to handle all the different types
of cells. Let's adapt them! Remember that the only substantive difference
between `copy` and `copy_one` is that `copy_one` doesn't propogate through
`next` addresses!

```c
C *copy_cell(C *c) {
    switch (c->type) {
        case LABEL:
            return makecell(LABEL, (V){ c->val.label }, copy_cell(c->next));
        case LIST:
            return makecell(LIST, (V){ .list = copy_cell(c->val.list) }, copy_cell(c->next));
        case BUILTIN:
            return makecell(BUILTIN, (V){ .func = { c->val.func.name, c->val.func.addr} }, copy_cell(c->next));
        case NIL:
            return &nil;
    }
}
```

and `copy_one_cell`, with the `next` members pointing to `&nil`:

```c
C *copy_one_cell(C *c) {
    switch (c->type) {
        case LABEL:
            return makecell(LABEL, (V){ c->val.label }, &nil);
        case LIST:
            return makecell(LIST, (V){ .list = copy_cell(c->val.list) }, &nil);
        case BUILTIN:
            return makecell(BUILTIN, (V){ .func = { c->val.func.name, c->val.func.addr} }, &nil);
        case NIL:
            return &nil;
    }
}
```

You might notice a problem right away with this! `makecell` allocates memory
for the contents of a cell, but those contents sometimes include pointers to
strings that also need to be allocated! I can pull this into a helper function
that allocates some memory, copies a string into it.

```c
char *scpy(char *s) {
    int l = 0;
    while (s[l] != '\0') { l++; }
    char *out = malloc(l);
    if (!out) { exit(1); }

    for (int i = 0; i < l; i++) {
        out[i] = s[i];
    }
    out[l] = '\0';
    return out;
};
```

I'll plop this into `utils.c` and use it in the `env.c` file to return a copy instead of the original.

```c
...
            return copy_one_cell(cur->value);
...
```

Now, everything cleans itself up correctly when it is evaluated.

> A word about perf
> -----------------

> You might be reading this and saying something like: "Hey, making copies all
> the time seems pretty wasteful, and malloc system calls can be pretty
> expensive, and this isn't very performative, you're an idiot!"

> I wouldn't really argue with you! (except _maybe_ on the idiot thing, which
> seems a little harsh). All of these things, in fact, are very very true.
> There are lots of opportunities for making this faster, better, and generally
> more perfomant, in fact, I'm trying to keep a running tally of those things
> in my head, and am looking forward to a lot of refactoring after I get
> everything working! The goal of this iteration is clarity and consistency in
> implementation, not performance. I'd love to make that a priority later
> though!

<hr>

Let's set.
---------

So, I've got a way to get stuff out of an `Env`, but I'm currently setting it by hand.
This is silly! I want a corresponding `set` function that takes an env, and a
key value pair, and inserts a new entry into that Env (at the head of it, which
becomes important later for scoping!) and then updates that Env's internal
`head` member to point to this new entry.

First, the function signature, which I had already put into the `h` file:

```c
C *set(Env* env, C *key, C *value) {
}
```

Except, you know what? now that I think of it, this function needn't return
anything at all, since if it fails I want to exit. And though I'm always going
to be returning a value, I might as well pass in a string so I don't have to
muck around with new cells.

```c
void set(Env* env, char *key, C *value) {
}
```
So I'll make a new entry out of the key value pair with my shiny `new_entry()` function:

```c
void set(Env* env, char *key, C *value) {
    new_entry(key, value);
}
```

And I'll tell the new_entry that its `next` member should be the current head
of the Env:

```c
void set(Env* env, char *key, C *value) {
    struct Entry *new = new_entry(key, value);
    new->next = Env->head;
}
```

And I'll tell the Env that its head is now the new entry:

```c
void set(Env* env, char *key, C *value) {
    struct Entry *new = new_entry(key, value);
    new->next = Env->head;
    env->head = new;
}
```

And that's it! If the `malloc`ing happening inside of new_entry fails, I'll have
an `exit(1)` call to cath it. I've been falling behind on setting up good exit error
messaging, but I'll make a sweep on that at some point.

Back in the `eval_file` function, then, I can do this:

```c
Env *env = new_env();
set(env, "hi", truth());
set(env, "mom", truth());
```

And I have an env with two entries!

```
hi
mom
```

Gives me:

```
#t
#t
```

Success!

There's one interesting aspect of this env thing that is implicit in its design! What if I do this?

```c
Env *env = new_env();
set(env, "hi", truth());
set(env, "hi", empty_list());
```

Two entries with the same key but different values. Now, in sild land, what
will I get if I evaluate the LABEL `hi`? How does my `get` function choose?

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

I didn't put any special logic in there- how does it know which one? Well...

```
()
```

It returns the first one it finds! This doesn't seem like a big deal, but in a
way it will be the backbone of my language's variable scoping, later on.

<hr>

Now that I have all these helpers defined, and a concept of an Env defined,
it's a short walk in the park to implement a new `sild` builtin function that
can utilize them! The signature will look like all the builtin functions:

```c
C *define(C *operand, Env *env);
```

it will take two arguments, a key and a value. (in sild land):

```c
C *define(C *operand, Env *env) {
    arity_check("define", 2, operand);
}
```

The key _must_ be a label:

```c
C *define(C *operand, Env *env) {
    arity_check("define", 2, operand);
    if (operand->type != LABEL) { exit(1); }
}
```

Then it will `set` the arguments to a key value pair inside the given env,
evalling the 2nd operand.

```c
C *define(C *operand, Env *env) {
    arity_check("define", 2, operand);
    if (operand->type != LABEL) { exit(1); }
    set(env, operand->val.label, eval(operand->next, env));
}
```

Then it will free the label! I don't need to free the evalled operand, because
that will serve as the master copy in the env.

```c
C *define(C *operand, Env *env) {
    arity_check("define", 2, operand);
    if (operand->type != LABEL) { exit(1); }
    set(env, operand->val.label, eval(operand->next, env));
    free_one_cell(operand);
}
```

And that's really that! It has to return something, so how about nil? I won't
be doing anything with that return value ever (you will see why soon!)

```c
C *define(C *operand, Env *env) {
    arity_check("define", 2, operand);
    if (operand->type != LABEL) { exit(1); }
    set(env, operand->val.label, eval(operand->next, env));
    free_one_cell(operand);
    return &nil;
}
```

Now, I can add `define` into the reader, just like the other ones:

```
...
} else if (scmp(token, "define")) {
    out = makecell(BUILTIN, (V){ .func = {token, define} }, &nil);
...
```

And lo and behold, this totally works!

```
(define thing (quote (1 2 3)))
thing
```

Will print out

```
(1 2 3)
```

And I could use `thing` wherever it makes sense to use (1 2 3)

```
(define thing (quote (1 2 3)))
(define otherthing (quote 0))
(cons otherthing thing)
```

yields:

```
(0 1 2 3)
```

You can even compose them! For example:

```
(define thing (quote (1 2 3)))
(define otherthing (quote 0))
(define wat (cons otherthing thing))
wat
```

Now, `wat` is equal to `(0 1 2 3)`!

One more thing
--------------

Well, a couple more things! `define` is the first builtin function that has any
sort of side effect- in this case, it is mutating the only possessor of state
in the running program: the top level environment. Its return value, if it were
a C function, would be `void`, since it's being called only for those side
effect. I don't have a `void` type in sild (yet?), but I assigned it to return
`nil` as an expediency. To see why this might be problematic, consider:

```
(cons (quote 1) (define thing (quote ())))
```

This, er, sort of makes sense, right? You would kind of half expect this to
return

```
(1)
```

Since `thing` is supposed to be equal to `()` now, right?

It doesn't, since `define` is returning `nil`, `cons` really gets called on:

```
(cons (quote 1))
```

I don't know... should define return its label? Blargh...

This is venturing into some interesting language design question territory, and
I'm not ready to make a decision! I am going to default to parity with scheme,
which solves this problem by making `define` to return `undefined`, which is
kind of funny, and _disallowing_ define statements outside of the top level
forms.

This looks a little funny compared to the other calls, but i can catch this in
the reader step by throwing an error if the reader encounters a `define`
keyword when the depth is greater than 1!

```c
...
    } else if (scmp(token, "define")) {
        if (depth > 1) {
            fprintf(stderr, "Error: define found in inner form.");
            exit(1);
        }
        out = makecell(BUILTIN, (V){ .func = {token, define} }, &nil);
...
```

This solves the problem. Defines will now only be able to happen in the top
level, and I don't really need to make another sild language void type or
whatever, since I'll never be able to call define anywhere that would matter.

I can even have the C function `define` return `void`, and all will be well.

```
void define(C *operand, Env *env) {
    arity_check("define", 2, operand);
    if (operand->type != LABEL) {
        fprintf(stderr, "define expected a LABEL as its first argument and did not get one\n");
        exit(1);
    }
    set(env, operand->val.label, eval(operand->next, env));
    free_one_cell(operand);
}
```

"But what about `delete()` in the env?"

I don't want to expose a deletion function to the sild space just yet, if at
all, once a variable is bound using `define` in the global environment, I want
it to remain that way. But I do need to free the environment itself after I'm
done with it, or I'll have a memory leak.

Just as I free the results of an evaluation of a form after I don't need it anymore in `eval_file`

```c
void eval_file(const char *filename) {

        fprintf(stderr, "Error opening file: %s\n", filename);
        exit (1);
    }

    C * c;

    Env *env = new_env();
    while((c = read(fp)) != &nil) {
        c = eval(c, env);
        free_cell(c);           // here!
    }

    fclose(fp);
}
```

So too will I free the environment I created for that file after I'm done
reading the file! It will go here:

```c
void eval_file(const char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        fprintf(stderr, "Error opening file: %s\n", filename);
        exit (1);
    }

    C * c;

    Env *env = new_env();
    while((c = read(fp)) != &nil) {
        c = eval(c, env);
        free_cell(c);
    }
    free_env(env);              // here!

    fclose(fp);
}
```

And it will look like this:

```
void free_env(Env* env) {
    // get the first entry in the env
    Entry *cur = env->head;

    //holding place for the next entry
    Entry *next;

    while (cur) {
        // free the char* key
        free(cur->key);

        // free the cell that is the value
        free_cell(cur->value);

        // hold pointer to next cell here, so that I can ...
        next = cur->next;

        // free the entry space for cur
        free(cur);

        // reassign cur to what was its next entry...
        cur = next;
    }
    // finally, when there are no more entries, free the environment itself.
    free(env);
}
```

Now, I am being a good memory citizen and cleaning up after myself when I am
done reading all the forms in a file.
