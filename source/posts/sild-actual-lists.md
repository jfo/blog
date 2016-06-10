---
title: Sild - actual lists
layout: post
date: 2016-06-10
tags: rc
---

[So far](/sild-reading-substrings) I've made a linked list whose cells have an
arbitrary string as their value. I can read in an input string and turn it into
a linked list of words, like this:

```c
int main() {
    C *a_list = read("here are some words");
    debug_list(a_list);
    return 0;
}
```

Gives me a series of cells like this:

```c
Address: 0x7fed51403460, Value: here, Next: 0x7fed51403440
Address: 0x7fed51403440, Value: are, Next: 0x7fed51403420
Address: 0x7fed51403420, Value: some, Next: 0x7fed51403400
Address: 0x7fed51403400, Value: words, Next: 0x0
```

Alright! That is a _list_ of words, for sure. What if I read in a _lisp_ list?
(notice the surrounding parens on the inside of the double quotes now)...

```c
int main() {
    C *a_list = read("(here are some words)");
    debug_list(a_list);
    return 0;
}
```
This gives me:

```c
Address: 0x7f9852c03460, Value: (here, Next: 0x7f9852c03440
Address: 0x7f9852c03440, Value: are, Next: 0x7f9852c03420
Address: 0x7f9852c03420, Value: some, Next: 0x7f9852c03400
Address: 0x7f9852c03400, Value: words), Next: 0x0
```

Which is not at all what I want! Of course, as written, the parser doesn't know
anything about lists, or lisp syntax. It simply doesn't make a distinction
between the opening and closing parens and any other `char`. Further, though
I've been referring to the structure that results from linking a bunch of these
cell's together as a 'linked list', because that's what it is, but that structure
_alone_ is insufficient to express a lisp. I'm going to have to fix that
problem first.

<hr>

The most basic syntactical element of any lisp is a __symbolic expression__, or
an _S-Expression_ for short. An S-Expression can be only one of two basic
things: an _atom_ or a _list_. Right now, we only have a type of atom, there is
no concept of a list, at all. A cell, currently, can only hold a string; I need
to add another type of value to the cell that is itself a list. Because lists
are represented by a pointer address to the first element in the list, I simply
need to add another member to the cell struct that can hold one of those, like
so:

```c
typedef struct C {
    char * val;
    struct C * list_val;
    struct C * next;
} C;
```

I'll also add this member to the `makecell()` constructor function:

```c
C *makecell(char *val, C *list_val, C *next) {
    C *out = malloc(sizeof(C));
    out->val = val;
    out->list_val = list_val;
    out->next = next;
    return out;
};
```

And because I've added it there, I'll also have to pass in a `NULL` if I'm not
assigning it to anything when I call it.

```c
C * read(char *s) {
    switch(*s) {
        case '\0': case ')':
            return NULL;
        case ' ': case '\n':
            return read(s + 1);
        default:
            return makecell(read_substring(s), NULL, read(s + count_substring_length(s) + 1));
    }
}
```

Now, I need to teach the reader about parens, and what to do when it sees one.
The closing paren is easy, it represents the end of a list, just like the NULL
byte `'\0'` does, so that will also return `NULL`. The opening paren needs to
return a different type of cell, a list. It will also call `makecell()`. Take a
look at this new read function:

```c
C * read(char *s) {
    switch(*s) {
        case '\0': case ')':
            return NULL;
        case ' ': case '\n':
            return read(s + 1);
        case '(':
            return makecell(NULL, read(s + 1), read(s + count_list_length(s) + 1));
        default:
            return makecell(read_substring(s), NULL, read(s + count_substring_length(s) + 1));
    }
}
```

Now, if the reader sees an opening paren, it will begin to create a new list as
the `list_val` member of the cell it is creating. When it is done making that
sublist, it needs to jump ahead past the end of the list it just made and read
in the next value _from there_.

Notice that I've added a new function to do just that, `count_list_length()`
that knows how to figure out how many chars to jump ahead after reading a list
in. It looks like this, for now, and increments a pointer until it hits a
closing paren:

```c
int count_list_length(char *s) {
    int i = 0;
    while (s[i] != ')' && s[i] != '\0')
        i++;
    return i;
}
```

After adding printing of a `list_val` to `debug_list()`, like this:

```c
void debug_list(C *car) {
    printf("Address: %p, Value: %s, list_value: %p, Next: %p\n",
            car,
            car->val,
            car->list_val,
            car->next);
    if (car->list_val) {
        debug_list(car->list_val);
    }
    if (car->next) {
        debug_list(car->next);
    }
}
```

