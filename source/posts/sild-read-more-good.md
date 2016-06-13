---
title: Sild - read more good
layout: post
date: 2016-06-13
tags: rc
---

There is a complexity problem with my program!

I want to iterate over each character as few times as possible in
order to read them in. How many times am I iterating over them now?

To find out, I'll add an `inner_reads` global var and initialize it
to 0. As a reminder, you can see this code in its working form in the repo,
right about
[here](https://github.com/urthbound/sild/commit/1c9d7a9d14ddf5f7cedca0f749ddc51f4e9624be).

```c
int inner_reads = 0;
```

I'll add an increment to that variable each place where a char is
being accessed: Once in:

```c
char *read_substring(char *s) {
    int len = count_substring_length(s);
    char *out = malloc(len);
    for (int i = 0; i < len; i++) {
        if (s[i] == 'i')
            inner_reads++;

        out[i] = s[i];
    }
    out[len] = '\0';
    return out;
};
```

once in:

```c
int count_substring_length(char *s) {
    int i = 0;
    while (s[i] != ' ' && s[i] != '\0' && s[i]!= ')') {

        if (s[i] == 'i')
            inner_reads++;

        i++;
    }
    return i;
}
```

and once in

```c
int count_list_length(char *s) {
    int depth = 1;
    int i = 1;
    while (depth > 0) {

        if (s[i] == 'i')
            inner_reads++;

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

Notice I'm just incrementing on the character `i`, so that I can see how many times I access just that one char, like this:


```c
int main() {
    C *a_list = read("i");
    debug_list(a_list);
    printf("%i", inner_reads);
    return 0;
}
```

This prints out:

```c
LABEL- Address: 0x7f99684033d0, Value: i Next: 0x104197028
NIL- Address: 0x104197028
-------------------------------------------------------
3
```

Ok, so that's not so so bad... I look at that char 3 separate times.
Once in `read_substring()` when it calls `count_substring_length()` to figure
out how much memory to `malloc` for the output, once when it actually copies
over the substring to the memory that has been `malloc`'d, and one final time
in the main read function when it calls `count_substring_length()` to know how
far to jump ahead in the input string. That, I can live with. But what about
`count_list_length()`?


```c
int main() {
    C *a_list = read("(((((((((((i)))))))))))");
    debug_list(a_list);
    printf("%i", inner_reads);
    return 0;
}
```

yields:

```c
LIST- Address: 0x7fde4b403540, List_Value: 0x7fde4b403520 Next: 0x100186028
|   LIST- Address: 0x7fde4b403520, List_Value: 0x7fde4b403500 Next: 0x100186028
|   |   LIST- Address: 0x7fde4b403500, List_Value: 0x7fde4b4034e0 Next: 0x100186028
|   |   |   LIST- Address: 0x7fde4b4034e0, List_Value: 0x7fde4b4034c0 Next: 0x100186028
|   |   |   |   LIST- Address: 0x7fde4b4034c0, List_Value: 0x7fde4b403490 Next: 0x100186028
|   |   |   |   |   LIST- Address: 0x7fde4b403490, List_Value: 0x7fde4b403470 Next: 0x100186028
|   |   |   |   |   |   LIST- Address: 0x7fde4b403470, List_Value: 0x7fde4b403450 Next: 0x100186028
|   |   |   |   |   |   |   LIST- Address: 0x7fde4b403450, List_Value: 0x7fde4b403430 Next: 0x100186028
|   |   |   |   |   |   |   |   LIST- Address: 0x7fde4b403430, List_Value: 0x7fde4b403410 Next: 0x100186028
|   |   |   |   |   |   |   |   |   LIST- Address: 0x7fde4b403410, List_Value: 0x7fde4b4033f0 Next: 0x100186028
|   |   |   |   |   |   |   |   |   |   LIST- Address: 0x7fde4b4033f0, List_Value: 0x7fde4b4033d0 Next: 0x100186028
|   |   |   |   |   |   |   |   |   |   |   LABEL- Address: 0x7fde4b4033d0, Value: i Next: 0x100186028
|   |   |   |   |   |   |   |   |   |   |   NIL- Address: 0x100186028
|   |   |   |   |   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   |   |   |   |   NIL- Address: 0x100186028
|   |   |   |   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   |   |   |   NIL- Address: 0x100186028
|   |   |   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   |   |   NIL- Address: 0x100186028
|   |   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   |   NIL- Address: 0x100186028
|   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   NIL- Address: 0x100186028
|   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   NIL- Address: 0x100186028
|   |   |   |   -------------------------------------------------------
|   |   |   |   NIL- Address: 0x100186028
|   |   |   -------------------------------------------------------
|   |   |   NIL- Address: 0x100186028
|   |   -------------------------------------------------------
|   |   NIL- Address: 0x100186028
|   -------------------------------------------------------
|   NIL- Address: 0x100186028
-------------------------------------------------------
NIL- Address: 0x100186028
-------------------------------------------------------
14
```

The way I've got this written now, when a string is nested inside
other lists, it gets examined 3 times for the actual reading of the
string and _once more_ for _each_ list that it is nested inside. This
is _really crappy_, and it means that for a string like

```c
"(((((((((((i)))))))))))"
```

The `i` char in the middle is being accessed _fourteen_ times. This
isn't including looking at all the parenthethes chars, either!

I can do better than this. At the very least, I want to be assured
that, no matter what the nesting structure, each char will only ever
be examined the same number of times!

<hr>


Well, it turns out that I can get rid of the `count_list_length()` function
_completely_ by changing the way I approach the `read()` function itself!

Right now, `read()` operates on a pointer to the head of a string.
When you pass this pointer into the function, it creates a local copy
of that value and binds it to the argument name in the function
signature. Which only exists until the end of the function. So, for
example:

```c
int derp(int local_i) {
    local_i++;
    return local_i;
}

int i = 10;
printf("%i", i); // 10
printf("%i", derp(i)); // 11
printf("%i", i); // 10
```

Further, if I call `derp()` inside of itself, I am still not affecting
anything outside of the current function call.

```c
int i = 10;

printf("%i", i); // 10

int derp(int local_i) {
    local_i++;
    if (local_i < 100) // have to have a base case or it will go on forever!
        derp(local_i);
    return local_i;
}

printf("%i", derp(i)); // 11
printf("%i", i); // 10
```

Avoiding complex global state is almost always a Good Thing. This
seems like the expected behavior! We want the stuff that happens
inside `derp()` to _stay there_, and not touch the global state,
normally. But in the case of the `read()` function, because it is so
recursive, it is much cleaner to have it operate on a _pointer to a
pointer_ instead of the pointer itself. This way, instead of copying
the pointer each time the function is called, it copies a _pointer_ to
it, and you can operate _directly_ on the pointer value itself, incrementing
it regardless of how many stack frames you are inside!

So,

```c
int derp(int *local_i) {
    (*local_i)++;
    return *local_i;
}

int i = 10;
printf("%i\n", i);        // 10
printf("%i\n", derp(&i)); // 11
printf("%i\n", i);        // 11
```

Now, the increment of the pointer inside the function affects the
actual value itself, not the local copy.

How does this look in the read function? Well it looks like this:

```c
C * read(char **s) { // **s is a 'pointer to a pointer', in this case a pointer to a string
    switch(**s) {    // dereferencing the pointer twice yields the actual char it points to (two levels of indirection)
        case '\0': case ')':
            (*s)++;              // increment the pointer at the end of a list
            return &nil;
        case ' ': case '\n':
            (*s)++;              // increment the pointer after ignoring whitespace
            return read(s);
        case '(':
            (*s)++;              // increment the pointer after starting a list

            // this is the magic part! the first call to read increments the pointer as it goes
            // so that when what looks like the same pointer is passed into the second call, it has
            // already passed by the entirety of the list!
            return makecell(LIST, (union V){.list = read(s)}, read(s));
            //                                         ^          ^
            //                                 so the 1st call & 2nd call are starting in different places!
        default: {
            // this part works like it did before, but we're guaranteed to never
            // read a char more than the 3 times necessary to make a copy and then jump over it.
            char *label_val = read_substring(*s);
            (*s) += count_substring_length(*s);
            return makecell(LABEL, (union V){.label = label_val}, read(s));
        }
    }
}
```

NOW WATCH THIS

```c
int main() {
    char *a_string = "(((((((((((i)))))))))))";
    C *a_list = read(&a_string);
    debug_list(a_list);
    printf("%i", inner_reads);
    return 0;
}
```

with this new version of `read`, returns:

```c
LIST- Address: 0x7f8c0a403540, List_Value: 0x7f8c0a403520 Next: 0x10d94a028
|   LIST- Address: 0x7f8c0a403520, List_Value: 0x7f8c0a403500 Next: 0x10d94a028
|   |   LIST- Address: 0x7f8c0a403500, List_Value: 0x7f8c0a4034e0 Next: 0x10d94a028
|   |   |   LIST- Address: 0x7f8c0a4034e0, List_Value: 0x7f8c0a4034c0 Next: 0x10d94a028
|   |   |   |   LIST- Address: 0x7f8c0a4034c0, List_Value: 0x7f8c0a403490 Next: 0x10d94a028
|   |   |   |   |   LIST- Address: 0x7f8c0a403490, List_Value: 0x7f8c0a403470 Next: 0x10d94a028
|   |   |   |   |   |   LIST- Address: 0x7f8c0a403470, List_Value: 0x7f8c0a403450 Next: 0x10d94a028
|   |   |   |   |   |   |   LIST- Address: 0x7f8c0a403450, List_Value: 0x7f8c0a403430 Next: 0x10d94a028
|   |   |   |   |   |   |   |   LIST- Address: 0x7f8c0a403430, List_Value: 0x7f8c0a403410 Next: 0x10d94a028
|   |   |   |   |   |   |   |   |   LIST- Address: 0x7f8c0a403410, List_Value: 0x7f8c0a4033f0 Next: 0x10d94a028
|   |   |   |   |   |   |   |   |   |   LIST- Address: 0x7f8c0a4033f0, List_Value: 0x7f8c0a4033d0 Next: 0x10d94a028
|   |   |   |   |   |   |   |   |   |   |   LABEL- Address: 0x7f8c0a4033d0, Value: i Next: 0x10d94a028
|   |   |   |   |   |   |   |   |   |   |   NIL- Address: 0x10d94a028
|   |   |   |   |   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   |   |   |   |   NIL- Address: 0x10d94a028
|   |   |   |   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   |   |   |   NIL- Address: 0x10d94a028
|   |   |   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   |   |   NIL- Address: 0x10d94a028
|   |   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   |   NIL- Address: 0x10d94a028
|   |   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   |   NIL- Address: 0x10d94a028
|   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   NIL- Address: 0x10d94a028
|   |   |   |   -------------------------------------------------------
|   |   |   |   NIL- Address: 0x10d94a028
|   |   |   -------------------------------------------------------
|   |   |   NIL- Address: 0x10d94a028
|   |   -------------------------------------------------------
|   |   NIL- Address: 0x10d94a028
|   -------------------------------------------------------
|   NIL- Address: 0x10d94a028
-------------------------------------------------------
NIL- Address: 0x10d94a028
-------------------------------------------------------
3
```

Only those three times!

What about:

```c
"((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((i))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))";
```

```c
|   |   |   |   |   -------------------------------------------------------
|   |   |   |   |   NIL- Address: 0x10c22f028
|   |   |   |   -------------------------------------------------------
|   |   |   |   NIL- Address: 0x10c22f028
|   |   |   -------------------------------------------------------
|   |   |   NIL- Address: 0x10c22f028
|   |   -------------------------------------------------------
|   |   NIL- Address: 0x10c22f028
|   -------------------------------------------------------
|   NIL- Address: 0x10c22f028
-------------------------------------------------------
NIL- Address: 0x10c22f028
-------------------------------------------------------
3 // <----- Boom.
```

With this tweak, I've removed a potentially major computation bottleneck and
guaranteed that the reader function will operate in linear time at a max of
O(3n), and I've completely eliminated the `count_substring_length()` function
from the source. At this point, the source code is still only 116 lines long,
and  fully 35 of those lines are devoted to the debugging code that lets me see
what I am doing!

<hr>

I feel pretty good about having this in constant time, but I can do just one
more better. I'm currently calling `count_substring_length()` twice- once in
the `read_substring()` to malloc the right amount, and again in `read()` to
jump ahead the right amount after reading a substring in. Why not just save
that value somewhere so I only have to count once?

```c
int current_substring_length = 0;
char *read_substring(char *s) {
    current_substring_length = count_substring_length(s);
    char *out = malloc(current_substring_length);
    for (int i = 0; i < current_substring_length; i++) {
        out[i] = s[i];
    }
    out[current_substring_length] = '\0';
    return out;
};
```

And then in the read function:

```c
C * read(char **s) {
    switch(**s) {
        case '\0': case ')':
            (*s)++;
            return &nil;
        case ' ': case '\n':
            (*s)++;
            return read(s);
        case '(':
            (*s)++;
            return makecell(LIST, (union V){.list = read(s)}, read(s));
        default: {
             char *label_val = read_substring(*s);
             (*s) += current_substring_length;
             //           HERE ^
             return makecell(LABEL, (union V){.label = label_val}, read(s));
        }
    }
}
```

Now I've saved a whole iteration and only need to look at each char a maximum
of two times! This can really add up. I don't think I can go any lower than
that- the initial lookahead is necessary to malloc appropriately, and I'd have
to reallocate any temporary buffer that I might use to try and get around that,
which would likely take more time to computer (and be more error prone!) than
just looking ahead for the number on each substring.

_But wait there's even more!_

I am operating on the very same pointer that I have a pointer to in the
`read()` function... why can't I use the same trick to get rid the global var
that holds the substring length? Spoiler alert I totally can.

```c
char *read_substring(char **s) {
    int current_substring_length = count_substring_length(*s);
    char *out = malloc(current_substring_length);
    for (int i = 0; i < current_substring_length; i++) {
        out[i] = **s;
        (*s)++;
    }
    out[current_substring_length] = '\0';
    return out;
};
```

I still have to pass a copy of the pointer into `count_substring_length()`, and
it's good to assign the `current_substring_length` to a _local_ var, so I only
have to count the length once for both the `malloc` and the `for` loop, but now
when I increment the pointer with `(*s)++`, I am affecting the global state of
that pointer. This means that I can remove the addition of
`current_substring_length` in the main `read()` function.

```c
C * read(char **s) {
    switch(**s) {
        case '\0': case ')':
            (*s)++;
            return &nil;
        case ' ': case '\n':
            (*s)++;
            return read(s);
        case '(':
            (*s)++;
            return makecell(LIST, (V){.list = read(s)}, read(s));
        default: {
            return makecell(LABEL, (V){read_substring(s)}, read(s));
        }
    }
}
```

Now every call to `read()` and `read_substring()` increments the global pointer
as much as it needs to as soon as it can. I have a lot less global state to
think about and don't have to worry about passing that information through all
these recursive calls!
