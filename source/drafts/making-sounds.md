---
title: Sound from nowhere
layout: post
---

There is a very quiet room, somewhere around sea level. The room is full of
air. The air is made of particles, of atoms, of different types of gases... it
doesn't really matter. What matters is that all of the particles and atoms and
gases are equidistant from each other, roughly speaking. It is a very quiet
room.

![img](https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/Simple_sine_wave.svg/1024px-Simple_sine_wave.svg.png)

Two disembodied hands clap together one time, suspended in the very middle of
the room. Like two cousin It's from the Addam's Family.

Where the hands meet, air moves out of the way, and bumps into more air, which
bumps into more air, etc. A pressure wave moves from the epicenter (where the
hands met) outward in all directions, until the pressure wave hits
the wall of the now not as quiet room, where it bounces off, again in all directions,
until the wave is dissipated, and the room is once again a very quiet room.

That is what sound is: a bunch of pressure differentials travelling through the
air. This is what we are sensing when we hear anything: music, boiling water,
my neighbor's dogs barking all the time forever and ever... it's all a giant
mess of different pressure waves interacting with each other and the world and
getting to our ears where we process it into some weird brain assembly
language.

Let's talk about that wave diagram up there. The X axis is time, and the Y
value is the level of pressure at a static point at that static time. There are
lots of ways to measure this, but it's easiest to think of this pressure being
somewhere between -1 and 1, where 0 would be the room at rest. Just like the
ocean goes below sea level immediately following a wave, a negative pressure
follows the positive, hence, -1

Let's look at a speaker; here's a teeny tiny one:

I want to point out some important bits. There is a speaker cone. There is a
magnet. There are two nodes that connect to an electromagnet inside the
speaker. When a current is applied, this electromagnet becomes charged. You'll
hear a little click. This is the sound that the speaker makes when it is
*physically moving*. Take a look:

The electromagnet, when charged, becomes attracted to the magnet, and pulls the
speaker cone inwards. Here's something I never realized before: If you reverse the
direction of the input current, the speaker cone moves in the opposite
direction! The electromagnet is being attracted instead of being repelled. This
makes perfect sense, but had never occurred to me. I love stuff like that!

Controlling when and how much current is applied to this speaker is how we can
control the sound that is coming out of it.

Let's Arduino!
-------------

We're going to plug the speaker directly into the board. This is kind of silly,
but it totally works! The arduino has an output voltage of 5v, which is not
much really, but it's enough to drive the speaker, and the code is hellah
simple.

If you've never worked with the Arduino language before: it's C++, basically,
but the IDE / Compiler / toolchain takes care of all the heavy lifting wrt
linking libraries and compiling binaries and flashing the chip on the board
with the new firmware and all that.  We just need to worry about a single `.ino`
file that implements two functions:

```c
void setup();
void loop();
```

`setup()` runs one time, at the start of the program, and thereafter `loop()`
runs indefinitely, on a loop.

Although I fully intend to delve into the madness and learn how to flash my own
hardware and write bare C/C++ for chips someday, that day is not today, so this is
very nice. We just have to write two methods, flash to the board, and the
Arduino will work. :sparkles: Rapid indeed! Here is a simple program:

```c
void setup() {
    pinMode(13, OUTPUT);
}

void loop() {
    digitalWrite(13, HIGH);
}
```

`13` is the number for one of the board's digital pins, so we're telling it
that we want to treat that pin as an output pin. It's purely digital, off and
on, 0v or 5v, and nothing in between, but we have precise control over when it
is switched, up to the limits of the speed of the processor.

What does this program do? It writes `HIGH` to the output pin as fast as it
can, forever. `HIGH` is an arduino constant that resolves to the maximum output
voltage of the model of board you have, so for this one, 5v)

This doesn't really do that much, but you can indeed here the telltale click:

... which means that a current is being applied.

Let's change our loop... (`LOW`, as you might guess, is a constant that resolves
to the minimum output of our board, which is 0v):

```c
void loop() {
    digitalWrite(13, HIGH);
    digitalWrite(13, LOW);
}
```
This does more... I mean, it makes a ... sound. :\

This loop is writing high and low to the pin as fast as it can. The speaker is
moving back and forth, and we can hear a high pitched, messy squeal as a result.

We want a little more control over this, but let's start by making something
pretty close to white noise.

```c
void loop() {
    int no_whammies = random(100);
    if (no_whammies > 50) {
        digitalWrite(13, HIGH);
    } else {
        digitalWrite(13, LOW);
    }
}
```