I can see what I'm reading in. The `read()` function now ignores parens as regular chars and does something like what I want:

```c
Address: 0x7fbdd0403480, Value: (null), list_value: 0x7fbdd0403460, Next: 0x0
Address: 0x7fbdd0403460, Value: here, list_value: 0x0, Next: 0x7fbdd0403440
Address: 0x7fbdd0403440, Value: are, list_value: 0x0, Next: 0x7fbdd0403420
Address: 0x7fbdd0403420, Value: some, list_value: 0x0, Next: 0x7fbdd0403400
Address: 0x7fbdd0403400, Value: words, list_value: 0x0, Next: 0x0
```

As you can see, the very first cell has nothing set as its `val` member, so it
prints `(null)`.

<hr>

How do I know, for any individual cell, whether it is an atom, or a list? It
can only be one or the other, after all, not both at once, not really. It
cannot, for example, have a `list_val` member that points to some other cell
_and_ have a `val` member that contains a string. I need to type these cells,
and attach a bit of metadata to each one that can help me to interpret it
correctly. I'll add one more member to the struct, then, like this:

```c
typedef struct C {
    int type;
    char * val;
    struct C * list_val;
    struct C * next;
} C;
```

And I'll define a couple of constants to use to represent these types:

```c
#define LABEL 0
#define LIST 1
```

I'm calling the string `val` members a _label_.

Now, we can do something like this, to treat them differently in the
`debug_list()` function, for example.

```c
void debug_list(C *car) {
    if (car->type == LABEL) {
            printf("LABEL- Address: %p, Value: %s Next: %p\n",
            car,
            car->val,
            car->next);
    } else if (car->type == LIST) {
            printf("LIST- Address: %p, List_Value: %p Next: %p\n",
            car,
            car->list_val,
            car->next);
    }

    if (car->list_val) {
        debug_list(car->list_val);
    } else if (car->next) {
        debug_list(car->next);
    }
}
```

I'll of course have to add this `type` as a member of the cell struct to both
the makecell function:

```c
C *makecell(int type, char *val, C *list_val, C *next) {
    C *out = malloc(sizeof(C));
    out->type = type;
    out->val = val;
    out->list_val = list_val;
    out->next = next;
    return out;
};
```

and the read function:

```c
C * read(char *s) {
    switch(*s) {
        case '\0': case ')':
            return NULL;
        case ' ': case '\n':
            return read(s + 1);
        case '(':
            return makecell(LIST, NULL, read(s + 1), read(s + count_list_length(s) + 1));
        default:
            return makecell(LABEL, read_substring(s), NULL, read(s + count_substring_length(s) + 1));
    }
}
```

Also, instead of defining constants longhand with `#define`, it is much simpler to use an `enum` type that does that for us:

```c
enum { LABEL, LIST };
```

`LABEL` is still a constant that represents `0` and `LIST` is still a constant
that represents `1`, this is just an easier, and more extensible, way to do
that.

<hr>

This struct is becoming unwieldy. Look how I have to pass in `NULL` values to
makecell when I'm making the other kind of cell.

If I'm constructing a cell that has a `list_val`, then I have to pass in `NULL`
to the `val` member, and vice versa. This is silly. A cell can only ever be one
or the other type, after all, and furthermore as it is I'm allocating space for
those members even when I'm not using them.

It's much better to use a `union`, which I wrote about before [here](/structs-and-unions).

A cell, now, will have only three members ever: a `type`, a generic `value` and
the `next` pointer to the next cell.

