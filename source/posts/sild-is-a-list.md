---
title: Sild - is... a list?
layout: post
date: 2016-06-6
tags: rc
---

This is the first post in a series of posts that start from nothing and end up
with a lisp interpreter. I tried very hard to keep my commits atomic
and in parity with these posts, and for the most part I think I did that fairly
well. You can start from [the first few
commits](https://github.com/urthbound/sild/commits/master?page=7) if you want
to follow along and see the growth of the language along with these posts, but
I won't be linking to particular commits along the way.

<hr>

Where would I start, if I'd like to write a lisp?

LISP stands for "list processor," so I suppose I should start with lists.

What is a list? A list is a sequential collection of somethings or anothers.
Let's call these somethings or others "cells" for now.

So, a "list" is a sequential collection of "cells". So what is a cell? I could
say that a cell is a something or another, and that wouldn't be a _lie_
exactly, but it's not very helpful, is it? Or maybe it is helpful... certainly
a cell is a something... let's say that something could be a number. So, a cell
is a number!

But how do we get the next thing in the list? We could put all the things in
the list next to each other in memory, and this would make it easy to find the
next cell- we could just look to the next slot in memory and there we would
find it. This is actually _not_ a list... this is an _array_. It is similar,
but not the same.

A list is a collection of sequential cells; a cell is a something _and_ another.

A _something_ is a number, then _another_ would be the next cell in the list.

So, cells have two things in them: a value, and an address for the next cell in
the list. Let's make a cell, in C. I'll start with creating a struct that can
hold those two things, and I'll call it a `Cell`:

```c
struct Cell {
    int value;
    struct Cell *next;
};
```

If you don't know what a struct is, [I wrote about them
here](/structs-and-unions/).

I could assign values to a cell like this:

```c
int main() {
    struct Cell a_cell; // declare a_cell to be a Cell
    a_cell.value = 1;   // initialize the Cell's value
    a_cell.next = 0x0;  // point to the next Cell (in this case, the null pointer)

    printf("a_cell's value is: %d\n", a_cell.value);
    printf("the next cell after a_cell is: %p", a_cell.next);
}
```

That dot notation is used to access the `members` of the struct. In this case,
there is no next cell, so `a_cell.next` is the `NULL` pointer, which is
zero. This is a _list_ of one cell. Let's make a second cell.

```c
int main() {
    struct Cell another_cell;
    another_cell.value = 2;
    another_cell.next = 0x0;

    struct Cell a_cell;
    a_cell.value = 1;
    a_cell.next = &another_cell;

    printf("a_cell's value is: %d\n", a_cell.value);
    printf("the next cell after a_cell is: %p, which is called another_cell\n", a_cell.next);
    printf("another_cell's value is: %d\n", another_cell.value);
    printf("the next cell after another_cell is: %p", another_cell.next);
}
```

Now, `a_cell.next` is being assigned to `&another_cell`. Which is taking the
address of `another_cell`. There is now a reference to `another_cell` contained
in `a_cell`, and the two cells are _linked_.  That is why this structure is
called a `linked list`. It consists of cells that are _linked_ together.

I should be able to get to `another_cell`'s values _through_ the first
cell, and I can, and it looks like this:

```c
printf("another_cell's value is: %d\n", a_cell.next->value);
printf("the next cell after another_cell is: %p", a_cell.next->next);
```

Notice how that is different... I say "tell me where the next cell after
```a_cell``` lives" with ```a_cell.next```, and I say "give me its value" with
`->value`

