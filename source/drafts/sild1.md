---
title: Sild part 1
layout: post
---

If I'd like to write a lisp, where would I start?

Lisp stands for "list processor," so I'll start with lists.

<hr>

A list is a series of cells that have two things in them: a value, and an
address for the next cell in the list. I'll start with creating a struct that
can hold those two things, and I'll start by calling it a `Cell`:

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
    struct Cell a_cell;
    a_cell.value = 1;
    a_cell.next = 0x0;

    printf("a_cell's value is: %d\n", a_cell.value);
    printf("the next cell after a_cell is: %p", a_cell.next);
}
```

The dot notation is used to access the `members` of the struct. In this case,
there is no next cell, so ```a_cell.next``` is the `NULL` pointer. This is a
list of one element. Let's make a second cell.

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

Now, ```a_cell.next``` is being assigned to ```&another_cell```. Which is
taking the address of another_cell. There is now a reference to
`another_cell` contained in `a_cell`, and the two cells are _linked_.
This is why this structure is called a `linked list`.

I should be able to get to ```another_cell```'s values _through_ the first
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

