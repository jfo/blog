---
title: Sild part 1
layout: post
---

If I'd like to write a lisp, where would I start?

Lisp stands for "list processor," so I'll start with lists.

<hr>

A list is a series of cells that have two things in them: a value, and an
address for the next cell in the list. I'll start with creating a struct that
can hold those two things, and I'll call it a `Cell`:

```c
struct Cell {
    int value;
    struct Cell * next;
};
```

For now, let's say that the value has to be an `int`. I could assign values to
a cell like this:

```c
int main() {
    struct Cell a_cell; // declare a_cell to be a Cell
    a_cell.value = 1; // initialize the Cell's value
    a_cell.next = 0x0; // point to the next Cell (in this case, the null pointer)

    printf("a_cell's value is: %d\n", a_cell.value);
    printf("the next cell after a_cell is: %p", a_cell.next);
}
```

That dot notation is used to access the `members` of the struct. In this case,
there is no next cell, so ```a_cell.next``` is the `NULL` pointer, which is
zero. This is a list of one element. Let's make a second cell.

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

Now, `a_cell.next` is being assigned to `&another_cell`. Which is
taking the address of `another_cell`. There is now a reference to
`another_cell` contained in `a_cell`, and the two cells are _linked_.
This is why this structure is called a `linked list`.

I should be able to get to `another_cell`'s values _through_ the first
cell, and I can, and it looks like this:

```c
printf("another_cell's value is: %d\n", a_cell.next->value);
printf("the next cell after another_cell is: %p", a_cell.next->next);
```

Notice how that is different... I say "tell me where the next cell after
```a_cell``` lives" with ```a_cell.next```, and I say "give me its value" with
`->value`

TODO: WRITE ABOUT THE ARROW NOTATION.

This is a very simple data structure, but you can do a lot with it! Here is a
function that takes a cell and prints it's value:

```c
void print_cell(struct Cell car) {
    printf("%d ", car.value);
}
```

But this only does a single cell. What If I want to print a whole list? I could
do something like this:

```c
void print_list(struct Cell car) {
    printf("%d ", car.value);
    print_list(*car.next);
}
```

Notice that `car.next` is a pointer, and ```print_list``` is expecting not a
pointer to a cell, but an _actual cell_ to be passed into it. The ```*```
operator takes a pointer and `dereferences` it, which means represents not
just the address of a thing but the _actual_ thing.

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

> That hotel is the heap. Once you've allocated memory on the heap, it's your's
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
is enough? I could figure that out by adding the size of an int to the sizeof a
pointer (which is what a cell contains), but it's easier to use `sizeof()` to
do it for me, and I don't have to change it if I add more members to the struct
later on (which I definitely will).

On success, `malloc()` returns a pointer to that allocated memory. I've told my
program we're treating it as a pointer to a Cell. The next two lines simply
assign the members of the new cell the values that I passed in, and then I
return the pointer. That's it. The memory has been allocated on the heap
instead of the stack frame of that particular function call, and so it is
persistent (at least until I tell it otherwise). I can count on that data being
at that address for as long as I like.

I'll need to modify `print_list()` to accept and operate on a pointer instead
of an object, but everything pretty much stays the same other than adding some
`*` and changing dots to arrows:

```
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
