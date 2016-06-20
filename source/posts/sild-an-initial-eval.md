---
title: Sild - an initial eval
layout: post
date: 2016-06-19
tags: rc
---

With the basic read function working, it's time to write `eval`!

I want eval to accept a cell, and return an evaluated cell. What exactly
'evaluated' means is immaterial right now. Here's a good first go.

```c
C* eval(C* c) {
    return c;
}
```

Further, a cell's evaluated version, if it has a cons component (meaning the
`next` member of the cell struct is pointing to a cell that is not `NIL`)
should be pointing to an evaluated cell. So before returning the cell that I
passed in, I need to evaluate its `next` member and assign the output of
that evaluation to the `next` member of the passed in cell.

```c
C* eval(C* c) {
    c->next = eval(c->next);
    return c;
}
```

If I try to run this right now, I'll get a familiar rupture, as there is no
check against `NIL` and it will eventually try to pass the `NULL` pointer that
`NIL` is wrapped around into `eval()`. Just as I did in the debug_list
function, I'll add a switch statement to operate on the three different types
of cells differently.


```c
C *eval(C* c) {
    switch (c->type) {
        case LABEL:
        case LIST:
            c->next = eval(c->next);
            return c;
        case NIL:
            return c;
    }
}
```

This is now a type of transparent pass through function. If I eval a cell right
now, I get back exactly what I put in. The only interesting thing is that I'm
necessarily evaluating all the elements that are linked to the cell I'm passing
in. To see that this is actually working, I'll change all the `LABEL`s to
"[chicken](https://youtu.be/yL_-1d9OSdk?t=37://youtu.be/yL_-1d9OSdk?t=37s)".

```c
C *eval(C* c) {
    switch (c->type) {
        case LABEL:
            c->val.label = "chicken";
            // falling through
        case LIST:
            c->next = eval(c->next);
            return c;
        case NIL:
            return c;
    }
}
```

Notice that the fall through from the LABEL case to the LIST case is desirable,
here. I still do want to evaluate the next cell after a label.  It is good form
to note when this kind of situation arises, because it is _very_ easy to miss
that it's happening, and can result in pretty insidious bugs.

```c
int main() {
    char *a_string = "a b c";
    C *a_list = read(&a_string);
    debug_list(eval(a_list));
    return 0;
}
```

Gives me:

```c
LABEL- Address: 0x7fe970403a70, Value: chicken Next: 0x7fe970403a50
LABEL- Address: 0x7fe970403a50, Value: chicken Next: 0x7fe970403a30
LABEL- Address: 0x7fe970403a30, Value: chicken Next: 0x10656d040
NIL- Address: 0x10656d040
-------------------------
```

Success!

But that is just a linked list of atoms. It's important to note here that
reading in a string of atoms like that gives us an _internal_ representation of
a linked list of atoms, but is _not_ a LIST in the context of the language
space. You can see that the three atoms are linked in the same way, but the enclosing linked list is not itself the `val.list` member of a `LIST` cell. This is a subtle but important distinction. For example, how 'bout this:

```c
int main() {
    char *a_string = "a b (hi mom) c";
    C *a_list = read(&a_string);
    debug_list(eval(a_list));
    return 0;
}
```

```c
LABEL- Address: 0x7fdb19403af0, Value: chicken Next: 0x7fdb19403ad0
LABEL- Address: 0x7fdb19403ad0, Value: chicken Next: 0x7fdb19403ab0
LIST- Address: 0x7fdb19403ab0, List_Value: 0x7fdb19403a60 Next: 0x7fdb19403a90
|   LABEL- Address: 0x7fdb19403a60, Value: hi Next: 0x7fdb19403a40
|   LABEL- Address: 0x7fdb19403a40, Value: mom Next: 0x10b7ab040
|   NIL- Address: 0x10b7ab040
-------------------------------------------------------
LABEL- Address: 0x7fdb19403a90, Value: chicken Next: 0x10b7ab040
NIL- Address: 0x10b7ab040
-------------------------------------------------------
```

Hmm... the atoms at the top level have been evaluated accurately, but the atoms
inside of the 'LIST' have been left untouched. I need to evaluate sublists, as
well! The fall through is no longer desirable, since I'm treating the `LIST`
and `LABEL` types differently now.

