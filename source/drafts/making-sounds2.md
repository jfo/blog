---
title: Dynamics
layout: post
---

There is a problem with our design! We can't control the relative volume of the
notes that we are producing. This is not ideal; dynamics are responsible a huge
amount of the expressivity of music, and if we're trying to make something that
can produce music, we should be concerned about that.

Computer music isn't often thought of as "expressive", but I'd invite you to
consider the fact that when you listen to a recording of a piece that really
gets to you, you are actually hearing a representation of an event produced by
the same electronics that, in a vacuum, invite criticism of unemotional-ness.

So, we need to figure out a way to modulate how much energy is being sent to
the speaker! Up until now we have been using a digital output pin which can
only output `HIGH` and `LOW`, essentially 1 or 0, which on the Arduino Uno is 5
volts for `HIGH` and 0 volts for `LOW`

Some cursory googling will reveal an arduino library function named
[`analogWrite()`](https://www.arduino.cc/en/Reference/AnalogWrite), which would
appear to be _exactly_ what we need, so [spoiler alert, it is not what we need
but] let's try it out [anyway]!

We can adjust the code from the very first wave example from before from:

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
`LOW`.  any number in between, though, and it oscillates between 0 and 255...

explain the rest of PWM.

If this sounds familiar, it's because it is doin exactly the same thing as we
are manually doing when we are creating a square wave!

490hz. is the standard carrier wave, so if we just `analogWrite(127);`
continuously, we can hear that frequency come out of the speaker:

This works great for lights, which are too fast for our senses to detect the
flicker, and for motors, which move too slowly to react to the the rapid
oscillations. 

here is where we will have to write about the nyquist theorum, sample rates,
and what all that shit means.

how are we going to send a variable amount of energy through the speaker at
such an amazingly controlled rate> HOW?

At first I tried puls width modulation. This would work fine for a led, but
because the CARRIER WAVE frequency actually interacts destructively with the
output frequency, it sounds like absoulute ASS! Some solutions to this include
making a circuit that have a band filter on it, and the carrier freq would be
filtered out of that way, but if our goal is hi-fi audio. this is leass than
ideal.

a note here is that we have been using just the output voltage of the arduino,
which is also kind of silly. Normally we would want a high-Z output that was
consistent and send it through an amplifier, we will probably get to that.

instead of a PWM, which works fine for motors and other things like that, let's
explore a concept called an R2R resistance ladder. Incredibly, we get a really
clean way to turn binary output into an apporpriate amount of voltage anywhere
between 0-1 with an arbitrary max value. the resolution of that is limited only
by the bit depth. Right now we're going to use 8 bits, so we should be able to
quite easily make sounds that sound like nintendo shit.

but we have to either compute the next sample in a series, OR use a wavetable,
OR send in values from an external source (need to use buffers, etc)

maybe mention max mathews and his paper here at some point (-1..1) thing

can we now send a midi file through to the arduino?

maybe now we switch over
