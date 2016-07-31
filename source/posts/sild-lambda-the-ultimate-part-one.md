---
title: Sild - lambdas p.1
layout: post
date: 2016-07-24
tags: rc
---

Strap in, it is time for lambdas. If you're just joining us, this is the maybe
penultimate post in a long series that started
[here](/sild-is-a-lisp-dialect/).

<hr>

A lambda is an anonymous, unnamed function that can be applied to an arbitrary
set of inputs. Usually it looks something like:

```scheme
(lambda (x) x)
```

That's the [identity
function](https://en.wikipedia.org/wiki/Identity_function). If we were to want
to perhaps call it on something, it would look like this.

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
implemented any type of number support, so, to Sild,  `1` is still just an
arbitrary character string).

So, they are different. We still do need that built in identity function, after
all.

<hr>

I'm going to draw a distinction now. It took me a long time to figure this out,
but once I did it made everything a lot simpler.

A lambda is an anonymous function. A function is a procedure. The [_special
form_](http://www.lispworks.com/documentation/HyperSpec/Body/03_ababa.htm)
"lambda" denotes an anonymous procedure. But from the implementation's point of
view, `lambda` is a special form that _produces a procedure_ that can _then_ be
applied to an arbitrary set of arguments.

Let's think about this for a moment. The way the interpreter is written, if I were to write this:

```scheme
((car '(car)) '(1 2 3))
```

What am I going to get out of it? Let's walk through it.

The interpreter sees a list, so it tries to apply the first item in that list
to the remaining items as a function. It sees another list:

```scheme
(car '(car))
```

So it tries to evaluate this list before trying to apply it. What does it get
out of that evalutation?

Once again, it tries to apply the first item in the list to the remaining
arguments, but this time, it has more luck. `car` is not a list, it's a
builtin! We know what to do with that one, so the interpreter passes off
control to the function that the builtin points to. As we already know, `car`
expects a list and returns the first thing in that list. What is being passed
to it?

```scheme
'(car)
```

It needs to evaluate this to see if the result is a list.

Remember that `'` expands to a quoted form, so what the interpreter is really seeing is:

```scheme
(quote (car))
```

Another list! But this one is easy, right? `quote` is another builtin, it just
returns its arg unevaluated. So this whole thing returns `(car)`, which is a
list with one thing in it, which the original, calling `car` knows what to do with.

So, that call to `car` returns `car`. It could have returned anything- whatever
was the first thing in that list. So, back to the original:

```scheme
((car '(car)) '(1 2 3))
```

ends up looking like

```scheme
(car '(1 2 3))
```

Now the interpreter is able to apply the first item to the rest. Once again,
car returns the first thing in the list that is passed to it. Round and round we go...


```scheme
(car (quote (1 2 3)))
```

```scheme
1
```

This is all familiar!


<hr>

But what about lambdas?

Ok, so... interpreter sees a list. Tries to apply the first thing in that list.
Sees another list... same deal. Now it sees `lambda`. What is it supposed to
do? It needs to _return a procedure_. So after it evaluates the lambda, it
should see something like:

```scheme
(PROC '9)
```

That `PROC` object needs to hold three things inside of it: the argument list,
for binding labels to the arguments being passed to it, the body of the
function, and a _reference to the environment it was produced in_. That
last one is a little hairy, but very, _very_ important, and I'll come back to
it in great detail in a later post. For now, just notice that when a lambda
turns into a PROC, it retains a link to the env that was passed into the
`lambda()` C function!

What should that look like?

```scheme
; arg list    function body
;       \   /
(lambda (x) x)
```

so, let's say the interpreter produces this `PROC` and then tries to apply it:

```scheme
(PROC '9)
```

It should first evaluate the arguments passed to it, in this case `'9`, then it
needs to bind the result to the argument list, in this case `(x)`, so duriing
the evaluationg of this procedure's body, `x = 9`. Then, it evaluates the
body in that new, temporary environment, in this case the function
body is simply `x`.  So it evaluates `x` and since `x = 9`, the whole thing
returns `9`. The end, sleep tight.

Some notes to this- for now, I think the arity should match. This should throw
an error:

```scheme
((lambda (x y) x) '1)
```

So should this, I think:

```scheme
((lambda (x y) x) '1 '2 '3)
```

In each case, the number of arguments passed to the function is not equal to
the number of arguments the function expects. I don't know much about flexible
variable arity, maybe it's a good idea? But it doesn't make sense to me right
now, especially since if you want to pass in some number of things, well...

```scheme
((lambda (x) (car (cdr x))) '(1 2 3))
```

Seems like there is a way to do so already.

<hr>

So what is a `PROC`, really? Well, it's going to be a new type. We know how
this goes.

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

```scheme
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

    // type checking the arg list
    if (operand->type != LIST) {
        fprintf(stderr, "lambda expected a LIST as its first argument and did not get one\n");
        exit(1);
    }

    // returning a new PROC cell
    return makecell(PROC, (V){ .proc = { operand, operand2, env } }, &nil);
}
```

This function is fairly straightforward, it's when we try to apply that cell as
a function that things get interesting.

<hr>

Now that I have a new type, I'll have to account for it in all of the various
switch statements that operate on cell types.

In `debug_list`, I'll simply output the new procval struct in the same way as
the others:

```c
case PROC:
    printf("PROC- Address: %p, Next: %p\n| Args: \n", l, l->next);
    debug_list_inner(l->val.proc.args, depth + 1);
    printf("| Body: \n");
    debug_list_inner(l->val.proc.body, depth + 1);
    debug_list_inner(l->next, depth);
    break;
```

similarly, in `print`:

```c
case PROC:
    fprintf(output_stream, "(PROC ");
    print_inner(l->val.proc.args, depth, output_stream);
    fprintf(output_stream, " ");
    print_inner(l->val.proc.body, depth, output_stream);
    fprintf(output_stream, ")");
    break;
```

In `eval`, a `PROC` should evaluate to itself, just like a `BUILTIN`, or `NIL`

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

Looks pretty simple until you remember that we haven't written `apply_proc()` yet!

<hr>

`apply_proc` is a beast, it's the big kahuna of all the functions in this
project. It's the heart of the eval/apply loop.

All of the business logic of applying an anonymous procedure has to live in
this function. Let's take it step by step.

```c
static C *apply_proc(C* proc, Env *env) {
}
```

It will be static, I only need to call it from `apply`.

First, I'll need to check the arity against the number of arguments that have
been passed into it. For this, I'll need a function that can count how many
things are in the argument list, then count how many things have been passed,
and then compare them. Remember that the form will be:

```scheme
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

And I'll need to implement `count_list()`. This is relatively straightforward,
and I'll simply do it iteratively...

```c
static int count_list(C *c){
    int i= 0;
    // count args until the end of the list!
    while(c->type != NIL) {
        i++;
        c = c->next;
    }
    return i;
};
```

Great! That wraps up a dynamic arity check.

Next, I need to evaluate the arguments being passed and set them to the labels
designated in the arg list. For this, I'll create a new environment called
`frame` to set them in.

```c
    // make an env just for this procedure application!
    struct Env *frame = new_env();

    C *nextarg;
    for(int i = 0; i < arity; i++) {
        // retain a reference to the next arg before disconnecting it
        nextarg = curarg->next;

        // disconnect next arg from curarg
        curarg->next = &nil;

        // evaluate curarg _in the enclosing environment_ and assign cur to it in the frame
        set(frame, cur->val.label, eval(curarg, env));

        // advance to next label / value pair
        curarg = nextarg;
        cur = cur->next;
    }
```

Notice a very important point here is that the arguments being passed into the
lambda are evaluated in the _enclosing_ environment that the lambda is being
applied _inside of_ BEFORE being passed to the loop that assigns that result to
a label in the frame. This enables us to _shadow_ variables effectively.

Consider the following:

```scheme
(define thingy '(2 3 4))

(define cdrer (lambda (thingy) (cdr thingy)))

(display
    (cdrer (cdr thingy))
)
```

Here, "thingy" is being shadowed in the lambda application. It means one thing
in the global env, and another in the frame, but the two definitions are
effectively isolated from one another.

Look at this expansion:

```scheme
(cdrer (cdr thingy))
(cdrer (cdr '(2 3 4)))
(cdrer (3 4))
```
and internal to the lambda...

```scheme
(cdr thingy)
(cdr (3 4))
(4)
```

Which is ultimately what we get returned.

<hr>

Now we're ready to evaluate the body of the function in the frame! Remember,
the PROC object contains three things: an arg list, a function body, and a
reference to the enclosing environment that we're not going to worry about just
yet.

So far in `apply_proc()` we've done some arity and type checking, evaluated the
passed arguments, and assigned them to their labels in the frame env that we've
created.

Here's the money line:

```c
C *out = eval(proc->val.proc.body, frame);
```

And that's that. We've evaluated the body of the lambda in the context of its
local frame environment. All that is left is to clean up after ourselves.

We free the args:

```c
free_cell(proc->val.proc.args);
```

We free the proc cell pointer itself:

```c
free(proc);
```

and we free the frame

```c
free_env(frame);
```

Then we can return the result that we wanted all along.

```c
return out;
```

That's it! The whole `apply_proc()` function looks like this:

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

    // eval will free the body, here:
    C *out = eval(proc->val.proc.body, frame);
    // but the args and the proc cell itself still need to be freed manually
    // after application:

    free_cell(proc->val.proc.args);
    free(proc);
    free_env(frame);

    return out;
}
```

:D

<hr>

This is pretty spectacular, being able to apply procedures! Let's
look at an easy way to use them!

We have `car` and `cdr`, but what if we wanted to _second_ item in a list?

We could go like:

```scheme
(car (cdr '(1 2 3)))
```

```
2
```

If we did that a lot, it would be helpful to have a shortcut:

```scheme
(define cadr (lambda (x) (car (cdr x))))
(cadr '(1 2 3))
```

```scheme
2
```

That's a traditional pattern in a lisp, we could define a whole host of helper functions!

```scheme
(define caddr (lambda (x) (car (cdr (cdr x)))))
(define caadr (lambda (x) (car (car (cdr x)))))
; etc...
```

But, much more impressively, we can use control flow introduced by `cond` to
write more dynamic procedures!

What if we want the last item in a list?

```scheme
(define last
    (lambda (l)
        (cond (cdr l) (last (cdr l))
              (car l))))
```

Now,

```scheme
(last '(1 2 3 4 5 6 7))
```

is `7`

```scheme
(last '(1 2))
```

is `2`

and furthermore,


```c
(display
    (last '( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100))
)
```

is `100`!

NOW we're cooking with gas! In the next post I'll address some thorny problems
inherent in this design and how to fix them, and we'll discover the power of
what we've wrought, and ... well, we'll sort of be at the end then, won't we?
