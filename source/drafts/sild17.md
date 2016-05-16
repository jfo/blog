---
title: Sild17 lambda
layout: post
---

Strap in, it is time for lambdas.  What the hell is a lambda?

A lambda is an anonymous function that can be applied to an arbitrary set of
inputs. Usually it looks something like:

```scheme
(lambda (x) x)
```

That's the identity function. If we were to want to perhaps call it on
something, it would look like this.

```scheme
((lambda (x) x) '(1 2 3))
```

That call would output:

```scheme
(1 2 3)
```

You might be tempted to say, hey wait- that's the same as the builtin quote
function! But it is in fact _not_ the same thing, at all! Consider:

```scheme
(quote (1 2 3))
```

Will produce

```scheme
(1 2 3)
```

But

```scheme
((lambda (x) x) (1 2 3))
```

Will produce

```
Error: unbound label: 1
```

Because the latter attempts to evaluate the list that's being passed to it
before passing it into the lambda. In this case, that means trying to lookup
the label 1 in the environment, which doesn't exist. (remember, I haven't yet
implemented any type of number support, so `1` is still just an arbitrary
character string to Sild).

So, they are different. We still do need that inbuilt identity function, after
all.

<hr>

I'm going to draw a distinction now. It took me a long time to figure this out,
but once I did it made everything a lot simpler.

A lambda is an anonymous function. A function is a procedure. The special form
lambda denotes an anonymous procedure. But from the implementations point of
view, `lambda` is a special form that _produces a procedure_ that can then be
applied to a given set of arguments.

Let's think about this for a moment. The way the interpreter is written, if I were to write this:

```
((car '(car)) '(1 2 3))
```

What am I going to get out of it? Let's walk through it.

The interpreter sees a list, so it tries to apply the first item in that list
to the remaining items as a function. It sees another list:

```
(car '(car))
```

So it tries to evaluate this list before trying to apply it. What does it get
out of that evalutation?

Once again, it tries to apply the first item in the list to the remaining
arguments, but this time, it has more luck. `car` is not a list, it's a
builtin! So the interpreter passes off control to the function that the builtin
points to. As we already know, `car` expects a list and returns the first thing
in that list. What is being passed to it?

```
'(car)
```

It needs to evaluate this to see if the result is a list.

Remember that `'` expands to a quoted form, so what the interpreter is really seeing is:

```
(quote (car))
```

Another list! But this one is easy, right? `quote` is another builtin, it just
returns its arg unevaluated. So this whole thing returns `(car)`, which is a
list with one thing in it, which `car` knows what to do with.

So, that call to `car` returns `car`. It could have returned anything- whatever
was the first thing in that list. So, back to the original:

```
((car '(car)) '(1 2 3))
```

ends up looking like

```
(car '(1 2 3))
```

Now the interpreter is able to apply the first item to the rest. Once again,
car returns the first thing in the list that is passed to it. Round and round we go...


```
(car (quote (1 2 3)))
```

```
1
```

This is all familiar!


<hr>

But what about lambdas?

```
((lambda (x) x) '9)
```

Ok, so... interpreter sees a list. Tries to apply the first thing in that list.
Sees another list... same deal. Now it sees `lambda`. What is it supposed to
do? It needs to _return a procedure_. So after it evaluates the lambda, it
should see something like:

```
(PROC '9)
```

That `PROC` object needs to hold three things inside of it: the argument list,
for binding labels to the arguments being passed to it, the body of the
function, and a _reference to the environment it was produced in_. That
last one is a little hairy, I'll come back to it in great detail.

What should that look like?

```
; arg list    function body
;       \   /
(lambda (x) x)
```

so, let's say the interpreter produces this `PROC` and then tries to apply it:

```
(PROC '9)
```

It should first evaluate the arguments passed to it, in this case `'9`, then it
needs to bind the result to the argument list, in this case `(x)`, so in the
evaluationg of this procedure, `x = 9`. Then, it evaluates the function body in
that environment, in this case the function body is simply `x`. So it evaluates
`x` and since `x = 9`, the whole thing returns `9`. The end; sleep tight.

Some notes to this- the arity should match. This should throw an error:

```
((lambda (x y) x) '1)
```

So should this, I think:

```
((lambda (x y) x) '1 '2 '3)
```

