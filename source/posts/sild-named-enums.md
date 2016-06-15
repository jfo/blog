---
title: Sild - typedeffed enums have a benefit!
layout: post
date: 2016-06-15
tags: rc
---

I've got a short one today.

As of now, the enum I've been using to represent cell types has been an anonymous one.

```c
enum { NIL, LABEL, LIST };

union V {
    char * label;
    struct C * list;
};

typedef struct C {
    int type;
    union V val;
    struct C * next;
} C;
```

But I'm going to give it a name.

```c
enum CellType { NIL, LABEL, LIST };
```

So that I can use it as a type inside the cell struct, like this.

```c
typedef struct C {
    enum CellType type;
    union V val;
    struct C * next;
} C;
```

Now, I'm going to switch the internal conditionals inside of the `debug_list()`
function from `if` / `else if` statements:

```c
void debug_list_inner(C *l, int depth) {
    printtabs(depth);
    if (l->type == LABEL) {
            printf("LABEL- Address: %p, Value: %s Next: %p\n", l, l->val.label, l->next);
            debug_list_inner(l->next, depth );
    } else if (l->type == LIST) {
            printf("LIST- Address: %p, List_Value: %p Next: %p\n", l, l->val.list, l->next);
            debug_list_inner(l->val.list, depth + 1);
            debug_list_inner(l->next, depth);
    } else if (l->type == NIL) {
            printf("NIL- Address: %p\n", &nil);
            printtabs(depth - 1);
            printf("-------------------------------------------------------\n");
    }
}
```

To a switch statement.

```c
void debug_list_inner(C *l, int depth) {
    printtabs(depth);
    switch (l->type) {
        case LABEL:
            printf("LABEL- Address: %p, Value: %s Next: %p\n", l, l->val.label, l->next);
            debug_list_inner(l->next, depth );
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

Notice that I've had to add `break;`s at the end of each code block to prevent
fall through, since this function doesn't return anything.

Why do I want to do this? There is actually a really good reason! Because the
compiler now knows what the type (`enum Celltype`) of the cell's `type` member
is, and it knows that the switch statement is operating on this type, it can
catch me if I try to write a switch and forget to account for every possible
case. Look what happens if I remove the `LIST` case, for example!

```c
sild.c:27:13: warning: enumeration value 'LIST' not handled in switch [-Wswitch]
    switch (l->type) {
                    ^
                    1 warning generated.
```

It is just a warning, it won't stop the compilation from succeeding, but it's a
very valuable one! When I start writing the interpreter functions, it will
become very important that every case is accounted for.

<hr>

While I'm at the `typedef` store, I'm also going to typedef the `union` that represents the value member of the cell struct.

```c
typedef union V {
    char * label;
    struct C * list;
} V;
```

Now I can instantiate the `.val` member like this:

```c
makecell(LIST, (V){.list = read(s)}, read(s));
```

Short and sweet.