Wow, that's weird.

Hertz so good
-------------

>The hertz (symbol Hz) is the unit of frequency in the International System of
>Units (SI) and is defined as one cycle per second.[1] It is named for Heinrich
>Rudolf Hertz, the first person to provide conclusive proof of the existence of
>electromagnetic waves.

[Thanks Wikipedia!](https://en.wikipedia.org/wiki/Hertz)

Using hertz (symbol Hz) as a unit is agnostic; it can refer to anything.
A light that flashes once a second is flashing at 1Hz.

Let's make this speaker "flash" at once per second:

```c
void loop() {
    digitalWrite(13, HIGH);
    digitalWrite(13, LOW);
    delay(1000);
}
```

(`delay()` takes an int that represents milliseconds, so this is one second)

You can hear it clicking, once per second, but it is very quiet. Look close at
what this is doing: it writes `HIGH` and then writes `LOW` as fast as it can,
and then waits a second before doing it again. There might be a better way; the
cone might not be getting all the way out before being pulled back in.

But recall that the speaker cone clicks when it goes in, AND when it goes out.

```c
void loop() {
    digitalWrite(13, HIGH);
    delay(500);
    digitalWrite(13, LOW);
    delay(500);
}
```

Now you have your own shitty, too quiet, incredibly user unfriendly
metronome!

> Why 500ms on each delay, instead of 1000ms? A cycle means that we end where
> we started. Even though this clicks twice a second, it is still only
> completely one cycle per second, and so is still 1Hz

A 440hz
-------

A musical note is pitched. There is a lot that goes into what it actually
*sounds* like, tonally, but the fundamental frequency of the sound wave is what
defines the pitch that we perceive.

We've made the speaker move in and out once per second. If we can make it move
faster than that, we can make real, pitched sounds. Let's try having it wait
just 1 millisecond.

```c
void loop() {
    digitalWrite(13, HIGH);
    delay(1);
    digitalWrite(13, LOW);
    delay(1);
}
```

This is one cycle every two milliseconds, which is 500 cycles per second, which
is 500Hz.

Here is a handy chart showing the frequencies of a couple of octaves of notes
in the middle of the keyboard:

![img](http://www.sengpielaudio.com/FrequenzenKlavier09.jpg)

According to this, our speaker should be producing a note about 6.12Hz faster
than a B above middle C. Let's see:

Super. We're almost to something useful. This is as fast as we can go using
`delay()` because it takes milliseconds, but never fear.

```c
void loop() {
    digitalWrite(13, HIGH);
    delayMicroseconds(1000);
    digitalWrite(13, LOW);
    delayMicroseconds(1000);
}
```

This code is a refactor of the loop above. A millisecond is 1/1000th of a
second, but a microsecond is 1/1000th of a millisecond. We're in the
millionth's of a second here, and can be a lot more precise now!

We want to produce a tone at 440Hz, which means we will complete 440
cycles per second, and that each single cycle will take 1/440 of a second.

```
1/440 = 0.0022727...
```

But a second has a million microseconds in it, so this is equal to

```
0.0022727... * 1000000 = 2272.7272...
```

Since we can't do floats I'll floor that to 2272μs. (The symbol for
microseconds is `μs`, which I didn't know until just now.)

Remember that to complete one complete cycle, we have to write `HIGH`, then
wait for 1/2 a cycle, then write `LOW`, then wait for the remaining half. Half
of 2272μs is 1136μs, so:

```c
void loop() {
    digitalWrite(13, HIGH);
    delayMicroseconds(1136);
    digitalWrite(13, LOW);
    delayMicroseconds(1136);
}
```

Will produce a tone at precisely 440Hz.

This is begging to be made into a function that takes a frequency and returns a
discrete number of microseconds that are equal to have of one cycle. Here it is:

```c
float halfCycleDelay(float freq) {
    return ((1/freq) * 1000000) / 2;
}
```
The math geniuses out there will no doubt note that this can be simplified to:

```c
float halfCycleDelay(float freq) {
    return 500000 / freq;
}
```

I'm returning a float just to retain that precision, though
`delayMicroseconds()` casts it to an int anyway. NBD.

```c
float delay_time = halfCycleDelay(440.0);

void loop() {
    digitalWrite(13, HIGH);
    delayMicroseconds(delay_time);
    digitalWrite(13, LOW);
    delayMicroseconds(delay_time);
}
```