In each case, the number of arguments passed to the function is not equal to
the number of arguments the function expects. I don't know much about variable
arity, maybe it's a good idea? But it doesn't make sense to me right now,
especially since if you want to pass in some number of things, well...

```
((lambda (x) (car (cdr x))) '(1 2 3))
```

Seems like there is a way to do so already.

<hr>

So what is a `PROC`? Well, it's going to be a new type. We know how this goes.

I'll add it here:

```c
enum CellType { NIL, LABEL, LIST, BUILTIN, PROC };
```

And I'll add it here:

```c
typedef union V {
    char * label;
    struct C * list;
    struct funcval func;
    struct procval proc; // here!
} V;
```

And I'll need a `procval` so that makes sense...

```c
struct procval {
    struct C *args;
    struct C *body;
    struct Env *env;
};
````

This is a little struct to hold those three things I mentioned earlier. Back to
the identity function example...

```
(lambda (x) x)
```

when evaluated, should produce this:

```c
makecell(PROC, (V){ .proc = { operand, operand2, env } }, &nil);
```

And so, I will make a new builtin function called `lambda` that will produce
that cell. This pattern will look familiar, it is the same as all the other
builtin functions!

```c
C *lambda(C *operand, Env *env) {
    // check arity for only two things- arg list and function body
    arity_check("lambda", 2, operand);

    // separating them from each other.
    C *operand2 = operand->next;
    operand->next = &nil;
    operand2->next = &nil;

    // returning a new PROC cell
    return makecell(PROC, (V){ .proc = { operand, operand2, env } }, &nil);
}
```

This function is fairly straightforward, it's when we try to apply that cell as
a function that things get interesting.

<hr>

Now that I have a new type, I'll have to account for it in all of the various
switch statements that operate on cell types.

In `debug_list`:

```c
case PROC:
    printf("PROC- Address: %p, Next: %p\n| Args: \n", l, l->next);
    debug_list_inner(l->val.proc.args, depth + 1);
    printf("| Body: \n");
    debug_list_inner(l->val.proc.body, depth + 1);
    debug_list_inner(l->next, depth);
    break;
```

In `print`:

```c
case PROC:
    fprintf(output_stream, "(PROC ");
    print_inner(l->val.proc.args, depth, output_stream);
    fprintf(output_stream, " ");
    print_inner(l->val.proc.body, depth, output_stream);
    fprintf(output_stream, ")");
    break;
```

In `eval`, a `PROC` shoudl evaluate to itself, just like a `BUILTIN`, or `NIL`

```c
...
case PROC:
case BUILTIN:
case NIL:
    return c;
...
```

And in `apply`, well, that's where the action happens.

```c
case PROC:
    return apply_proc(c, env);
```

Looks pretty simple until you remember that we haven't written `apply_proc()` yet.

<hr>

`apply_proc` is a beast, it's the big kahuna of all the functions in this
project. It's the heart of the eval/apply loop.

All of the business logic of apply an anonymous procedure has to live in this
function. Let's take it step by step.

```c
static C *apply_proc(C* proc, Env *env) {
}
```

It will be static, I only need to call it from `apply`.

First, I'll need to check the arity against the number of arguments that have
been passed in to it. For this, I'll need a function that can count how many
things are in the argument list, then count how many things have been passed,
and then compare them. Remember that the form will be:

```
; arg list    function body
;       \   /
((lambda (x) x) '1)
;                 \
;                   arguments being passed
```

```c
static C *apply_proc(C* proc, Env *env) {

    // first element in arg list
    C *cur = proc->val.proc.args->val.list;
    // first argument being passed
    C *curarg = proc->next;

    int arity = count_list(cur);
    int numpassed = count_list(curarg);

    if (arity != numpassed) {
        printf("arity error on proc application\n");
        exit(1);
    }

    // etc...
```

And I'll need to implement `count_list()`

```
static int count_list(C *c){
    int i= 0;
    while(c->type != NIL) {
        i++;
        c = c->next;
    }
    return i;
};
```

Great! A dynamic arity check.

Next, I need to evaluate the arguments being passed and set them to the labels
designated in the arg list. For this, I'll create a new environment called
`frame` to set them in.

```c
    struct Env *frame = new_env();
    C *nextarg;
    for(int i = 0; i < arity; i++) {
        nextarg = curarg->next;
        curarg->next = &nil;
        set(frame, cur->val.label, eval(curarg, env));
        curarg = nextarg;
        cur = cur->next;
    }
```
