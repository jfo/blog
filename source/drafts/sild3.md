---
title: Sild3 actual lists
layout: post
---

So far I've made a linked list whose cells have an arbitrary string as their
value. I can read in an input string and turn it into a linked list of words,
like this:

```c
int main() {
    C *a_list = read("here are some words");
    debug_list(a_list);
    return 0;
}
```

Gives me a series of cells like this:

```
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

```
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
    out->val = val; out->next = next;
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
prints `(nul)`.

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

I'm calling the string `val` members a _label_, which is the type of atom that
they are.

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

I'll of course have to add these type to both the makecell function:

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

`LABEL` is still a constant that represents `0` and `LIST` is still one that
represents `1`, this is just an easier, and more extensible, way to do that.

<hr>

This struct is becoming unwieldy.