```c
C *eval(C* c) {
    switch (c->type) {
        case LABEL:
            c->val.label = "chicken";
            c->next = eval(c->next);
            return c;
        case LIST:
            c->val.list = eval(c->val.list);
            c->next = eval(c->next);
            return c;
        case NIL:
            return c;
    }
}
```

And success! Now, `"a b (hi mom) c"` evals to:

```c
LABEL- Address: 0x7f9282c03af0, Value: chicken Next: 0x7f9282c03ad0
LABEL- Address: 0x7f9282c03ad0, Value: chicken Next: 0x7f9282c03ab0
LIST- Address: 0x7f9282c03ab0, List_Value: 0x7f9282c03a60 Next: 0x7f9282c03a90
|   LABEL- Address: 0x7f9282c03a60, Value: chicken Next: 0x7f9282c03a40
|   LABEL- Address: 0x7f9282c03a40, Value: chicken Next: 0x10219e040
|   NIL- Address: 0x10219e040
-------------------------------------------------------
LABEL- Address: 0x7f9282c03a90, Value: chicken Next: 0x10219e040
NIL- Address: 0x10219e040
-------------------------------------------------------
```

Now that I am evaluating sublists, it doesn't matter what depth I go to, every
`LABEL` will be evaluated to 'chicken'.

What about

```c
"(a b (c (c e f) g (h i j) k (l m n o p) q (r (s) t(u (v (w (x) y (and) (z)))))))"
```

?

You guessed it.

