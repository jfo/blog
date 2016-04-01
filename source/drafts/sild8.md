---
title: Sild8 apply
layout: post
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

This is the _Sild_ data that represents the `read` in string that looks like the C
string `"(+ 1 2)"`

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
I'll simply pass the input back out again.

```c
C *apply(C* c) {
    switch (c->type) {
        case LABEL:
        case LIST:
        case NIL:
            return c;
    }
}
```

It will be called from `eval` whenever it runs into a `LIST` and it will apply
the first argument of the list to the remaining arguments. In the struct's
lingo- given a `LIST` cell, it will look at the cell's `val.list` member, which
is, of course, itself a cell, and apply that cell's `car` (as an operator) to
its `cdr` (as operands).

In most cases, but not all, this also means evalling the operator and operands
before applying the function. For example, an expression like this one:

```c
"(+ 1 (- 3 2))"
```

Should equal zero, because we're subtracting the value of `(- 3 2)`, which
resolves to 1, from `1`. That nested expression has to be evaluated first.

In `eval()`, instead of evalling the list, we'll pass it to apply.


```c
C *eval(C* c) {
    switch (c->type) {
        case LABEL:
            c->next = eval(c->next);
            return c;
        case LIST:
            c->val.list = apply(c);
            c->next = eval(c->next);
            return c;
        case NIL:
            return c;
    }
}
```

Anything passed into the eval/apply loop will come out the other side exactly
the same, but inside the body of apply, we have the opportunity to dispatch the
list that we're evaluating into any function we want.

I'm not going to keep this function around, but let's say we have a C function
that takes two strings and returns a new string that is a concatenation of
them. There is probably a library function that does this, but for the sake of
demonstration, let's say it could look like this:

```c
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

The `val.label` members of the cell structs are currently only strings
(`LABELS`), so I needed a function that would operate on string to demonstrate
this. 