We use the `.` notation when we are operating directly on structs, and we use
the `->` notation when we are operating on a _pointer_ to a struct. The reasons
for this are historic, and [this fantastic stack overflow
    answer](http://stackoverflow.com/questions/13366083/why-does-the-arrow-operator-in-c-exist)
explains why in great detail, if you are interested.

This linked list of cells is a very simple data structure, but you can do a
whole lot with it! Here is a function that takes a cell and prints it's value:

```c
void print_cell(struct Cell car) {
    printf("%d ", car.value);
}
```

But this only prints a single cell. What If I want to print a whole list? I could
do something like this:

```c
void print_list(struct Cell car) {
    printf("%d ", car.value);
    print_list(*car.next);
}
```

Notice that `car.next` is a pointer, and ```print_list``` is expecting not a
pointer to a cell, but an _actual cell_ to be passed into it. The ```*```
operator takes a pointer and `dereferences` it, which means it returns not just
the address of a thing but the _actual_ thing.

If I try to run ```print_list(a_cell)``` though, this dies, because though it
succeeds in passing the first  two cells through the function, when it tries to
dereference the null pointer (`0x0`) that the second cell is still pointing to, it blows
up. I can fix this for now by wrapping that recursive call in a null pointer check:

```c
void print_list(struct Cell car) {
    printf("%d ", car.value);
    if (car.next) {
        print_list(*car.next);
    }
}
```

Now, I have a cell structure that I can build into a list, and I have a simple
function that can do something with that list. Progress! :D

> Did you know you can also initialize a struct in one line by passing a block
> of constructor args to it? It's true! And it looks like this:

> ```c
> struct Cell another_cell = { 2, 0x0 };
> struct Cell a_cell = { 1, &another_cell };
> ```

> It's order dependant, so the first argument is the `value` and the second
> argument is a pointer to another cell, just like in the struct declaration.

<hr>

C is... not an Object Oriented language with capital O's. But often, you can
squint your eyes, think of structs as objects, and get away with it. They
certainly fulfill a lot of the the same roles, at least! It is useful to have
constructor functions for objects, so it is also useful to have constructor
functions for structs. Here is one:

```c
struct Cell makecell(int value, struct Cell *next) {
    struct Cell outcell = { value, next };
    return outcell;
};
```

Great! Now I can abstract away that creation and assignment, like this, which
totally works.

```c
int main() {
    struct Cell another_cell = makecell(2, 0x0);
    struct Cell a_cell = makecell(1, &another_cell);

    print_list(a_cell);
}
```

But all is not well just yet. `makecell()` returns a cell, so I should be able
to inline this whole thing by creating the next cell at the same time as the
first one, like so:

```c
int main() {
    struct Cell a_cell = makecell(1, &makecell(2, 0x0));
    print_list(a_cell);
}
```

But this fails! With a hella cryptic error message:

```
sild.c:22:38: error: cannot take the address of an rvalue of type 'struct Cell'
     struct Cell a_cell = makecell(1, &makecell(2, 0x0));
                                      ^~~~~~~~~~~~~~~~~
```

What the hell is an `rvalue`? I've found conflicting definitions, so rather than
attempt to find a definitive answer here, I'll use the most plausible and simplest.

Consider an assignment expression that looks like this:

```c
int var = 1;
```

Or, more generally:

```c
type var = value
```

the `value` on the right is an `rvalue`, it has some value, but does not take
up space in memory. In fact, giving that value a place in memory is exactly
what we're doing by assigning it to a variable.

I'll give you one guess what `var` is called in this expression. Yup, `lvalue`,
for "left value".  You can also think of it as standing for "location value",
which is a useful mnemonic, since we're giving that variable a location by
declaring it (recall that variable declaration sets aside the amount of space
you need for whatever type you're declaring).

So, an `lvalue` has a location in memory, and an `rvalue` is anything else
that does _not_ have a location in memory. It makes perfect sense, then, that you
can't take the address of a thing that doesn't take up space! But why doesn't
it take up space? Because `makecell()` is returning the _literal data_ that
makes up a struct of type Cell. It's basically the same thing as trying to take
the address directly of an integer, which makes no sense! And in fact, if we
try to do so with `&1000` or something, we get the very same error:

```
sild.c:22:5: error: cannot take the address of an rvalue of type 'int'
    &1000;
    ^~~~~
```

This is a little bit contrived, at this point. You might say- well just don't
do that! Assign the output of `makecell` to a var before taking the address of
it! But this doesn't really make much sense... now I'm allocating memory twice
for the same structure. Once in `makecell()` itself, and once in `main()`, and
presumably I would run into more opportunities for reallocating stack memory to
pass around the whole cell later on, and, and and...

This isn't great. allocating and managing memory takes computational time, even
if the program is doing the heavy lifting. I don't want to make a Cell and
then pass the values around wholesale like that, copying them and erasing
them a bunch of times, I want to make the Cell once, and then pass around a
reference to the Cell in the form of the address of where I put it. I don't
want to _pass by value_, I want to _pass by reference_!

> My dad's friends always send him viral videos. But they don't send youtube or
> vimeo links, they send the entire video file along in the email! Everyone who
> gets the mail has to download a copy of the video... everytime the email is
> transmitted, all the data that constitutes the video goes with it. It gets
> copied hundreds of times! Isn't it easier to just send a URL to a youtube
> video? Then the data in the email is very small, but you still get
> to watch the
> [video](https://www.youtube.com/watch?v=8F9jXYOH2c0&app=desktop). Also less viruses.

> This is the same as the difference between _pass by value_ (copying the video
> each time the email is sent) and _pass by reference_ (the "reference" being the
> address of the video, or the memory address of the structure you're referring
> to.)

<hr>

I can modify `makecell()` to return a pointer (which is an address) to the Cell
I've created instead of the cell itself, like this:

```c
struct Cell *makecell(int value, struct Cell *next) {
    struct Cell outcell = { value, next };
    return &outcell;
};
```

But if I try to call it with `makecell(1, 0x0)`, I get another, different warning.

```
sild.c:17:13: warning: address of stack memory associated with local variable 'outcell' returned [-Wreturn-stack-address]
    return &outcell;
           ^~~~~~~
```

I returned an address, why is the compiler complaining? Because I returned the
address that the Cell inside of `makecell()` was given. But that's what I
wanted to do! To understand why this is problematic, we have to know the difference between

<h3>the stack and the heap</h3>

This is a pretty big subject, but for our purposes right now, the main thing we have to understand is this:

> The stack is memory that is managed by the program.
>
> The heap is memory that is managed by the programmer.

When `makecell()` is called, memory space is set aside for its execution, on
the stack. This will include any arguments passed into it and any variables
declared within its scope. It computes whatever it's supposed to, and returns
whatever it returns, and when it's done, all the space that was set aside for
its use is _freed_ by the program. Once the memory is freed, it can be reused
for anything else that's being executed, and likely will be reused, very
quickly. The contents of the address that `makecell()` returned, then, are
completely unreliable. It _could_ be the data that was stored there during
the execution of the function, but it almost definitely isn't. We need a
more durable home for each cell that we create, with a persistent address, and
for that, we'll need `malloc()`.

<hr>

`malloc()` means 'memory allocation'. It's a C standard library function that
takes one argument, the size of the memory block you are requesting from the
system, and returns a pointer to the block that you were given. Think of
`malloc()` like a hotel front desk clerk. You say: "Hi Mr. Malek, I would like
a room please," and `malloc()` goes back and checks if they have the kind of
room you wanted. If they do, it will give you the address of the room. If they
don't, if the hotel is full, you get 'nothing' back, in the form of the null pointer.

> That hotel is the heap. Once you've allocated memory on the heap, it's yours
> for the remainder of the program's execution. You must _manually_ free the
> memory by passing the address of it to `free()`, the yang to malloc's yin.
> Failure to properly manage heap memory, say by forgetting to free memory that
> you've allocated, results in particularly nasty things, like memory leaks. In
> a long running program, you can just _run out_ of memory if you have
> processes that keep requesting allocations without freeing the ones that
> they're done with.

I'll modify `makecell()` to use malloc

```
struct Cell *makecell(int value, struct Cell *next) {
    struct Cell *outcell = malloc(sizeof(struct Cell));
    outcell->value = value;
    outcell->next = next;
    return outcell;
};
```

I start now by requesting enough space on the heap for a cell. How much space
is enough? I can figure that out by using `sizeof()`.

On success, `malloc()` returns a pointer to that allocated memory. I've told my
program we're treating it as a pointer to a Cell. The next two lines simply
assign the members of the new cell the values that I passed in, and then I
return the pointer. That's it. The memory has been allocated on the heap
instead of the stack frame of that particular function call, and so it is
persistent (at least until I tell it otherwise). I can count on that data being
at that address for as long as I like.

I'll need to modify `print_list()` to accept and operate on a pointer instead
of an object, but everything pretty much stays the same other than adding some
`*`'s and changing dots to arrows:

```c
void print_list(struct Cell *car) {
    printf("%d ", car->value);
    if (car->next) {
        print_list(car->next);
    }
}

int main() {
    struct Cell *a_cell = makecell(1, makecell(2, 0x0));
    print_list(a_cell);
}
```

<hr>

I'll end by tightening things up a little bit. First, I'll add a typedef to the
Cell struct and refer to it simply as C. This way, I can refer to it directly
as `C` instead of `struct Cell`. This structure is used all over the place, and
shortening it is an easy win for readibility. I'll also one line the member
assignments in the `makecell()` function. I don't really have a good reason for
this other than it feels good to me. I will likely split these up later on
again, but for now, here's how the whole program looks so far, notice I've
`#include`d `stdio.h` for `printf()` and `stdlib.h` for `malloc()`:

```c
#include <stdio.h>
#include <stdlib.h>

typedef struct C {
    int val;
    struct C * next;
} C;


void print_list(C *car) {
    printf("%d ", car->val);
    if (car->next) {
        print_list(car->next);
    }
}

C *makecell(int val, C *next) {
    C *out = malloc(sizeof(C));
    out->val = val; out->next = next;
    return out;
};


int main() {
    C *a_cell = makecell(1, makecell(2, NULL));
    print_list(a_cell);
    return 0;
}
```

As written, this program prints out.

```
1 2
```

And now we have a linked list.