```c
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

I'm calling the `val` member's associated union `V`, because like the
`C` typedef for `Cell`, it shows up a LOT in the code and I want it to be clean
looking.

I can now update the `makecell()` signature to accept this type as an arg
instead of multiple different types of values.

```c
C *makecell(int type, union V val, C *next) {
    C *out = malloc(sizeof(C));
    out->type = type;
    out->val = val;
    out->next = next;
    return out;
};
```

And I can update the calls to it to pass in a union. The syntax for this is
kind of weird, but you can initialize a union like this:

```c
(union Example){ .member_name = "member value" };
```

In the read function, it looks like this:

```c
C * read(char *s) {
    switch(*s) {
        case '\0': case ')':
            return NULL;
        case ' ': case '\n':
            return read(s + 1);
        case '(':
            return makecell(LIST, (union V){.list = read(s + 1)}, read(s + count_list_length(s) + 1));
        default:
            return makecell(LABEL, (union V){.label = read_substring(s)}, read(s + count_substring_length(s) + 1));
    }
}
```

<hr>

This presents a new problem! Consider the `debug_list()` function, now.

```c
void debug_list(C *car) {
    if (car->type == LABEL) {
            printf("LABEL- Address: %p, Value: %s Next: %p\n",
            car,
            car->val.label,
            car->next);
            /* because of the union, there is some data there, it is not a pointer but it exists. */
            printf("%p", car->val.list);
    } else if (car->type == LIST) {
            printf("LIST- Address: %p, List_Value: %p Next: %p\n",
            car,
            car->val.list,
            car->next);
    }

    /* therefore this calls on the label bit, and ruptures! */
    if (car->val.list) {
        debug_list(car->val.list);
    }
    if (car->next) {
        debug_list(car->next);
    }
}
```

The chunk of memory that represents the cell looks like this:

```
-----------------------------
| type |    value    | next |
-----------------------------
```

When we try to check the existence of the `val.list` member,

```c
if (car->val.list) {
    debug_list(car->val.list);
}
```

The boolean returns true, because though there is not a valid cell pointer in
that space, there _is_ data there, that represents the `label` member. The
program then does what we tell it to and tries to `debug_list()` the string
pointer that lives in `val.label`, inevitably rupturing as a result.

I can fix this by putting the recursive call to debug the `list_val` _inside_
of the conditional that _already_ checks if it is a `LIST` typed cell.


```c
void debug_list(C *car) {
    if (car->type == LABEL) {
            printf("LABEL- Address: %p, Value: %s Next: %p\n",
            car,
            car->val.label,
            car->next);
    } else if (car->type == LIST) {
            printf("LIST- Address: %p, List_Value: %p Next: %p\n",
            car,
            car->val.list,
            car->next);
            debug_list(car->val.list);
    }

    if (car->next) {
        debug_list(car->next);
    }
}
```
But this highlights a situtation that I really don't like, which is that I have
to have a null check before every recursive call to any function that operates
on these lists. This isn't a huge deal now, but as the program grew it became
more difficult to reason about the structure of all the moving parts when each
function had to concern itself with both the cell it's operating directly on
_and_ the cell immediately following it (if it exists or not!).

I decided to solve this problem by creating a special type of cell, the `NIL`
cell. (h/t to Rubby).

```c
enum { NIL, LABEL, LIST };
```
And assigning it _only once_ as a global, static variable in the running
program. Notice that I'm initializing the struct with a bracketed, array like
syntax, and the union inside the struct with another such bracketed section.
When you assign a union in this way, it assumes the first member of the union.
This is a little terse, but in this case it doesn't matter; ostensibly, this
will never be accessed.

```c
static C nil = { NIL, {NULL}, NULL };
```

this cell, `nil`, is now the source of falsehood for everything running inside
the program. It exists in only one place, at the address that can be shown by
`&nil`, and I'll refer to it that way in the code because I want it to be clear
I'm explicitly looking at the address of the `nil` cell.

It's essentially a wrapper around the `NULL` pointer, so that I can operate on any
cell without worrying about the program hitting a `NULL` pointer in any normal
usage. Now, I change the read function to return `&nil` instead of `NULL` at
the end of a list or string:

```c
C * read(char *s) {
    switch(*s) {
        case '\0': case ')':
            return &nil;
        case ' ': case '\n':
            return read(s + 1);
        case '(':
            return makecell(LIST, (union V){.list = read(s + 1)}, read(s + count_list_length(s) + 1));
        default:
            return makecell(LABEL, (union V){.label = read_substring(s)}, read(s + count_substring_length(s) + 1));
    }
}
```

And I can change the `debug_list()` function to treat the `NIL` type as the
terminal cell in a string, instead of checking against a NULL pointer before
passing it in.

```c
void debug_list(C *car) {
    if (car->type == LABEL) {
            printf("LABEL- Address: %p, Value: %s Next: %p\n",
            car,
            car->val.label,
            car->next);
            debug_list(car->next);
    } else if (car->type == LIST) {
            printf("LIST- Address: %p, List_Value: %p Next: %p\n",
            car,
            car->val.list,
            car->next);
            debug_list(car->val.list);
    } else if (car->type == NIL) {
            printf("NIL");
    }
}
```

During some research, I discovered after implementing this that this is a known
pattern, and it has a name! It's called a 'sentinel node'

> Sentinel nodes
> ----------------

> Main article: [Sentinel node](https://en.wikipedia.org/wiki/Sentinel_node)

> In some implementations an extra 'sentinel' or 'dummy' node may be added before
> the first data record or after the last one. This convention simplifies and
> accelerates some list-handling algorithms, by ensuring that all links can be
> safely dereferenced and that every list (even one that contains no data
> elements) always has a "first" and "last" node.

To me, this looks a lot cleaner, and is a lot easier to reason about, which
will be a big help when I start writing more complicated functions that operate
on cells, like idk `eval` and `apply`... but that's for later.

Sublists
--------

Theres one remaining problem with the way the program is currently written with
regards to lists, and that is that it cannot handle sublists! Consider this:

```c
int main() {
    C *a_list = read("(let us consider words not chars)");
    debug_list(a_list);
    return 0;
}
```

returns:

```c
LIST- Address: 0x7fcd00c034e0, List_Value: 0x7fcd00c034c0 Next: 0x10bad4020
LABEL- Address: 0x7fcd00c034c0, Value: let Next: 0x7fcd00c034a0
LABEL- Address: 0x7fcd00c034a0, Value: us Next: 0x7fcd00c03480
LABEL- Address: 0x7fcd00c03480, Value: consider Next: 0x7fcd00c03460
LABEL- Address: 0x7fcd00c03460, Value: words Next: 0x7fcd00c03440
LABEL- Address: 0x7fcd00c03440, Value: not Next: 0x7fcd00c03420
LABEL- Address: 0x7fcd00c03420, Value: chars Next: 0x10bad4020
NIL
```

But this:

```c
int main() {
    C *a_list = read("(let us (consider) words not chars)");
    debug_list(a_list);
    return 0;
}
```

returns this:

```c
LIST- Address: 0x7f9bb8c03620, List_Value: 0x7f9bb8c03570 Next: 0x7f9bb8c03600
LABEL- Address: 0x7f9bb8c03570, Value: let Next: 0x7f9bb8c03550
LABEL- Address: 0x7f9bb8c03550, Value: us Next: 0x7f9bb8c03530
LIST- Address: 0x7f9bb8c03530, List_Value: 0x7f9bb8c03480 Next: 0x7f9bb8c03510
LABEL- Address: 0x7f9bb8c03480, Value: consider Next: 0x7f9bb8c03460
LABEL- Address: 0x7f9bb8c03460, Value: words Next: 0x7f9bb8c03440
LABEL- Address: 0x7f9bb8c03440, Value: not Next: 0x7f9bb8c03420
LABEL- Address: 0x7f9bb8c03420, Value: chars Next: 0x109a80020
NIL
```

Which is incorrect... "consider" should not be pointing to "words not chars",
the `LIST` cell that contains it should be! `debug_list()` is hard to read with
nesting, but the structure should look like this:

```c
let -> us -> LIST -> words -> not -> cars -> NIL
               \
                 consider -> NIL