```c
LIST- Address: 0x7fede2404090, List_Value: 0x7fede2404070 Next: 0x104310040
|   LABEL- Address: 0x7fede2404070, Value: chicken Next: 0x7fede2404050
|   LABEL- Address: 0x7fede2404050, Value: chicken Next: 0x7fede2404030
|   LIST- Address: 0x7fede2404030, List_Value: 0x7fede2404010 Next: 0x104310040
|   |   LABEL- Address: 0x7fede2404010, Value: chicken Next: 0x7fede2403ff0
|   |   LIST- Address: 0x7fede2403ff0, List_Value: 0x7fede2403aa0 Next: 0x7fede2403fd0
|   |   |   LABEL- Address: 0x7fede2403aa0, Value: chicken Next: 0x7fede2403a80
|   |   |   LABEL- Address: 0x7fede2403a80, Value: chicken Next: 0x7fede2403a60
|   |   |   LABEL- Address: 0x7fede2403a60, Value: chicken Next: 0x104310040
|   |   |   NIL- Address: 0x104310040
|   |   -------------------------------------------------------
|   |   LABEL- Address: 0x7fede2403fd0, Value: chicken Next: 0x7fede2403fb0
|   |   LIST- Address: 0x7fede2403fb0, List_Value: 0x7fede2403b40 Next: 0x7fede2403f90
|   |   |   LABEL- Address: 0x7fede2403b40, Value: chicken Next: 0x7fede2403b20
|   |   |   LABEL- Address: 0x7fede2403b20, Value: chicken Next: 0x7fede2403b00
|   |   |   LABEL- Address: 0x7fede2403b00, Value: chicken Next: 0x104310040
|   |   |   NIL- Address: 0x104310040
|   |   -------------------------------------------------------
|   |   LABEL- Address: 0x7fede2403f90, Value: chicken Next: 0x7fede2403f70
|   |   LIST- Address: 0x7fede2403f70, List_Value: 0x7fede2403c40 Next: 0x7fede2403f50
|   |   |   LABEL- Address: 0x7fede2403c40, Value: chicken Next: 0x7fede2403c20
|   |   |   LABEL- Address: 0x7fede2403c20, Value: chicken Next: 0x7fede2403c00
|   |   |   LABEL- Address: 0x7fede2403c00, Value: chicken Next: 0x7fede2403be0
|   |   |   LABEL- Address: 0x7fede2403be0, Value: chicken Next: 0x7fede2403bc0
|   |   |   LABEL- Address: 0x7fede2403bc0, Value: chicken Next: 0x104310040
|   |   |   NIL- Address: 0x104310040
|   |   -------------------------------------------------------
|   |   LABEL- Address: 0x7fede2403f50, Value: chicken Next: 0x7fede2403f30
|   |   LIST- Address: 0x7fede2403f30, List_Value: 0x7fede2403f10 Next: 0x104310040
|   |   |   LABEL- Address: 0x7fede2403f10, Value: chicken Next: 0x7fede2403ef0
|   |   |   LIST- Address: 0x7fede2403ef0, List_Value: 0x7fede2403c90 Next: 0x7fede2403ed0
|   |   |   |   LABEL- Address: 0x7fede2403c90, Value: chicken Next: 0x104310040
|   |   |   |   NIL- Address: 0x104310040
|   |   |   -------------------------------------------------------
|   |   |   LABEL- Address: 0x7fede2403ed0, Value: chicken Next: 0x7fede2403eb0
|   |   |   LIST- Address: 0x7fede2403eb0, List_Value: 0x7fede2403e90 Next: 0x104310040
|   |   |   |   LABEL- Address: 0x7fede2403e90, Value: chicken Next: 0x7fede2403e70
|   |   |   |   LIST- Address: 0x7fede2403e70, List_Value: 0x7fede2403e50 Next: 0x104310040
|   |   |   |   |   LABEL- Address: 0x7fede2403e50, Value: chicken Next: 0x7fede2403e30
|   |   |   |   |   LIST- Address: 0x7fede2403e30, List_Value: 0x7fede2403e10 Next: 0x104310040
|   |   |   |   |   |   LABEL- Address: 0x7fede2403e10, Value: chicken Next: 0x7fede2403df0
|   |   |   |   |   |   LIST- Address: 0x7fede2403df0, List_Value: 0x7fede2403d00 Next: 0x7fede2403dd0
|   |   |   |   |   |   |   LABEL- Address: 0x7fede2403d00, Value: chicken Next: 0x104310040
|   |   |   |   |   |   |   NIL- Address: 0x104310040
|   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   LABEL- Address: 0x7fede2403dd0, Value: chicken Next: 0x7fede2403db0
|   |   |   |   |   |   LIST- Address: 0x7fede2403db0, List_Value: 0x7fede2403d40 Next: 0x7fede2403d90
|   |   |   |   |   |   |   LABEL- Address: 0x7fede2403d40, Value: chicken Next: 0x104310040
|   |   |   |   |   |   |   NIL- Address: 0x104310040
|   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   LIST- Address: 0x7fede2403d90, List_Value: 0x7fede2403d70 Next: 0x104310040
|   |   |   |   |   |   |   LABEL- Address: 0x7fede2403d70, Value: chicken Next: 0x104310040
|   |   |   |   |   |   |   NIL- Address: 0x104310040
|   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   NIL- Address: 0x104310040
|   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   NIL- Address: 0x104310040
|   |   |   |   -------------------------------------------------------
|   |   |   |   NIL- Address: 0x104310040
|   |   |   -------------------------------------------------------
|   |   |   NIL- Address: 0x104310040
|   |   -------------------------------------------------------
|   |   NIL- Address: 0x104310040
|   -------------------------------------------------------
|   NIL- Address: 0x104310040
-------------------------------------------------------
NIL- Address: 0x104310040
-------------------------------------------------------
```

<hr>

You know, `debuglist()` is getting a little unwieldy, as far as output is
concerned. It is useful for seeing how the linked list cells are stiched
together internally in the memory space of the running C program, but I don't
strictly need to see all those memory addresses all the time, do I? It is time
to bring back `print_list`.

It will have the same basic structure as `debug_list()`, but it will print different
things. As a reminder of what `debug_list_inner()` looks like (remember that
`debug_list()` is just a wrapper around `debug_list_inner()` that passes in an
initial depth of `0`):

