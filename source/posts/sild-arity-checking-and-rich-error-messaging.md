---
title: Sild - arity checking and rich error messaging
layout: post
date: 2016-06-27
tags: rc
---

I'd like to take a post and just do some refactoring, and clean things up a
bit. Where are some opportunities for that kind of thing?

Every builtin function does an arity check on its arguments before it does
anything else. this check follows a simple pattern... take `cons` for example:

```c
    if (operand->type == NIL || // checks that there is a first argument.
        operand->next->type == NIL || // checks that there is a second argument
        operand->next->next->type != NIL) { // checks that there is NOT a third argument
        exit(1);
    }
```

It has to go in order this way, because if the conditional attempted to access
`operand->next` when the `operand` was `NIL`, it would be trying to dereference
the `NULL` pointer that `NIL` is acting as a wrapper for. Here's another, for
`car` and `cdr`, which both have only one argument.

```c
if (operand->type == NIL || operand->next->type != NIL) {
    exit(1);
}
```

This is generic enough to abstract into a simple function that can be called at
the beginning of each builtin. It will take the first operand and the number of
arguments, and return true if the number matches the number of arguments passed
to the function. Like most of the other functions that operate on these linked
lists, it could be recursive.

```c
void arity_check(int args, C *operand) {
    if (args > 0) {
        if (operand->type == NIL) {
            exit(1);
        } else {
            arity_check(args - 1, operand->next);
        }
    } else if (args == 0 && operand->type != NIL){
        exit(1);
    }
}
```

I can now replace the long hand checks in the builtin functions with a call to
this function with the appropriate number of args.

```c
C *quote(C *operand) {
    arity_check(1, operand);
    return operand;
}
```

But you know what? I want to stop writing crappy errors that just exit with a
generic code. #itstime for real error messaging. To do this, I could just print something to standard out before exiting, like this:

```c
void arity_check(int args, C *operand) {
    if (args > 0) {
        if (operand->type == NIL) {
            printf("something happened, you didn't have enough args");
            exit(1);
        } else {
            arity_check(args - 1, operand->next);
        }
    } else if (args == 0 && operand->type != NIL){
        printf("something happened, you had too many args");
        exit(1);
    }
}
```

But standard out (`stdout`) is not the most appropriate stream for this
message. It's an error message, so it should be directed to standard error:
`stderr`. I can print to an arbitrary stream by using `fprintf` instead:

```c
void arity_check(int args, C *operand) {
    if (args > 0) {
        if (operand->type == NIL) {
            fprintf(stderr, "something happened, you didn't have enough args");
            exit(1);
        } else {
            arity_check(args - 1, operand->next);
        }
    } else if (args == 0 && operand->type != NIL){
        fprintf(stderr, "something happened, you had too many args");
        exit(1);
    }
}
```
This is heading in the right direction, but it's not very rich. What function
was being called? What was being passed in? I can give `arity_check()` the name
of the caller like this:

```c
void arity_check(char *caller_name, int args, C *operand) {
    if (args > 0) {
        if (operand->type == NIL) {
            fprintf(stderr,
            "something happened, you didn't have enough args to %s",
            caller_name);
            exit(1);
        } else {
            arity_check("quote", args - 1, operand->next);
        }
    } else if (args == 0 && operand->type != NIL){
        fprintf(stderr,
        "something happened, you had too many args to %s",
        caller_name);
        exit(1);
    }
}
```

This is better, but you know what? I don't need to make this recursive at all,
really. Doing so means I have to copy all those inputs to the function on each
call, and I don't really know what state I'm in when the error gets tripped. I
can just count the number of args to the function and compare it against the
number that was passed in. That's much easier!


```c
void arity_check(char *caller_name, int args, C *cur) {
    int passed_in = 0;
    while (cur->type != NIL) {
        passed_in++;
        cur = cur->next;
    }
    if (passed_in != args) {
        fprintf(stderr,
        "ArityError: %s expected %d, got %d",
        caller_name, args, passed_in
        );
        exit(1);
    }
}
```

I still would like to list the arguments passed in. I can retain access to the
first operand by copying the pointer at the beginning before transforming it in
the counting loop.

```c
void arity_check(char *caller_name, int args, C *c) {
    C *cur = c;
    int passed_in = 0;
    while (cur->type != NIL) {
        passed_in++;
        cur = cur->next;
    }
    if (passed_in != args) {
        fprintf(stderr,
        "ArityError: %s expected %d, got %d",
        caller_name, args, passed_in
        );
        print_list(c);
        exit(1);
    }
}
```

Hey great! Now when I call something like:

```
(quote this (that))
```

I get something like this:

```
ArityError: quote expected 1, got 2: this (that)
shell returned 1
```

MUCH more helpful. I can just replace the arity checks in all the builtins with
this simple call, and I get cleaner code and more useful error messaging, to
boot.