```

But instead, it looks like this:

```c
let -> us -> LIST -> NIL
               \
                 consider -> words -> not -> cars -> NIL
```

If I take another look at `count_list_length`, I can see that it has no way of
knowing whether it is inside of a sublist or not. I can add a variable that
keeps track of this internally to this function.

```c
int count_list_length(char *s) {
    int depth = 1;
    int i = 1;
    while (depth > 0) {
        if (s[i] == '(') {
            depth += 1;
        } else if (s[i] == ')'){
            depth -= 1;
        }
        i++;
    }
    return i;
}
```

Now it will read sublists appropriately!

```c
LIST- Address: 0x7fbb6a403500, List_Value: 0x7fbb6a4034e0 Next: 0x10e9c6020
LABEL- Address: 0x7fbb6a4034e0, Value: let Next: 0x7fbb6a4034c0
LABEL- Address: 0x7fbb6a4034c0, Value: us Next: 0x7fbb6a4034a0
LIST- Address: 0x7fbb6a4034a0, List_Value: 0x7fbb6a4033f0 Next: 0x7fbb6a403480
LABEL- Address: 0x7fbb6a4033f0, Value: consider Next: 0x10e9c6020
NIL- Address: 0x10e9c6020
LABEL- Address: 0x7fbb6a403480, Value: words Next: 0x7fbb6a403460
LABEL- Address: 0x7fbb6a403460, Value: not Next: 0x7fbb6a403440
LABEL- Address: 0x7fbb6a403440, Value: chars Next: 0x10e9c6020
NIL- Address: 0x10e9c6020
NIL- Address: 0x10e9c6020
```

As I said before, the `debug_list()` function is now becoming difficult to use,
since the depth of nested lists aren't being visually represented. I can fix
this by passing in an `int depth` argument to the debugging function and
printing an indent for each level of nesting!

```c
void printtabs(int depth) {
    for (int i = 0; i < depth; i++) {
        printf("|   ");
    }
}