```c
void debug_list_inner(C *l, int depth) {
    printtabs(depth);
    switch (l->type) {
        case LABEL:
            printf("LABEL- Address: %p, Value: %s Next: %p\n", l, l->val.label, l->next);
            debug_list_inner(l->next, depth);
            break;
        case LIST:
            printf("LIST- Address: %p, List_Value: %p Next: %p\n", l, l->val.list, l->next);
            debug_list_inner(l->val.list, depth + 1);
            debug_list_inner(l->next, depth);
            break;
        case NIL:
            printf("NIL- Address: %p\n", &nil);
            printtabs(depth - 1);
            printf("-------------------------------------------------------\n");
            break;
    }
}
```

Let's strip out all the specifics and make a skeleton:

```c
void print_list(C *l) {
    switch (l->type) {
        case LABEL:
        case LIST:
        case NIL:
    }
}
```

And a first pass at what we'll want to see when we print a list, annotated:

```c
void print_list(C *l) {
    switch (l->type) {
        case LABEL:
            printf("%s", l->val.label);
            print_list(l->next);
            break;
        case LIST:
            printf("(");
            print_list(l->val.list);
            print_list(l->next);
            break;
        case NIL:
            printf(")");
            break;
    }
}
```

Let's try it!

```c
int main() {
    char *a_string = "(a b c d)";
    C *a_list = read(&a_string);
    print_list(a_list);
    return 0;
}
```
yields:

```
(abcd))
```

Not bad! Need to add some spaces between those labels, and deal with that
trailing closing paren, as well! First, for the spaces, I simply need to print a space if the atom that I'm printing is _not_ the last cell in a list.

```c
void print_list(C *l) {
    switch (l->type) {
        case LABEL:
            printf("%s", l->val.label);

            if (l->next->type != NIL)
                printf(" ");

            print_list(l->next);
            break;
        case LIST:
            printf("(");
            print_list(l->val.list);

            // also adding here to print space after a list ends!
            if (l->next->type != NIL)
                printf(" ");

            print_list(l->next);
            break;
        case NIL:
            printf(")");
            break;
    }
}
```

This gives me:

```
(a b c d))
```

Which looks pretty good!

Now, as for that trailing paren! If we look back at the read function, you can see that it is treating `')'` and `'\0'` the same way:

```c
etc...
    switch(current_char) {
        case ')': case '\0':
            list_depth--;
            (*s)++;
            return &nil;
...etc
```

This is functionally correct- the `NULL` byte in the string should return a
`NIL` cell to guarantee that the list it read in is a well formed one.

The answer is to keep track of the depth of the list that has been passed in,
and only print a closing paren if the depth is greater than `0`, similar to the way I handled indention in `debug_list()`.

```c
void print_list_inner(C *l, int depth) {
    switch (l->type) {
        case LABEL:
            printf("%s", l->val.label);

            if (l->next->type != NIL)
                printf(" ");

            print_list_inner(l->next, depth);
            break;
        case LIST:
            printf("(");
            print_list_inner(l->val.list, depth + 1);

            if (l->next->type != NIL)
                printf(" ");

            print_list_inner(l->next, depth);
            break;
        case NIL:
            if (depth > 0) {
                printf(")");
            }
            break;
    }
}

void print_list(C *l) {
    print_list_inner(l, 0);
};

```

Just like `debug_list`, I've wrapped this in a helper function that always
starts at 0 depth. This achieves the desired effect!

```c
int main() {
    char *a_string = "(a b c d)";
    C *a_list = read(&a_string);
    print_list(a_list);
    return 0;
}
```

Is now outputting `(a b c d)`, just like I wanted it to!

I'm not conviced this is an optimal solution, but it is ok for now!

How about:

```c
"(a b (c (c e f) g (h i j) k (l m n o p) q (r (s) t (u (v (w (x) y (and) (z)))))))"
```

Through the extra special `eval()` that turns everything into chickens, and
then through this improved `print_list()` function

```c
(chicken chicken (chicken (chicken chicken chicken) chicken (chicken chicken chicken) chicken (chicken chicken chicken chicken chicken) chicken (chicken (chicken) chicken (chicken (chicken (chicken (chicken) chicken (chicken) (chicken)))))))
```

This is real progress! I can imagine a much better way to print
out deeply nested lists than this- this is just one long stream of cells with
no newlines! But it looks a lot cleaner and terser than `debug_list()` does,
and it's more familiar and easier to read.
