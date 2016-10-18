---
title: How Rust Do?
layout: post
date: 2016-10-16
tags: rc
---

Hey how does [Rust](https://www.rust-lang.org/en-US/) do?

I've been kind of interested in Rust since my [Recurse
Center](https://www.recurse.com) batch in 2014. A [batchmate of mine was
getting interested in it](http://src.codes/), and it sounded hella neat.

But alas, it wasn't to be. I was new to programming, having only written
Ruby for a few months, and Rust was still a long ways from 1.0 stable,
with the nightlies breaking libraries and the like.  One or the other of these
might have been alright, but not both. I'm glad I didn't try to learn it then,
I almost definitely would have been extremely frustrated.

But I kept Rust in the back of my mind, and now, with at least some programming
in C under my belt, more general experience, and Rust being firmly post 1.0, it
feels like the right time to check it out in earnest. I gotta say, I'm pretty
excited about it so far.

This is a tutorial/devlog of a small project, my first, I did in Rust. Once
again, I'm no expert, but I learned a lot doing it, and maybe someone will find
this account useful- I start from nothing and build a thing that does a thing.
Feel free to lmk if anything is borked. I would be happy to know.

The code for this is [here](https://github.com/urthbound/rav)

<a name=toc />
Table of Contents
----

- [getting Rust](#getrust)
- [mkdir](#mkdir)
- [Cargo](#cargo)
- [stdout](#stdout)
- [mystery](#mystery)
- [writing arbitrary bytes](#arbbytes)
- [did something happen?](#didsomethinghappen)
- [writing the waves](#writingthewaves)
- [make some noise](#makesomenoise)
- [run it](#runit)
- [let's refactor this dumpster fire](#dumpster)
- [stdout.lock()](#stdoutlock)
- [byteorder](#byteorder)
- [some other stuff](#someotherstuff)
- [passing locks](#passinglocks)
- [not just stdout, pls](#notjust)
- [the borrow checker](#borrowchecker)
- [&](#&)
- [two sound producing functions](#twofuncs)
- [you said we were going to come back to those warnings](#comebacktowarnings)
- [result returns vs exceptions](#resultsvsexceptions)
- [almost done](#almostdoneass)
- [what's that click](#whatsthatclick)
- [coda](#coda)


<sub><a href='#toc'>toc</a></sub>

<a name=getrust />
getting Rust
-----------

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

<sub><a href='#toc'>toc</a></sub>
<a name=mkdir />
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
    println!("Hello, World!");
}
```

A couple of things here!

First, there is no `stdio.h` equivalent import! The compiler automatically
inserts a [prelude](https://doc.rust-lang.org/std/prelude/) that imports a lot
of useful things right off the bat.

Second, though I won't go into the differences just yet, `println!` is a
_macro_, not a function. This distinction is very important, but for now you
can just think of it like a function, as long as you keep in the back of your
head that it is a macro. It does act look a function, anyway. Anything with a
`!` at the end of it is a macro.

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

<sub><a href='#toc'>toc</a></sub>
<a name=cargo />
Cargo
=====

Cargo is rust's package manager. It feels a lot like ruby's
[bundler](http://bundler.io/) or python's
[pip](https://pypi.python.org/pypi/pip) or javascript's
[<strike>npm</strike>](https://www.npmjs.com/)
[yarn](https://code.facebook.com/posts/1840075619545360/yarn-a-new-package-manager-for-javascript/).

That is to say, it is very easy to use, and declarative. You have a
[manifest](http://doc.crates.io/manifest.html) file written in
[toml](https://users.rust-lang.org/t/why-does-cargo-use-toml/3577/4) and
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


<sub><a href='#toc'>toc</a></sub>
<a name=stdout />
stdout
======

If I want to write data out of the program, I'm going to start by figuring out
how to write arbitrary data to standard out. This facility is _not_ included
with the prelude, so I'm going to have to import a thing for it. That looks
like this:

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

But of course, I actually want to _write something_ to stdout. For that, I'll
need to import another trait from the same namespace as before:

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

<sub><a href='#toc'>toc</a></sub>
<a name=mystery />
A mysterious warning
--------------------

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

<sub><a href='#toc'>toc</a></sub>
<a name=arbbytes />
writing arbitrary bytes
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

```rust
stdout().write([1u8]);
```

Nyope.

```
stdout().write([1u8]);
               ^^^^^ expected &[u8], found array of 1 elements
```

> I want to pause for a minute here and acknowledge how incredibly frustrating
> this might be for beginners to the language, especially if you're new to
> types in general. This type of thing would have crushed my resolve a few
> years ago!

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

```rust
stdout().write(&[1u8]);
```

This one compiles! As will, surprisingly, this one:

```rust
stdout().write(&[1]);
```

Turns out the compiler does do some type inference on integral types, after
all!

<sub><a href='#toc'>toc</a></sub>
<a name=didsomethinghappen />
did something happen?
-------------------

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

`write()` was expecting a variably sized
[slice](https://doc.rust-lang.org/beta/std/slice/) of `u8`s, so we could write
as many as we want.

```rust
stdout().write(&[1, 2, 3, 4, 5, 6, 7, 8]);
```

```
0000000: 0102 0304 0506 0708                      ........
```

If the values correspond to an ascii character code, then it will be
interpreted as that character by the terminal.

```rust
stdout().write(&[104, 105, 32, 109, 111, 109, 22]);
```

```
0000000: 6869 206d 6f6d 16                        hi mom.
```

Well, it doesn't have to be ascii, it can be unicode too!

```rust
stdout().write(&[0xe0, 0xb9, 0x80, 0xd5, 0x87, 0x20, 0xe0, 0xb9, 0x94, 0xe0, 0xb9, 0x8f, 0xd1, 0x94, 0xe0, 0xb8, 0xa3, 0xe0, 0xb8, 0xa0, 0x27, 0xd5, 0x87, 0x20, 0xd1, 0x92, 0xe0, 0xb8, 0x84, 0xd7, 0xa9, 0xd1, 0x94, 0x20, 0xd5, 0x87, 0xe0, 0xb9, 0x8f, 0x20, 0xe0, 0xb9, 0x92, 0xd1, 0x94, 0x20, 0xe0, 0xb8, 0x84, 0xe0, 0xb8, 0xa3, 0xcf, 0x82, 0xe0, 0xb9, 0x80, 0xe0, 0xb9, 0x80, 0x0a]);
```

Neat!

<sub><a href='#toc'>toc</a></sub>
<a name=writingthewaves />
Writing the waves
=================

We usually think of catting and echoing and stdout and whatnot as being related
to textual out and input. But it's not, really! It can be _any type_ of data. I
want to make a sound file. For simplicity's sake, it should be uncompressed.
I'll make a .wav file!

![img](http://soundfile.sapp.org/doc/WaveFormat/wav-sound-format.gif)

[A wave file consists of a header
chunk](http://soundfile.sapp.org/doc/WaveFormat/), containing metadata about
the data contained int he rest of the file, and a data chunk, which contains
the, uh, data.

The link above is really informative, but I'll go over it a little bit here
too. I'm going to be writing an 8 bit file, at 44.1kHz. I'll write all the data
to `stdout` initally, from there I can do something else with it if I want.

We start with the characters `"RIFF"`

```rust
stdout().write(b"RIFF");
```

Just like writing a string; that's 4 bytes long.

The next 4 bytes are a little-endian representation of how long the rest of the
file is. We'll come back to that in a minute, for now I'll just put in nulls (0).

```rust
stdout().write(b"RIFF");
stdout().write(&[ 0, 0, 0, 0 ]);
```

Next I write the literal strings `"WAVE"` and `"fmt "`... note the extra space
at the end of `"fmt "`, so that it takes up 4 bytes.

```rust
stdout().write(b"RIFF");
stdout().write(&[ 0, 0, 0, 0 ]);
stdout().write(b"WAVE");
stdout().write(b"fmt ");
```

Next comes the size annotation for the metadata chunk. For this type of wave
file, it is always 16 bytes.

```rust
stdout().write(b"RIFF");
stdout().write(&[ 0, 0, 0, 0 ]);
stdout().write(b"WAVE");
stdout().write(b"fmt ");
stdout().write(&[ 0, 0, 0, 16 ]);
```

BUT WAIT! All of the numerical values in this metadata header are in _little
endian_ format. This means that _the least significant byte comes first_. So,
instead of

```rust
stdout().write(&[ 0, 0, 0, 16 ]);
```

We write 16 like this:

```rust
stdout().write(&[ 16, 0, 0, 0 ]);
```

[Here's a spoopy video describing endianess in more
detail.](https://www.youtube.com/watch?v=MEyV7moej-k) (Happy Halloween
errybody.)

Ok, little endian everywhere! The next two bytes denote the "Audio Format". For
uncompressed [PCM](https://en.wikipedia.org/wiki/Pulse-code_modulation), this
value is always `1` (Again, in little endian!)

```rust
stdout().write(&[ 1, 0 ]);
```

The next two bits are the number of channels. Let's go easy on ourselves with mono!

```rust
stdout().write(&[ 1, 0 ]);
```

(That's one channel.)

The next one is a tad different! It's 4 bytes that represent that _sample rate_
of the file. We're going to go with 44.1kHz, which is the ["red book
standard"](http://www.soundonsound.com/sound-advice/q-it-worth-recording-higher-sample-rate)
for digital audio.

Now, we can't do this:

```rust
stdout().write(&[ 44100, 0, 0, 0 ]);
```

This doesn't make any sense. Each number is a single byte- which is 8 bits. A
single byte can only hold a value up to 2<sup>8</sup>, which is 256. Including
0, that's [256 possible values](/c-and-simple-types/) from 0-255. We need a two byte / 16
bit word to hold 44100.

In binary, that value would look like this:

```
1010110001000100
```

If we split that up into two bytes, and assing hexadecimal values to the two bytes,

```
binary:   1010 1100    0100 0100
hex:         a    c       4    4
```

Add a couple of padding zero bytes before these two byte:

```
00 00 ac 44
```

And then make the transformation to little endian:

```
44 ac 00 00
```

And there you go! It makes sense to write these into the stream as hexadecimal
literals just like they look above,

```rust
stdout().write(&[ 0x44, 0xac, 0x00, 0x00 ]);
```

(though you could write their decimal equivalents)

```rust
stdout().write(&[ 68, 172, 0, 0 ]);
```

(but, frankly, this makes even less sense, kind of...)

We're getting close. Don't worry. We're going to make it.

Next, is a 4 byte block for the byterate. The byterate is computed thusly:

```rust
samplerate * number of channels * (bits per sample / 8)
```

This is basically asking: how many bytes are set aside for each second of
audio? In our case,

```rust
44100 * 1 * (8 / 8)
```

This is the same as the sample rate, so we can reuse that value. Again, in
little endian.

```rust
stdout().write(&[ 0x44, 0xac, 0x00, 0x00 ]);
```

Blockalign is similar... how many bytes _per sample_ for all channels
inclusively.

```rust
number of channels * (bits per sample / 8)
```

That's just one.

```rust
stdout().write(&[ 1, 0 ]);
```

Sigh. Almost there.

Bits per sample is self explanatory:

```rust
stdout().write(&[ 8, 0 ]);
```

Finally, another string literal to denote the beginning of the data chunk...

```rust
stdout().write(b"data");
```

AND FINALLY, a four byte section to tell us how many bytes exist _in the whole
data chunk_. Let's pretend we're going to make one second of sound... at a
sample rate of 44100Hz, this means we're going to need 44100 samples to fill
one second, so once again:

```
// subchunk2size == numsamples * numchannels * bitspersample / 8
stdout().write(&[ 0x44, 0xac, 0x00, 0x00 ]);
```

The whole header looks something like this:

```rust
fn main() {

    // ChunkId
    stdout().write(b"RIFF");

    // ChunkSize = 36 + subchunk size 2
    stdout().write(&[ 0x68, 0xac, 0x00, 0x00 ]);

    // Format
    stdout().write(b"WAVE");

    // Subchunk1ID
    stdout().write(b"fmt ");

    // Subchunk1size
    stdout().write(&[16, 0, 0, 0 ]);

    // AudioFormat
    stdout().write(&[ 1, 0 ]);

    // Numchannels
    stdout().write(&[ 1, 0 ]);

    // Samplerate
    stdout().write(&[ 0x44, 0xac, 0x00, 0x00 ]);

    // Byterate samplerate + num of channels * bits per sample /8
    stdout().write(&[ 0x44, 0xac, 0x00, 0x00 ]);

    // blockalign
    stdout().write(&[ 1, 0 ]);

    // bitspersample
    stdout().write(&[ 8, 0 ]);

    // subchunk2 id
    stdout().write(b"data");

    // subchunk2size == numsamples * numchannels * bitspersample / 8
    stdout().write(&[ 0x44, 0xac, 0x00, 0x00 ]);

```

Notice I've filled in the subchunk 1 size with the appropriate value, which is
the size of all the data + a constant of 36 for the header prior to the data
chunk! That's the whole header!

<sub><a href='#toc'>toc</a></sub>
<a name=makesomenoise />
Make some noise
---------------

We need some actual data to fill this wav file with! What is it going to be? We
could start with the simplest to make noise there is- [white
noise](https://www.youtube.com/watch?v=EY5OQ2iVA50).

Sampled white noise is simply random values. Each sample is going to be some
random value between 0 and 255. No computation necessary!

We need 44100 of these values. It will look something like this!

```
for x in 0..44100 {
    stdout().write(&[ random() ]);
}
```

But rust isn't going to let us get away with a call like `random()`! We'll need
a crate [library](https://crates.io/crates/rand) for it!

Using a crate is pretty easy! We just need to add it to our `Cargo.toml` file
under `[dependencies]`, along with a version annotation. This glob means I
don't care which version I get.

```
[dependencies]
rand = "*"
```

At the top of the file, we'll import the library.

```
extern crate rand;
```

And we'll have access to that namespacing and all of its functions and traits!

```
for x in 0..44100 {
    stdout().write(&[ rand::random::<u8>() ]);
}
```

So, cool thing here- when we compile this, _cargo just like, works_. Assuming
you're connected to the internet- the dependency will be downloaded and
resolved and made available to you to be linked and compiled into the resulting
binary.

[We're just about right here, by the
way.](https://github.com/urthbound/rav/commit/cf20c195d94a01b0edf70ef21d10118d39e977a2)


<sub><a href='#toc'>toc</a></sub>
<a name=runit />
run it
-----

You can compile and run this! If you `cargo run` it, it will both compile _and_
run it.

But surprise if you did, because it just screwed up your terminal!! :D Turns
out catting a bunch of random binary shit to stdout can royally screw up your
terminal emulator. I assume it's catching random values that correspond to
instruction codes to the terminal display or something? I don't know, it
doesn't matter, but the first time it happens it sure can freak you out. if you
did this, just type `reset` and all should be well.

> If it screwed up your tmux, you can reset the pane by renaming it. <C-b>,<C-n>

But, also, there is an easy way to get stdout directed into a file!

```
cargo build
target/debug/rav > out.wav
```

Note that we have to build and run it this way because `cargo run` prints other
stuff to stdout before compiling the file!

Hey look a wav file! Try opening it up in a music player, and you should hear
exactly one second of horrible abrasive white noise! We just wrote a soundfile
from scratch.

If I open the resulting horrible sounding wave file in some editing software
that I can see the waveform in, I can look at the values I've produced.

<img src="/images/whitenoise.png" />

Looks like whitenoise! If we zoom in even further, it's easy to see the
individual random values.

<img src="/images/whitenoiseclose.png" />




<sub><a href='#toc'>toc</a></sub>
<a name=dumpster />
Let's refactor this dumpster fire!
--------------------------------

Ok, so, first of all, it seems pretty straightforward that we might want to
abstract the header writing out into a function called something clever, like
`write_header`. How about that?

```rust
use std::io::{ stdout, Write };
extern crate rand;

#[allow(unused_must_use)]
fn write_header() {
    // ChunkId
    stdout().write(b"RIFF");

    // ChunkSize = 36 + subchunk size 2
    stdout().write(&[ 0x68, 0xac, 0x00, 0x00 ]);

    // Format
    stdout().write(b"WAVE");

    // Subchunk1ID
    stdout().write(b"fmt ");

    // Subchunk1size
    stdout().write(&[16, 0, 0, 0 ]);

    // AudioFormat
    stdout().write(&[ 1, 0 ]);

    // Numchannels
    stdout().write(&[ 1, 0 ]);

    // Samplerate
    stdout().write(&[ 0x44, 0xac, 0x00, 0x00 ]);

    // Byterate samplerate + num of channels * bits per sample /8
    stdout().write(&[ 0x44, 0xac, 0x00, 0x00 ]);

    // blockalign
    stdout().write(&[ 1, 0 ]);

    // bitspersample
    stdout().write(&[ 8, 0 ]);

    // subchunk2 id
    stdout().write(b"data");

    // subchunk2size == numsamples * numchannels * bitspersample / 8
    stdout().write(&[ 0x44, 0xac, 0x00, 0x00 ]);
}

#[allow(unused_must_use)]
fn main() {
    write_header();
    // for x in 0..44100 {
    //     stdout().write(&[ rand::random::<u8>() ]);
    // }
}
```

Notice that we have to add the `#[allow(unused_must_use)]` annotation over
_every_ function that we want it to apply to. Explicit! (There is a way to have
it apply to the [whole project](http://stackoverflow.com/a/25877389/2727670),
but that's overkill right now.)

> Also, I've commented out the noise generation so that I can `cargo run` with
> impunity [because I want to](https://www.youtube.com/watch?v=D_XI_290cfw).

<sub><a href='#toc'>toc</a></sub>
<a name=stdoutlock />
stdout.lock()
--------------

So, this works fine. Each call to `stdout()` returns a locked handle to the
stdout stream of that process. But, why suffer the overhead of calling that
function over and over again? I can simply assign the output of that call
_once_ to a local binding, and reuse it... something like this:

```rust
let stdout = stdout();
stdout.write(b"RIFF");
```

Woah hey this doesn't work!

```
 --> src/main.rs:9:5
  |
6 |     let stdout = stdout();
  |         ------ use `mut stdout` here to make mutable
...
9 |     stdout.write(b"RIFF");
  |     ^^^^^^ cannot borrow mutably

```

IF I do that...

```rust
let mut stdout = stdout();
stdout.write(b"RIFF");
```

This will work. It will uncomplainingly compile and run, printint as you would
expect. But this is not the best way to accomplish this!

A mutable reference to stdout means that there is no lock against an attempt to
write to it from anywhere!

Look at this- what if I try to write to stdout in this mutable way from two
different threads simultaneously?

```rust
thread::spawn(|| {
    for _ in 0..100 {
        let mut stdout = stdout();
        stdout.write(b"1");
    }
});
thread::spawn(|| {
    for _ in 0..100 {
        let mut stdout = stdout();
        stdout.write(b"2");
    }
});
```

This will also compile... I have explicitly told the compiler to treat stdout
at mutable in both places, but it's _completely unpredictable_. Every time you
run it it will look different. I mean, look at this hot garbage!

```
   Compiling rav v0.1.0 (file:///Users/jfowler/code/rav)
    Finished debug [unoptimized + debuginfo] target(s) in 0.41 secs
     Running `target/debug/rav`
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
Press ENTER or type command to continue

   Compiling rav v0.1.0 (file:///Users/jfowler/code/rav)
    Finished debug [unoptimized + debuginfo] target(s) in 0.42 secs
     Running `target/debug/rav`
12thread '<unnamed>' panicked at 'cannot access stdout during shutdown', ../src/libcore/option.rs:700
note: Run with `RUST_BACKTRACE=1` for a backtrace.

Press ENTER or type command to continue

   Compiling rav v0.1.0 (file:///Users/jfowler/code/rav)
    Finished debug [unoptimized + debuginfo] target(s) in 0.42 secs
     Running `target/debug/rav`
12thread '
Press ENTER or type command to continue
```

I don't even rn.

This is just to say that I need a mechanism for _locking stdout_ to a
particular handle before I write to it. This is implicit in the `stdout()`
calls, as the lock persists only as long as the scope of that call, but I'd
prefer to be more explicit, as rust [seems to want me to want to
be.](https://doc.rust-lang.org/beta/std/io/fn.stdout.html)

So I will!

```rust
let stdout = stdout();
let mut handle = stdout.lock();
handle.write(b"RIFF");
// etc...
```

The benefits of this method will become more apparent when I start to pass
handles around!


<sub><a href='#toc'>toc</a></sub>
<a name=byteorder />
Byteorder
---------

So, this all works fine, to write that header, but it's cryptic as all hell.

```rust
handle.write(&[ 0x44, 0xac, 0x00, 0x00 ]);
```

We know what that is because I explained it, but if I hadn't, would it make any
sense at all at first glance? When I forget this repo exists and come back to
it in a year... will I remember what that is? What it represents? That it's in
little endian?


```rust
// little endian bytewise representation of the sample rate: 44100
handle.write(&[ 0x44, 0xac, 0x00, 0x00 ]);
```

Sure, fine, I should comment more liberally. But that old axiom, that code
should be it's own documentation? That might be bumpkis, writ generalis, but I
can't argue with the idea that I should try to write code that clearly
expresses my intent.

The fine folks over in `#rust-beginners` pointed me to the perfect library to
solve this problem... [Byteorder](https://crates.io/crates/byteorder).

I pull in the crate in my Cargo.toml:

```
[dependencies]
rand = "*"
byteorder = "0.5.3"
```

And add the import `use` statement specifying what I'm actually using in my
preamble.

```
use byteorder::{ LittleEndian, WriteBytesExt };
```

This library includes some utilities (WriteBytesExt) for writing different
sized numerical types into anything that uses the `Write` trait. So instead of
the cryptic thing above, I can write this:

```
handle.write_u32::<LittleEndian>(44100);
```

I'm writing a u32 (which is 4 bytes wide) and I'm writing it in little endian,
and the number I am writing is clear af and human readable right in the code now!

> This syntax is pretty unfamiliar to me- the brackets and type annotations and where
> they can live and do things and what they do has so far been the most counter
> intuitive part of this exercise...

I can do the same for all the other writes in the header function. And also I'm
going to pull a bunch of these values out into constants, because I don't
anticipate changing them for the duration of these exercises.

```rust
const SAMPLE_RATE: u32 = 44100;
const CHANNELS: u32 = 1;
const HEADER_SIZE: u32 = 36;
const SUBCHUNK1_SIZE: u32 = 16;
const AUDIO_FORMAT: u32 = 1;
const BIT_DEPTH: u32 = 8;
const BYTE_SIZE: u32 = 8;

fn write_header() {
    let stdout = stdout();
    let mut handle = stdout.lock();

    let numsamples = SAMPLE_RATE * 1;

    handle.write(b"RIFF");
    handle.write_u32::<LittleEndian>(HEADER_SIZE + numsamples);
    handle.write(b"WAVEfmt ");
    handle.write_u32::<LittleEndian>(SUBCHUNK1_SIZE);
    handle.write_u16::<LittleEndian>(AUDIO_FORMAT as u16);
    handle.write_u16::<LittleEndian>(CHANNELS as u16);
    handle.write_u32::<LittleEndian>(SAMPLE_RATE);
    handle.write_u32::<LittleEndian>(SAMPLE_RATE * CHANNELS * (BIT_DEPTH / BYTE_SIZE));
    handle.write_u16::<LittleEndian>((CHANNELS * (BIT_DEPTH / BYTE_SIZE)) as u16);
    handle.write_u16::<LittleEndian>(BIT_DEPTH as u16);
    handle.write(b"data");
    handle.write_u32::<LittleEndian>(numsamples * CHANNELS * (BIT_DEPTH / BYTE_SIZE));
}
```

Sure thing! That's a lot clearer. Also I snuck some other stuff in there!

<sub><a href='#toc'>toc</a></sub>
<a name=someotherstuff />
some other stuff
-------------

Look at the `as u16` statements in the audio format and the channels sections.
So, in rust, there is _no implicit arithmetic integral type casting_. This is
pretty wild!

So for example,

```rust
3 * 3           // will work
3u32 * 3u32     // will work
3u32 * 3i32     // will NOT work
3u8 * 3i64      // will NOT work
```

They have to actually be the actual for realsies same type!

I'm setting most of those constants as u32 (because I don't need any negative
numbers.) so that they can interact with each other. But I need to explicitly
cast them into `u16` to write them as two byte words into stdout, even though
the value is small enough to fit into a u16, it might NOT be small enough. How
is the compiler supposed to know? That's some hard typing, right there.

Also this:

```rust
let numsamples = SAMPLE_RATE * 1;
```

I'm computing how many samples total are in the file! This is straightforward-
however many seconds the file is, times the sample rate. Look above, the number
of samples is also used in computing the size of the whole file in the last
line, and the size of the whole file including the headers in the second!

Let's parameterize the seconds!

```rust
#[allow(unused_must_use)]
fn write_header(seconds: u32) {
    let stdout = stdout();
    let mut handle = stdout.lock();

    let numsamples = SAMPLE_RATE * seconds;
// etc...
```

Now I can write a wav file of arbitrary length of white noise!

> TODO: link to that commit

<sub><a href='#toc'>toc</a></sub>
<a name=passinglocks />
passing locks.
------------

I want `write_header()` to be more generic. I'll also parameterize the lock
that I'm passing in!

```rust
fn write_header(seconds: u32, mut handle: StdoutLock) {
        // etc...
```

and in `main()`:

```rust
let stdoutvar = stdout();
write_header(duration, stdoutvar.lock());
```

So, check out that typing! `seconds` has to be a `u32` but the `handle` var
must be a `StdoutLock`.
[StdoutLock](https://doc.rust-lang.org/std/io/struct.StdoutLock.html) is the
struct that is returned by a call to `.lock()`. Also, it _must_ be mutable,
because we're writing to it! You can't write to an immutable value, because
that would be changing it, which means it's not immutable.

Now, in main, I can create that lock once and pass it in to the function I've
made:

```rust
#[allow(unused_must_use)]
fn main() {

    let duration = 1;

    let stdoutvar = stdout();
    write_header(duration, stdoutvar.lock());
    for x in 0..duration * SAMPLE_RATE {
        stdoutvar.lock().write(&[ rand::random::<u8>() ]);
    }
}
```
<sub><a href='#toc'>toc</a></sub>
<a name=notjust />
Not just stdout, pls.
----------------------

So whiny.

Ok so,

```rust
fn write_header(seconds: u32, mut handle: StdoutLock) {
    // stuff
}
```

Is great, cause I can pass in a lock, but what if I want to write that output
to something else? Say a file? Or a
[vector](https://doc.rust-lang.org/std/vec/struct.Vec.html)?

Let's start with a vector! Vectors [do implement the write
trait](https://doc.rust-lang.org/src/std/up/src/libstd/io/impls.rs.html#211-226),
so all those writes should work on them the same way! (of course, it will need to be a vector of `u8`s, but that's ok!)

I can't pass a vector in under the current type annotation, though, I'll get this:

```
error[E0308]: mismatched types
  --> src/main.rs:40:28
   |
40 |     write_header(duration, vec);
   |                            ^^^ expected struct `std::io::StdoutLock`, found struct `std::vec::Vec`
   |
```

But I could state that I could allow anything to be passed through, with a
generic, which is denoted by `T`

```rust
fn write_header<T:Write>(seconds: u32, mut handle: T) {
```

A generic needs to guarantee some trait or interface, that's the `<T:Write>`
part of the function declaration.

```rust
let duration = 1;
let vec: Vec<u8> = Vec::new();
write_header(duration, vec);
```

This will work! I just wrote the header for a one second file straight into a vector.

Let's print the vector to see what it looks like;

```rust
fn main() {
    let duration = 1;
    let vec: Vec<u8> = Vec::new();
    write_header(duration, vec);
    println!("{:?}", vec);
}
```

Uh oh...

```
error[E0382]: use of moved value: `vec`
  --> src/main.rs:42:22
   |
40 |     write_header(duration, vec);
   |                            --- value moved here
41 |
42 |     println!("{:?}", vec);
   |                      ^^^ value used here after move
```

Strap the eff in because it's our first encounter with

<sub><a href='#toc'>toc</a></sub>
<a name=borrowchecker />
The Borrow Checker
------------------

[The official docs](https://doc.rust-lang.org/beta/book/ownership.html) do a
much better job of explaining this concept than I could hope to in a subsection
of an introductory blog post, so I'd suggest you go skim a little bit of that
to get a feel for _what_ the borrow checker is, _why_ it is, and _how_ it
do. It's one of Rust's most powerful power features, and what makes GC-less
memory management possible through static compile time analysis.

I can however, in this limited example, explain _exactly_ what the checker is
complaining about.

When a value is passed in with what you might think of as "normal" syntax (ie,
no special annotation), _ownership_ of that value is transferred to the function
you're passing it into.  That means that at the end of _that_ scope, the memory
is freed.

When we try to print it after that function call, we get the error above,
because the memory is no longer guaranteed to be stable. It _might_ be, but it
_might_ not be, so it won't compile.

What if we pass in a (ahem) "pointer"?

```rust
let duration = 1;
let  vec: Vec<u8> = Vec::new();
write_header(duration, &vec);
println!("{:?}", vec);
```

No worky!

```
error[E0277]: the trait bound `&std::vec::Vec<u8>: std::io::Write` is not satisfied
```

I'm a little fuzzy on the terminology here, but I find it useful to think about
it this way.

<sub><a href='#toc'>toc</a></sub>
<a name=& />
&
-
```
&
```

In C, the ampersand _takes the address of a thing_. When you pass an address
around, you're passing by reference, and when you mutate the data that thing
references, you're mutating the original data, not a copy.

In Rust, the ampersand _kind of sort of_ means the same thing, but the
appropriate term is "borrowing" the value- the difference being what I was
saying before about who is responsible for deallocation.

If the value is "moved", i.e., passed by value into a called function- the
called function is responsible for that deallocation. If however, the value is
"borrowed" by the called function, the _caller_ is still responsible for the
deallocation.

But passing by reference (er... _borrowing_) is _immutable by default._

A borrowed vector is therefore read only. To make it writable, we have to
explicitly _say_ we're borrowing a _mutable_ reference, with `mut`.

Both in the function declaration:

```rust
fn write_header<T:Write>(seconds: u32, handle: &mut T) {
    // stuff...
}
```

And in the variable binding:


```rust
let mut vec: Vec<u8> = Vec::new();
```

... oh yes, _and_ in the call to the function.

```rust
write_header(duration, &mut vec);
```

With all these conditions satisfied, we can now pass in a mutable vector which
gets written to in the function call, and then print it to the screen after
that.

```
[82, 73, 70, 70, 104, 172, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 1, 0, 68, 172, 0, 0, 68, 172, 0, 0, 1, 0, 8, 0, 100, 97, 116, 97
```

Isn't that something?

<sub><a href='#toc'>toc</a></sub>
<a name=twofuncs />
two sound producing functions
---------------------------

I will also factor out the white noise generation into its own function, with the same type signature as `write_header()` :

```rust
#[allow(unused_must_use)]
fn make_some_noise<T: Write>(seconds: u32, handle: &mut T) {
    for _ in 0..seconds * SAMPLE_RATE {
        handle.write(&[ rand::random::<u8>() ]);
    }
}
```

> How about this one?
>
> ```rust
> #[allow(unused_must_use)]
> fn make_a_random_ass_sawtooth<T: Write>(seconds: u32, handle: &mut T) -> Result<(), Error > {
>     for x in 0..seconds * SAMPLE_RATE {
>         try!(handle.write(&[ ((x + 1) % 255) 1as u8 ]));
>     }
> }
> ```
>
> The period of this [waveform](https://en.wikipedia.org/wiki/Sawtooth_wave) is
> SAMPLE_RATE / [u8::MAX](https://doc.rust-lang.org/std/u8/constant.MAX.html).
> That's 44100 / 255 = 172.94, which is just a hair under
> [F3](http://www.phy.mtu.edu/~suits/notefreqs.html). Give it a try!


<sub><a href='#toc'>toc</a></sub>
<a name=comebacktowarnings />
You said we were going to come back to those warnings.
-------------------------------------------------------

So I did. It's time to remove all the `#[allow(unused_must_use)]`
annotations.

Surprise! Everything breaks!

```rust
   Compiling rav v0.1.0 (file:///Users/jfowler/code/rav)
warning: unused result which must be used, #[warn(unused_must_use)] on by default
  --> src/main.rs:42:9
   |
42 |         handle.write(&[ rand::random::<u8>() ]);
   |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

Well, not everything breaks, really, it still compiles, but with _ton_ of
warnings. In fact, I get a separate warning like the above for every call to
any kind of `write`.

Let's go back to the simplest case where we first saw this message.

```rust
use std::io::{ stdout, Write };

fn main() {
    stdout().write(b"hi mom");
}
```

```
warning: unused result which must be used, #[warn(unused_must_use)] on by default
 --> thing.rs:5:5
  |
5 |     stdout().write(b"hi mom");
  |     ^^^^^^^^^^^^^^^^^^^^^^^^^^

hi mom
```

What is this unused `result` thing? Let's try to get a little more information
about it... maybe I can print it to something? It's being returned from that
expression, so I'll assign it to a thing and then `println!` it...

```rust
use std::io::{ stdout, Write };

fn main() {
    let thing = stdout().write(b"hi mom\n");
    println!("{:?}", thing);
}
```

yields:

```
hi mom
Ok(7)
```

OOOOOOH, the result is a [_Result_, with a capital
`R`](https://doc.rust-lang.org/beta/std/result/)!

<sub><a href='#toc'>toc</a></sub>
<a name=resultsvsexceptions />
result returns vs exceptions
--------------------------------

So, Rust doesn't have exceptions. There is no concept of a `try`/`catch` block
like there is in many other languages. Instead, Rust uses [return
values](https://doc.rust-lang.org/book/error-handling.html) to communicate
success and failure.

For every call that can fail, like `write()`, the expression evaluates to a
Return type, that can either be `Ok` or `Err`. [That's this bit](https://doc.rust-lang.org/beta/std/result/enum.Result.html):

```rust
#[must_use]
pub enum Result<T, E> {
   Ok(T),
   Err(E),
}
```

So, if a `Result` is `Ok`, it can return any other type `T` wrapped in that
Result. If it's an Error, it return an `E` type wrapped in a Result. Either
way, the return value of a potentially failable function call is a _something_
wrapped in a Result.

> This has something to do / a lot in common with the [Either monad in
> Haskell](https://hackage.haskell.org/package/category-extras-0.52.0/docs/Control-Monad-Either.html), and
> the [Option type in
> Scala](http://danielwestheide.com/blog/2012/12/19/the-neophytes-guide-to-scala-part-5-the-option-type.html)
> and the [option datatype](http://sml-family.org/Basis/option.html) in ML. I
> don't really know about how those things work other than to mention them as
> probably pertinent here! Rust is my first encounter with this concept in a
> language I'm actively trying to learn, but it's not new in the world at large!

The compiler is telling us that we need to address this Result, because it
_could_ be potentially failing. As the code is written, if any of the writes
fail, the program will do weird things!

Check this one out:

```
use std::fs::File;

fn main() {
    let result = File::open("file_that_doesnt_exist.lol");
    println!("{:?}", result);
}
```

```
Err(Error { repr: Os { code: 2, message: "No such file or directory" } })
```

That's a potential error case that I need to address in my code! This is what
the warning was warning about.

There are a few ways to do this! The simplest way is to call
[`.unwrap()`](https://doc.rust-lang.org/1.7.0/std/option/enum.Option.html#method.unwrap)
on the expression that returns a result. This will "unwrap" the option, and if
it's `Ok()` it will return whatever the result has wrapped. If it's an `Err()`,
it will simply panic, killing the process. This is a rudimentary way of
handling the error, yes, but it definitely beats the program mysteriously
dying, or worse, undefined behavior after that failure to write or whatever.

```rust
use std::fs::{File};

fn main() {
    File::open("file_that_doesnt_exist.lol").unwrap();
}
```

```
thread 'main' panicked at 'called `Result::unwrap()` on an `Err` value: Error { repr: Os { code: 2, message: "No such file or directory" } }', ../src/libcore/result.rs:788
note: Run with `RUST_BACKTRACE=1` for a backtrace.
```

backtrace == sweet action.

Better still is to _actively deal with the error_ somehow. I could assign that
result to a local var and handle each case explicitly using a match statement...

```rust
use std::fs::{File};
fn main() {
    let result = File::open("file_that_doesnt_exist.lol");
    match result {
        Ok(v) => println!("success opening file :) {:?}", v),
        Err(e) => println!("error opening file!!!: {:?}", e),
    }
    println!("the above doesn't exit the thread though, so this is still printed.");
}
```

[Pattern matching is super common and useful in
rust!](https://doc.rust-lang.org/stable/book/patterns.html) The `match`
statement is like a superpowered `switch` from C. [Just like in
C](http://blog.jfo.click/sild-named-enums/) the compiler will warn you if you
haven't handled all the possible cases for a typed match! If I try to do this,
for example:

```rust
use std::fs::{File};
fn main() {
    let result = File::open("file_that_doesnt_exist.lol");
    match result {
        Ok(v) => println!("success opening file :) {:?}", v),
    }
    println!("the above doesn't exit the thread though, so this is still printed.");
}
```

I get this:

```
error[E0004]: non-exhaustive patterns: `Err(_)` not covered
 --> thing.rs:5:11
  |
5 |     match result {
  |           ^^^^^^ pattern `Err(_)` not covered

error: aborting due to previous error
```

This is a great example of the compiler being your best friend! Non exhaustive
pattern matching would mean that I could have weird things happen.

So a thing about match, syntactically, is that it can be inlined and the
intermediate `result` variable can be dispensed with, assuming you don't need
that result type for anything else:

```rust
match File::open("file_that_doesnt_exist.lol") {
    Ok(v) => println!("success opening file :) {:?}", v),
    Err(e) => println!("error opening file!!!: {:?}", e),
}
```

In reality, I need to handle _every single write() call_ and the possible Error
results. You can imagine how tedious, and ugly, and verbose this would get in a
function like `write_header()`, especially when all the handlers basically do
the same thing. Rust provides a macro that does this for me,
[`try!`](https://doc.rust-lang.org/src/core/up/src/libcore/macros.rs.html#223-230).
Unfortunately, there is a catch! ... this won't work...

```rust
use std::fs::{ File };

fn main() {
    try!(File::open("file_that_doesnt_exist.lol"));
}
```

And fails with kind of a cryptic error..

```
error[E0308]: mismatched types
 --> <std macros>:5:8
  |
5 | return $ crate :: result :: Result :: Err (
  |        ^ expected (), found enum `std::result::Result`
thing.rs:4:5: 4:52 note: in this expansion of try! (defined in <std macros>)
  |
  = note: expected type `()`
  = note:    found type `std::result::Result<_, _>`
```

This was was a head scratcher for me for a bit. Why would this fail? And what
was expecting
[`()`](http://stackoverflow.com/questions/31107614/what-does-an-empty-set-of-parens-mean-when-used-in-a-generic-type-declaration)?

The answer is perfectly reasonable but very sneaky! Check again the
[`try!`](https://doc.rust-lang.org/src/core/up/src/libcore/macros.rs.html#227).
macro's source... you'll notice there is a hidden `return` statement in there!

In this case the compiler error is referencing _main itself_. It was expected
to return nothing, but a branch of that code (expanded from `try!`) could
potentially return the errored result. This was tricky!

`try!` is designed to allow early bailing from a function that returns a
result. It doesn't work in `main()` because main doesn't return a result! But
it will work perfectly fine in the other functions I've written, with a
little change to their signatures... take the noise function as an example!

```rust
fn make_some_noise<T: Write>(seconds: u32, handle: &mut T) -> Result< (), Error > {

    for _ in 0..seconds * SAMPLE_RATE {
       try!(handle.write(&[ rand::random::<u8>() ]));
    }

    Ok(())
}
```

This will compile just fine- I am saying that this function will return a
result of either nothing (`Ok(())`) or an error! This can then be _explicitly
passed_ to the caller (in this case `main`) and handled there.

For my case, simply `unwrap()`ping the return from the `make_some_noise()` call
inside of `main()` is sufficient. If it failed at any point, ok whatevers, just bail.
In production code or a bigger program, I might want to propogate that error
further, or handle it more gracefully, but this is ok for now.

```rust
fn main() {
    let duration = 1;

    let mut fp = File::create("out.wav").unwrap();

    write_header(duration, &mut fp).unwrap();
    make_some_noise(duration, &mut fp).unwrap();
}
```

[I also wrap all the `write` calls in `write_header()` in `try!` macros!](https://github.com/urthbound/rav/commit/8994c8e0163a7a0d67bcac9f043745dd3327421f)

And now I don't have to suppress those warnings, because I've addressed them,
and they don't show up!

<sub><a href='#toc'>toc</a></sub>
<a name=almostdoneass />
almost done
----------------

This is getting pretty close to being a doneass program, but I still haven't
really written any sound output that sounds like anything, except for that
awful sawtooth whose frequency is tied to the sample rate.

Here's a function that computes sinusoidal values on a sample by sample basis
given a frequency:

```rust
fn sine_wave<T: Write>(seconds: u32, handle: &mut T, freq: f64) -> Result<(), Error > {
    for x in 0..seconds * SAMPLE_RATE {
       let x = x as f64;
       try!(handle.write(&[ ((((((x * 2f64 * PI) / SAMPLE_RATE as f64) * freq).sin() + 1f64 )/ 2f64) * 255f64) as u8 ]));
    }
    Ok(())
}
```

I debated whether or not to explain everything in that function right now. I'm
not going to! I'll come back to it in another post, because it's fascinating,
but it's not about rust, really..

I used it to write a [Barry Harris
scale](https://www.youtube.com/watch?v=-jO-sIrjTq://www.youtube.com/watch?v=-jO-sIrjTqg)

```rust
fn main() {
    let duration = 1;

    let mut fp = File::create("out.wav").unwrap();

    write_header(duration * 9, &mut fp).unwrap();
    sine_wave(duration, &mut fp, 523.25_f64).unwrap();
    sine_wave(duration, &mut fp, 493.88_f64).unwrap();
    sine_wave(duration, &mut fp, 440_f64).unwrap();
    sine_wave(duration, &mut fp, 415.30_f64).unwrap();
    sine_wave(duration, &mut fp, 392_f64).unwrap();
    sine_wave(duration, &mut fp, 349.23_f64).unwrap();
    sine_wave(duration, &mut fp, 329.63_f64).unwrap();
    sine_wave(duration, &mut fp, 293.66_f64).unwrap();
    sine_wave(duration, &mut fp, 261.63_f64).unwrap();
}
```

[Try compiling
it!](https://github.com/urthbound/rav/commit/f291ae4d50573c0591ef8496cbadce1e6c111cd2)

<img src="/images/sinusoidal.png" />

<sub><a href='#toc'>toc</a></sub>
<a name=whatsthatclick />
what's that click
------------------

So, I gotta share this one last thing that I learned. If you compile that last
example and play the resulting wave file, you might notice something strange.
There is an audible clicking between some of the notes being played. I used to
wonder about what that is, but with this output you can just like, _look at
it_, and see!

<img src="/images/clicks.png" />

When I start computing a new note, I _always_ start from 0. Sometimes, the last
value in the previous note is pretty close to 0, and you don't hear anything,
and it's smooth. Sometimes, it's _very far_ from 0, and the change happens
super abruptly and results in an audible clicking noise. Gross! The solution to
this nastiness would be to precompute the phase offset of the next note, to
know where to start the new waveform from. This is outside the scope of this post,
but I thought it was pretty neat!

<sub><a href='#toc'>toc</a></sub>
<a name=coda />
Coda
----

Thanks to #rust-beginners, that channel was friendly and does what it says on
the tin.  And also
[users.rust-lang.org/](https://users.rust-lang.org/t/some-questions-on-idioms-in-a-small-program/7607/4).
And also [Steve Klabnik](https://twitter.com/steveklabnik), who seems to be
everywhere and is very helpful.

The Rust community has a pretty welcoming reputation, and so far so good on
that front! I'm excited to do low level stuff with a modern ecosystem, and Rust
has a lot of interesting ideas behind it I am eager to learn more about.

Ok that's it for now.
