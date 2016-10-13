---
title: How Rust Do?
layout: post
---

Hey how tf [Rust](https://www.rust-lang.org/en-US/) do?

Ok, first I have to get Rust on my machine. I could download a binary from that
website, or I could use [homebrew](http://brewformulas.org/Rust) on my mac, or
I could use [this thing called rustup](https://rustup.rs/).

That last site looks a little spartan, but it's an [officially supported
project.](https://github.com/rust-lang-nursery/rustup.rs), so I'm going to trust it.

```
curl https://sh.rustup.rs -sSf | sh
```

If you have a healthy scepticism of running arbitrary shell scripts on your
machine (insider tip, you should totally have that!) you can check out what
that's doing
[here](https://github.com/rust-lang-nursery/rustup.rs/blob/master/rustup-init.sh).

Or alternately, you could just curl it into less or something to read it first...

```
curl https://sh.rustup.rs -sSl | less
```

This should figure out what system you're on and download the correct
installer and run it, and will create the `~/.cargo/` directory in your home
directory and populate it with some stuff.

Ok! What's in this thing anyway?

```
tree -L 2 ~/.cargo
```

```
/Users/jfowler/.cargo
├── bin
│   ├── cargo
│   ├── rust-gdb
│   ├── rust-lldb
│   ├── rustc
│   ├── rustdoc
│   └── rustup
├── env
└── registry
    ├── cache
    ├── index
    └── src

5 directories, 7 files
```

That bin directory is what we're interested in.  It will need to be on your
[path](https://www.cs.purdue.edu/homes/bb/cs348/www-S08/unix_path.html)... the
installer might be able to add this for you, but it might not have. Or you
might have to start a new shell or something to get access to these commands.

`rustup` is the version manager we're using! If the path is configured correctly,

```
rustup update
```

Should ensure you have the latest stable build! You can also run it without
args to get a help menu. That was relatively easy...

What's the other stuff?

- `cargo` is the built in package manager / task runner. I'll come back to this
  in detail. It's pretty great though.

- `rust-gdb` and `rust-lldb` are [wrappers around
  debuggers](https://michaelwoerister.github.io/2015/03/27/rust-xxdb.html)
  `gdb` and `lldb` respectively.

- `rustc` is the rust compiler. This is where we'll start.

- `rustdoc` generates documentation from inlined comments and code.

- `rustup` is the version manager.

Let's do something with rust! I'm going to write a program that produces a wave
file that's going to sound really good I promise.

mkdir
=====

```
mkdir rav
```

Rust is a compiled language, like C. A C program needs a `main` function, so
that it knows where to start when you run it, and Rust does too.

[In C](https://www.youtube.com/watch?v=yNi0bukYRnA), err... I mean, [In
C](https://en.wikipedia.org/wiki/%22Hello,_World!%22_program#History), the
classic `Hello World!` looks like this:

```c
#include <stdio.h>

main( )
{
        printf("hello, world\n");
}
```

In Rust, it looks almost exactly the same! It looks like this:

```rust
fn main() {
    println!("Hello, World!\n");
}
```

A couple of things here!

First, there is no `stdio.h` equivalent import! The compiler automatically
inserts a [prelude](https://doc.rust-lang.org/std/prelude/) that imports a lot
of useful things right off the bat.

Second, though I won't go into the differences just yet, `println!` is a
_macro_, not a function. This distinction is very important, but for now you
can just think of it like a function, as long as you keep in the back of your
head that it is a macro. It does act look a function, anyway.

We can compile that! Let's say it lives in a file called `hello.rs`

```
rustc hello.rs
```

Will compile our code and give us an executable binary called `hello`.

Run it!

```
./hello
```

And as you would expect...

```
Hello, World!
```

Hello, Rust!

Cargo
=====

Cargo is rust's package manager. It feels a lot like ruby's
[bundler](http://bundler.io/) or python's
[pip](https://pypi.python.org/pypi/pip) or javascript's
[<strike>npm</strike>](https://www.npmjs.com/)
[yarn](https://code.facebook.com/posts/1840075619545360/yarn-a-new-package-manager-for-javascript/).

That is to say, it is very easy to use, and declarative. You have a
[manifest](http://doc.crates.io/manifest.html) file written in
[toml](https://users.rust-lang.org/t/why-does-cargo-use-toml/3577/4?u=jfo) and
running cargo will keep all the dependencies installed and up to date.

But `cargo` isn't _just_ dependency management... it's also a taskrunner.
running `rustc` directly is more granular than is usually necessary, in fact!
`cargo` provides facilities to create new projects, compile them in various
modes, run tests, compile and run the project, and a whole lot more I don't
know about yet. In fact, let's scratch that `mkdir`.

```
rm -r rav
```

and instead start a project with cargo.

```
cargo new --bin rav
```

This sets up a directory structure for a project that will produce an
executable binary. The `hello world` code from above is already there, and the
build directory is ignored by default.

Try:

```
cargo run
```

This will compile the source and run the binary. It feels really smooth! I've
already added that command to my
[vim-runners](https://github.com/urthbound/vim-runners/blob/master/plugin/runners.vim#L41-L49)
plugin that I use all the time.

stdout
======

If I want to write data out of the program, I'm going to start by figuring out
how to write arbitrary data to standard out. This facility is _not_ included
with the prelude, so I'm going to have to import a thing for it.

```rust
use std::io::stdout;
```

Now with access to that, I can call `stdout()`, which is a function that
returns a 'handle' to the standard out of the current process (read, access to
the running program's environmental stdout pipe!).

This program does nothing, but will compile: 

```rust
use std::io::stdout;

fn main() {
    stdout();
}
```

With rust, I've found that just getting it to compile can be quite a challenge
sometimes, but the compiler erroring is quite verbose and will lead you down
some really interesting rabbit holes if you follow it. The fact that this
compiles is :+1:!

But of course, I actually want to write something to stdout. For that, I'll need to import another trait from the same namespace as before:

```rust
use std::io::stdout;
use std::io::Write;

fn main() {
    stdout().write("hi mom");
}
```

Because we're pulling in two things from the same module, we can inline them in
a bracketed group, bash style...

```rust
use std::io::{ stdout, Write };

fn main() {
    stdout().write("hi mom");
}
```

This doesn't compile!

```
Compiling rav v0.1.0 (file:///Users/jfowler/code/rav)
error[E0308]: mismatched types
 --> src/main.rs:5:20
  |
5 |     stdout().write("hi mom");
  |                    ^^^^^^^^ expected slice, found str
  |
  = note: expected type `&[u8]`
  = note:    found type `&'static str`
```

See what I mean about the compiler? The problem here is that the function wants
an array of `u8`s, not a static string, which is what I'm giving it. a `u8` is
the name for the unsigned 8 bit type- what in C would be a `char`, which was
always a terrible misleading name.

Strings have an `as_bytes()` method (can I call it a method? I think I'm going
to call it a method, since it implicitly passes self of whatever you're calling
it on) that will turn that string into an array of bytes. So this will compile:

```rust
use std::io::{ stdout, Write };

fn main() {
    stdout().write("hi mom".as_bytes());
}
```

So will this- apparently prefixing a string with a lowercase `b` does the same thing!

```rust
use std::io::{ stdout, Write };

fn main() {
    stdout().write(b"hi mom");
}
```

Both of these examples compile and run, but they also trigger compiler warnings:

```
Compiling rav v0.1.0 (file:///Users/jfowler/code/rav)
warning: unused result which must be used, #[warn(unused_must_use)] on by default
--> src/main.rs:5:5
|
5 |     stdout().write("hi mom".as_bytes());
|     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Finished debug [unoptimized + debuginfo] target(s) in 0.33 secs
Running `target/debug/rav`
hi mom
```

_ooooo a mystery!_

This is just a warning- it doesn't halt compilation and the program runs, but
it will become important to address this later on. It might seem a little
strange at first, really! What even is this call returning? Why is it returning
anything? The answer is pretty interesting and super important to understanding
how rust works, in particularly with regard to error handling, but I'm going to
totally ignore it for now and come back to it in excruciating detail later on.

We can issue compiler directives inline in the source code just above the
function we want it to apply to. To silence these warnings, we'll add this:

```rust
use std::io::{ stdout, Write };

#[allow(unused_must_use)]
fn main() {
    stdout().write(b"hi mom");
}
```

Now, the program will compile without any warnings at all, and write 'hi mom'
to stdout when run.

arbitrary bytes
---------------

So, `write()` ing to stdout is different than printing to standard out. The
`Hello World!` using `println!` did that just fine. Why do I need to go to the
extra effort of instantiating my own handle and writing byte arrays of
characters by hand? If all I want to do is print human readable strings to
output, then `println!` works just fine. But `write()` is much lower level- I
can write _anything_ to stdout, as long as I do it one `u8` at a time! This is
very powerful!

Can I do this?

```rust
stdout().write(1);
```

Nope.

```
stdout().write(1);
               ^ expected &[u8], found integral variable
```

Maybe it's because I'm passing in an integer without a type annotation? It
could be anything? I can be explicit about that by appending a type directly to
the number, like this:

```rust
stdout().write(1u8);
```

This might look weird, but it's more explicit. It still doesn't work, though.

```
stdout().write(1u8);
               ^^^^ expected &[u8], found u8
```

> Fun fact: that could also be written as `1_u8`. The underscore is ignored, and
> can be used for readibility in this or in very large numbers, like where you
> might put commas. Like ` 9_223_372_036_854_775_807u64` or something.

Maybe it needs the number to be in an array?

```
stdout().write([1u8]);
```

Nyope.

```
stdout().write([1u8]);
               ^^^^^ expected &[u8], found array of 1 elements
```

> I want to pause for a minute here and acknowledge how incredibly frustrating
> this might be for beginners to the language, especially 

We're almost there. The type that it's expecting is prepended with an
ampersand. In C, this would denote a pointer address to an array of `chars`
(`u8`s in rust) in memory. In rust, the meaning of this symbol is similar but
not quite the same. It does, in a sense, mean to pass something by reference-
we don't copy the whole byte array over into the `write()` function, but we
also don't really deal with pointers as abstractions in rust too often. Or at
least, it seems that way to me. The ampersand is related more to concepts of
ownership and borrowing than direct pointer manipulation, even if it's kind of
the same thing in this case.

Anyway- let's slap an ampersand on it.

```
stdout().write(&[1u8]);
```

This one compiles! As will, surprisingly, this one:

```
stdout().write(&[1]);
```

Turns out the compiler does do some type inference on integral types, after
all!

When you run this one, it doesn't seem to do anything. But it does! Let's run
the binary directly, it gets compiled into `target/debug/rav`. We'll pipe it
into [`xxd`](http://linuxcommand.org/man_pages/xxd1.html), which makes a stream
into a hexdump.

```
./target/debug/rav | xxd
```

```
0000000: 01
```

There it is, that's the `1` we wrote to stdout!

`write()` was expecting a variably sized slice of `u8`s, so we could write as many was we want.

```
stdout().write(&[1, 2, 3, 4, 5, 6, 7, 8]);
```

```
0000000: 0102 0304 0506 0708                      ........
```

If the values correspond to an ascii code, then it will be interpreted as that
character by the terminal.

```
stdout().write(&[104, 105, 32, 109, 111, 109, 22]);
```

```
0000000: 6869 206d 6f6d 16                        hi mom.
```

Neat!

Writing the waves
=================
