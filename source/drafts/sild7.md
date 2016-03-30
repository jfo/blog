---
title: Sild7 eval
layout: post
---

With the basic read function working, it's time to write `eval`!

I want eval to accept a cell, and return an evaluated cell. What exactly
'evaluated' means is immaterial right now. Here's a good first go.

```c
C* eval(C* c) {
    return c;
}
```

Further, a cell's evaluated version, if it has a `CONS` component (meaning the
`next` member of the cell struct is pointing to a cell that is not `NIL`)
should be pointing to an evaluated cell. So before returning the cell that I
passed in, I need to evaluate it's `next` member.

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
["chicken"](chicken)

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
it, and can result in pretty insidious bugs.

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

But how about this:

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
inside of the sublist have been left untouched. I need to evaluate sublists, as
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

And success! Again, `"a b (hi mom) c"` evals to:

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

Now that I am evaluating sublists, it doesn't matter what depth I go to, every `LABEL` will be evaluated to 'chicken'. 

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

You know, `debuglist()` is getting a little unwieldy, as far as output is concerned.
