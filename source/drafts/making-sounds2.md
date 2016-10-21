---
title: Dynamics
layout: post
---

Here, I'm indexing against the array of natural notes from earlier. This is
pretty unwieldy, and I'm missing the chromatic notes, which is very limiting.
Instead, I can define numerical constants that will be interpolated by the
preprocessor as the floats that I want to pass in. That will look something like this:

```c
#define _C1 213.383
#define _Db1 243.383
// etc...
```

We have the note letter name, the octave (0-8) that it is in, and the
frequency that the constant will map to. I'm prefixing them with an `_` to
avoid conflicts with predefined constants in the Arduino standard library.

I'm not going to paste all this in there, but I am going to make a header file
for it and include it in my arduino sketch to allow me to use all of these
labels in my song code.

<a href="https://github.com/urthbound/soundfromnowhere/blob/master/player/notes.h" target="_blank">It's here, if you're curious!</a>

Here's another melody, using those constants:

```c
float buddy_holly[49][2] = {
    {_Ab3,    500.0}, {_F4,    500.0}, {_Eb4,   500.0}, {_C4,     250.0},
    {_Ab3,    250.0}, {_Bb3,   250.0}, {_C4,    250.0}, {_Bb3,    250.0},
    {_Ab3,    250.0}, {_F3,    500.0}, {_Eb3,   500.0}, {_REST,   500.0},
    {_F4,     500.0}, {_Eb4,   500.0}, {_C4,    250.0}, {_Ab3,    250.0},
    {_Bb3,    250.0}, {_C4,    250.0}, {_Bb3,   250.0}, {_Ab3,    250.0},
    {_Bb3,    500.0}, {_REST,  500.0}, {_F3,    500.0}, {_G3,     500.0},
    {_Ab3,    500.0}, {_Bb3,   250.0}, {_C4,    250.0}, {_F3,     250.0},
    {_F3,     250.0}, {_Eb3,   250.0}, {_Eb3,   250.0}, {_Eb3,    125.0},
    {_F3,     125.0}, {_Ab3,   250.0}, {_REST,  500.0}, {_Ab3,    500.0},
    {_F4,     500.0}, {_Eb4,   250.0}, {_C4,    500.0}, {_REST,   250.0},
    {_Ab3,    500.0}, {_REST, 1500.0}, {_Ab3,   500.0}, {_F4,     500.0},
    {_Eb4,    250.0}, {_C4,    500.0}, {_REST,  250.0}, {_Ab3,    500.0},
    {_REST,  1500.0}
};
```

TODO: buddy holly

If you'll notice, we're passing in absolute durations in milliseconds for each
note. This is also kind of unwieldy, unmusical, and hard to change. A more
musical way of approaching this would be to mark each note with a constant
representing a duration, and then modifying the existing ancillary functions to
process that into the appropriate duration given a global tempo.

I can define an `enum` in one of my header files to provide me with the 'marks':

```c
enum durs = { SIXTEENTH, EIGHTH, DOTTED_EIGHTH, QUARTER, DOTTED_QUARTER, HALF, WHOLE }
```

An `enum` is a shorthand way to define numerical constants in C/C++. The above
could be written as:

```c
#define SIXTEENTH       0
#define EIGHT           1
#define DOTTED_EIGHT    2
#define QUARTER         3
#define DOTTED_QUARTER  4
#define HALF            5
#define WHOLE           6
```

As with the note macros defined above, the C preprocessor interpolates these
integer values wherever it sees its associated token. So `EIGHTH` becomes `0`,
and `0` is what the compiler actually sees.

Now I can add a `tempo` argument to the `play_melody()` function, and define a
helper function that computes the value of a rhythmic duration at a given
tempo. Lickity split!

