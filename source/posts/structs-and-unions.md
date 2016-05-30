---
title: Structs and Unions
date: 2016-05-30
layout: post
tags: rc
---

C has a variety of [built in data
types](https://en.wikipedia.org/wiki/C_data_types). But let's pick just two to
mess around with: a `long long int` and a `char`.

A `long long int` (or just `long long`) is specified to be at _least_ 64 bits
in size. That means that if we call `sizeof` on it, we should get at _least_ 8
bytes, since 8 * 8 = 64.

```c
#include <stdio.h>

int main() {
    long long x;
    printf("%lu", sizeof(x));
    return 0;
}
```

Sure enough, this outputs:

```
8
```

A `char` is, by its name, one 'character'... but this is a bit misleading. In
ye olden days, a character was never more than one byte long, since the [ascii
standard](http://www.asciitable.com/) specified only a very small set of
symbols, and they could all be accomodated in a single byte. Nowadays, a more standard
encoding is [Unicode](https://www.youtube.com/watch?v=MijmeoH9LT4), in which
many thousands of symbols can be represented by strings of bytes of somewhat
arbitrary length. It is no longer accurate, then, to say that a `char`, in the
sense of "character", is only one byte long, but the naming convention persists
in C, and the `char` _type_ **is** always one byte long. It would
be drastically more accurate to call that type a `byte`, but here we are.

```c
#include <stdio.h>

int main() {
    char x;
    printf("%lu", sizeof(x));
    return 0;
}
```

yields:

```
1
```

Structs
-------

A struct is a way for the programmer to bundle types together in one
_structure_. Let's say we wanted to represent a point in two dimensional space,
for example. A point is fully articulated when we have both an x value and a y
value. A `Point` struct might look like this:

```c
struct Point {
    int x;
    int y;
};
```

We coud then use `struct Point` to declare a point variable just like any other type.

```c
struct Point x;
```

How big is `x`, now, do you think? a `struct Point` contains two ints. How big is an int?

```c
#include <stdio.h>

int main() {
    int x;
    printf("%lu", sizeof(x));
    return 0;
}
```

```
4
```

Looks like it is four bytes long. A `struct Point`, then, should be 8 bytes long, right?

```c
#include <stdio.h>

struct Point {
    int x;
    int y;
};

int main() {
    struct Point x;
    printf("%lu", sizeof(x));
    return 0;
}
```

And indeed it is.

```
8
```

What about a point in 5 dimensional space? We would need 5 `int`s to fully
specify such a point, right?

```c
#include <stdio.h>

struct Point {
    int x;
    int y;
    int z;
    int a;
    int b;
};

int main() {
    struct Point x;
    printf("%lu", sizeof(x));
    return 0;
}
```

If you're guessing this is 20 bytes long, well pat yourself on the back!

```
20
```

Normally, when we declare a var, we can simply assign a value to it like this:

```c
int x;
x = 5;
```

Or even initialize it at the time of declaration:

```c
int x = 6;
```

For structs, we can do the same type of thing! Let's look at that 2d point again.

```c
struct Point {
    int x;
    int y;
};
```

Those `x` and `y` values are referred to as _members_ of that struct. To access
them for reading or writing, we can use dot notation.

```c
struct Point mypoint;
mypoint.x = 2;
mypoint.y = 5;
```

Now, `mypoint` is fully initialized, and equal to the point `(2, 5)` in regular
notation. You could do this in any order.

What about initializing the struct at the time of declaration, in one line?
That looks like this, with an inlined static array:

```c
struct Point mypoint = { 2, 5 };
```

If you simply list the member values in order like that, it will work, but you
can also specify which one is which by being explicit:

```c
struct Point mypoint = { .y = 5, .x = 2 };
```

<hr>

Let's go back to those two types from the beginning. What if we wanted a
`struct` that contained one of each?

```c
struct Thingy {
    char letter;
    long long number;
};
```

Who knows why we would need that, but whatever. The size of this struct in
memory is going to be equal to the sum of its members' sizes. So a `char` (1
byte) plus a `long long` (8 bytes), so 9 bytes.

```c
#include <stdio.h>

struct Thingy {
    char letter;
    long long number;
};

int main() {
    struct Thingy x;
    printf("%lu", sizeof(x));
    return 0;
}
```

Outputs:

```
16
```

Wait huh? This actually surprised me when I was writing this post! Because a
`long long` is 8 bytes long, the `char` member must be offset by the same
distance for optimizations! The 'true size' of the `letter` member is still
just one byte, but the space the member must take up in memory is now 8 bytes.
I do not fully understand this yet, but it looks like [this
document](http://c-faq.com/struct/align.esr.html) explains the historical
context and reasoning. Interesting! There appears to be some [black
magic](http://stackoverflow.com/questions/14332633/attribute-packed-v-s-gcc-attribute-alignedx)
that will force the compiler to do that without padding, but in the
absence of a very good reason, this seems unneccesary.

Unions
------

`union` types look and behave an awful lot like `struct`s do, syntactically, but
there is a very important difference. Whereas structs are a collection of
members that are assembled together in memory side by side, `unions` can _only ever contain
one of their members at any one time_. As such, a union type will be the size of its
_largest_ member, in order to accomodate the biggest thing it will ever need to hold.

```c
union Thingy {
    int x;
    int y;
};
```

`Thingy` looks like it has two `ints` inside of it. If this were a `struct`, it
would, and it would need to be as big as two ints to hold both of them! But
since this is a union, it will only ever need to hold one or the other.

```c
int main() {
    union Thingy myunion;
    printf("%lu", sizeof(myunion));
    return 0;
}
```

Will output: `4`! In fact, so will this:

```c
union Thingy {
    int x;
    int y;
    int a;
    int b;
    int c;
    int d;
    int e;
    int f;
};

int main() {
    union Thingy myunion;
    printf("%lu", sizeof(myunion));
    return 0;
}
```

You get the idea!

<hr>

Let's look at a weird thing about unions!

```c
#include <stdio.h>

union Thingy {
    int x;
    int y;
};

int main() {
    union Thingy myunion = { 156 };
    printf("%i\n", myunion.x);
    printf("%i\n", myunion.y);
    return 0;
}
```

Outputs:

```c
156
156
```

Because `myunion.x` and `myunion.y` are referencing the _exact same memory
space_. Because they are both `int`s, this is fine!

How about this one?

```c
union Thingy {
    char letter;
    long long number;
};

int main() {
    union Thingy myunion;
    printf("%lu", sizeof(myunion));
    return 0;
}
```

No surprise this time! Because a `long long` is by far the largest member of
this `union`, an instance of this type will have a size that is the same as the
`long long`, which is 8.

```
8
```

I will leave you with this bit of weirdness.

```c
#include <stdio.h>

union Thingy {
    char letter;
    long long number;
};

int main() {
    union Thingy myunion;

    myunion = (union Thingy){ .letter = '!' };
    printf("%c\n", myunion.letter);  // !
    printf("%lli\n", myunion.number); // 33

    myunion = (union Thingy){ .number = 33 };
    printf("%c\n", myunion.letter);  // !
    printf("%lli\n", myunion.number); // 33

    return 0;
}
```
All of these are just different ways to organize and get at the exact same
data. In every case above, the same memory is being assigned the same values,
but we're accessing it and interpreting it in different ways.