void debug_list_inner(C *l, int depth) {
    if (l->type == LABEL) {
            printtabs(depth);
            printf("LABEL- Address: %p, Value: %s Next: %p\n",
            l,
            l->val.label,
            l->next);
            debug_list_inner(l->next, depth );
    } else if (l->type == LIST) {
            printtabs(depth);
            printf("LIST- Address: %p, List_Value: %p Next: %p\n",
            l,
            l->val.list,
            l->next);
            debug_list_inner(l->val.list, depth + 1);
            debug_list_inner(l->next, depth);
    } else if (l->type == NIL) {
            printtabs(depth );
            printf("NIL- Address: %p\n", &nil);
            printtabs(depth - 1);
            printf("-------------------------------------------------------\n");
    }
}

void debug_list(C *l) {
    printf("\n");
    debug_list_inner(l, 0);

}
```

Notice I'm also wrapping the main loop in a convenience function so that I still
interface with it the same way, since the initial call to `debug_list_inner()`
will always start with a depth of 0.

LHOOQ!

```c
LIST- Address: 0x7fd02ac03500, List_Value: 0x7fd02ac034e0 Next: 0x10aab3020
|   LABEL- Address: 0x7fd02ac034e0, Value: let Next: 0x7fd02ac034c0
|   LABEL- Address: 0x7fd02ac034c0, Value: us Next: 0x7fd02ac034a0
|   LIST- Address: 0x7fd02ac034a0, List_Value: 0x7fd02ac033f0 Next: 0x7fd02ac03480
|   |   LABEL- Address: 0x7fd02ac033f0, Value: consider Next: 0x10aab3020
|   |   NIL- Address: 0x10aab3020
|   -------------------------------------------------------
|   LABEL- Address: 0x7fd02ac03480, Value: words Next: 0x7fd02ac03460
|   LABEL- Address: 0x7fd02ac03460, Value: not Next: 0x7fd02ac03440
|   LABEL- Address: 0x7fd02ac03440, Value: chars Next: 0x10aab3020
|   NIL- Address: 0x10aab3020
-------------------------------------------------------
NIL- Address: 0x10aab3020
-------------------------------------------------------
```

Now it is a lot easier, visually, to see the groupings of each list. Try this!


```c
int main() {
    C *a_list = read("(here (is (another (more deeply) nested) list))");
    debug_list(a_list);
    return 0;
}
```

```c
LIST- Address: 0x7fb472c03570, List_Value: 0x7fb472c03550 Next: 0x107b6f020
|   LABEL- Address: 0x7fb472c03550, Value: here Next: 0x7fb472c03530
|   LIST- Address: 0x7fb472c03530, List_Value: 0x7fb472c03510 Next: 0x107b6f020
|   |   LABEL- Address: 0x7fb472c03510, Value: is Next: 0x7fb472c034f0
|   |   LIST- Address: 0x7fb472c034f0, List_Value: 0x7fb472c034a0 Next: 0x7fb472c034d0
|   |   |   LABEL- Address: 0x7fb472c034a0, Value: another Next: 0x7fb472c03480
|   |   |   LIST- Address: 0x7fb472c03480, List_Value: 0x7fb472c03430 Next: 0x7fb472c03460
|   |   |   |   LABEL- Address: 0x7fb472c03430, Value: more Next: 0x7fb472c03410
|   |   |   |   LABEL- Address: 0x7fb472c03410, Value: deeply Next: 0x107b6f020
|   |   |   |   NIL- Address: 0x107b6f020
|   |   |   -------------------------------------------------------
|   |   |   LABEL- Address: 0x7fb472c03460, Value: nested Next: 0x107b6f020
|   |   |   NIL- Address: 0x107b6f020
|   |   -------------------------------------------------------
|   |   LABEL- Address: 0x7fb472c034d0, Value: list Next: 0x107b6f020
|   |   NIL- Address: 0x107b6f020
|   -------------------------------------------------------
|   NIL- Address: 0x107b6f020
-------------------------------------------------------
NIL- Address: 0x107b6f020
-------------------------------------------------------
```

<hr>

Now I have a program that can take an arbitrary string of arbitrarily nested
parenthetical expressions and turn it into an abstract syntax tree that's
represented in memory in a structured way. It doesn't handle malformed input
very well, and I can't do much with the structure I've read in yet, but this is
really great!