```c
int note_duration(int rhythmic_value, int tempo) {
    // 60000ms in a minute, divided by the tempo in beats per minutes, gives us
    // the absolute duration of a single beat. From there, dividing and
    // multiplying the beat will return the durations of related rhythmic values.

    int one_beat = 60000 / tempo

    switch (rhythmic_value) {
        case : SIXTEENTH
            return one_beat / 4;
        case : EIGHTH
            return one_beat / 2;
        case : DOTTED_EIGHTH
            return (one_beat / 2) * 1.5;
        case : QUARTER
            return one_beat;
        case : DOTTED_QUARTER
            return one_beat * 1.5;
        case : HALF
            return one_beat * 2;
        case : WHOLE
            return one_beat * 4;
    }
}

void play_melody(float melody[][2], size_t size_of_melody, int tempo) {

    int dur = note_duration(melody[i][1], tempo)

    for (int i = 0; i < size_of_melody / (sizeof(float) * 2); i++) {
        square_wave(melody[i][0], dur);
    }
}
```

Now we can represent these notes as a collection of tuples, that semantically
make a little more sense.

instead of `{440.0, 500.0}` to represent an A natural quarter note, we can
write something like `{_A4, QUARTER}` and pass in a global tempo instead of
doing each note duration by hand.

Here's how a melody looks in these tuples:

```c
float happy_birthday[26][2] = {
    { _Db3, DOTTED_EIGHTH }, { _Db3, SIXTEENTH }, { _Eb3, QUARTER }, { _Db3, QUARTER }, { _Gb3, QUARTER }, { _F3, HALF },
    { _Db3, DOTTED_EIGHTH }, { _Db3, SIXTEENTH }, { _Eb3, QUARTER }, { _Db3, QUARTER }, { _Ab3, QUARTER }, { _Gb, HALF },
    { _Db3, DOTTED_EIGHTH }, { _Db3, SIXTEENTH }, { _Db4, QUARTER }, { _Bb3, QUARTER }, { _Gb3, QUARTER }, { _F3, QUARTER }, { _Eb3, QUARTER },
    { _B3, DOTTED_EIGHTH }, { _B3, SIXTEENTH }, { _Bb3, QUARTER }, { _Gb3, QUARTER }, { _Ab3, QUARTER }, { _Gb3, HALF }, { REST, QUARTER }
}

loop() {
    play_melody(happy_birthday, sizeof(happy_birthday), 120);
    play_melody(happy_birthday, sizeof(happy_birthday), 160);
    delay(1000);
}
```

This little instrument never gets tired. It doesn't need to breath, and it can
play notes faster than we can hear them, because you know, it's a computer:

![Hey kid!](https://media.giphy.com/media/5fBH6zxifuuoKgTKB3O/giphy.gif)

```
nonsense computer noise notes with duration at 1μs or something.
```

Not bad for starting from scratch.


```c
flight of the bumble bee
```
There is a problem with our design! We can't control the relative volume of the
notes that we are producing. This is not ideal; dynamics are responsible for a
huge amount of the expressivity of music, and if we're trying to make something
that can produce music, we should be concerned about that.

> Computer music isn't often thought of as "expressive", but I'd invite you to
> consider the fact that when you listen to a recording of a piece that really
> gets to you, you are actually hearing a representation of an event produced by
> the same electronics that, in a vacuum, invite criticism of unemotional-ness.

So, we need to figure out a way to modulate how much energy is being sent to
the speaker! Up until now I've been using a digital output pin which can
only output `HIGH` and `LOW`, essentially 1 or 0, which on the Arduino Uno is 5
volts for `HIGH` and 0 volts for `LOW`

Some cursory googling will reveal an arduino library function named
[`analogWrite()`](https://www.arduino.cc/en/Reference/AnalogWrite), which would
appear to be _exactly_ what we need, so [spoiler alert, it is not what we need
but] let's try it out [anyway]!

I can adjust the code from the very first wave example from before from:

```c
void loop() {
    digitalWrite(OUTPIN, HIGH);
    delayMicroseconds(1136);
    digitalWrite(OUTPIN, LOW);
    delayMicroseconds(1136);
}
```
to:

```c
#define OUTPIN [an analog pin no]

void loop() {
    analogWrite(OUTPIN, 255);
    delayMicroseconds(1136);
    analogWrite(OUTPIN, 0);
    delayMicroseconds(1136);
}
```

TEST WHETHER HIGH AND LOW WORK at all

[Though we can use the `HIGH` and `LOW` constants here if we want to], it's
more instructive to skip that step and show the equivalent `255` for `HIGH` and
`0` for `LOW`. Notice also that I've changed the outpin; only some of the pins
on the board support this operation, some of them are digital only pins.
`analogWrite()` takes an integer between 0 and 255 (that's a one
byte value for those playing along at home) and outputs an analog equivalent
voltage between 0v and 5v. Like I said, sounds like exactly what I
wanted! Given that, this code should play the same tone at about half the
volume:

```c
void loop() {
    analogWrite(OUTPIN, 127);
    delayMicroseconds(1136);
    analogWrite(OUTPIN, 0);
    delayMicroseconds(1136);
}
```
And here, it does:

GROSS

Wait no it doesn't wtf?!

Why this doesn't work
---------------------

Arduino's `analogWrite()`-able pins use a technique called 'pulse width
modulation', or PWM, to approximate analog output. If you send `0` or `255` as
the value, it does the same this that `digitalWrite()` does for `HIGH` and
`LOW`, respectively.  any number in between, though, and it oscillates between
0 and 255 very very quickly, and adjusts the _duty cycle_ of the output to
approximate an analog value.

So, if I output a steady `analogWrite(127)` like this:

```c
void loop() {
    analogWrite(OUTPIN, 127);
}
```

I'm actually outputting `255`, or `HIGH`, half the time, and `LOW`, or `0`, the
other half of the time. Similarly, some value like `analogWrite(50)` would be
`HIGH` _about_ 1/5th of the time and `LOW` 4/5ths of the time. They would look like this:

PHOTO

If this sounds familiar, it's because it is doin exactly the same thing as we
are manually doing when we are creating a wave!  The 'pulse' in 'pulse width
modulation' _is a square wave itself_. You might be able to guess now, why the
"analog" output of out wave above wasn't working, because the wave we're trying
to output is interfering with the _carrier wave_ of the pulse width modulation.

On an arduino uno's 'analog' pins, 490hz. is the standard carrier wave, so if
we just `analogWrite(127);` continuously, like above, we can hear that
frequency come out of the speaker:

This works great for lights, because our eyes aren't sensitive enough to notice
the flickering, and we perceive it as a dimmed light.

It also works for motors:

which move too slowly to physically react to the the rapid oscillations.

Our ears, though, are particularly sensitive to oscillations in this range, and
the speaker itself is extremely sensitive to the changes as well. There are
clever ways to get around this... you can set the carrier wave frequency to be
high above human hearing range (which is, at most, ~20Hz to ~20000Hz) for
example.  At 60000Hz, the pulse width effect can be achieved without being
audible. This is awesome! But I'm interested in true digital to analog
conversion, so I'm going to do something else.

<hr>

Instead of a PWM, let's explore a thing called an R2R resistance ladder, which looks like this:


This turns out to be a really clean way to turn multiple-bit binary output into
an _actually analog_ amount of voltage between whatever `HIGH` and `LOW` is.

Here's how it works. It has 8 digital inputs, and 1 analog output. The first
input goes through three resistors, effectively halving it's output. So if it's
outputting a steady stream of 5v, after going through those two resistors it
would be outputting 2.5v. The next input goes through these same 3 resistors,
but _also_ goes through two more, halving that as well, _again_. The first, or
_most significant bit_ input is worth 2.5v, and the second most significant bit
input is worth 1.25v. Stopping there, with a two bit version, we could
potentially output any of these 4 values:

```
00 = 0v
01 = 1.25v
10 = 2.5v
11 = 3.75v
```

The more bits we have, the higher the resolution of our output and the more
precise we can be, by using different combinations of the output pins. I'm
attempting an 8 bit analog output, which would mean the eight pins would be
worth about this much each (zero indexed):

```
0 = 2.5 volts
1 = 1.25 volts
2 = 0.625 volts
3 = 0.3125 volts
4 = 0.15625 volts
5 = 0.078125 volts
6 = 0.0390625 volts
7 = 0.01953125 volts
```

but we have to either compute the next sample in a series, OR use a wavetable,
OR send in values from an external source (need to use buffers, etc)

maybe mention max mathews and his paper here at some point (-1..1) thing

can we now send a midi file through to the arduino?

maybe now we switch over
