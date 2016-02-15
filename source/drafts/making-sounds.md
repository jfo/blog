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
but the IDE / Compiler / toolchain takes care of all the heavy lifting with
regard to linking libraries and compiling binaries and flashing the chip on the
board with the new firmware and all that.  We just need to worry about a single
`.ino` file that implements two functions:

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

The arduino has other output pins, it doesn't have to be 13. And we hates us
some magic numbers, so might as well make that into a constant:

```c
#define OUTPIN 13

void setup() {
    pinMode(OUTPIN, OUTPUT);
}

void loop() {
    digitalWrite(OUTPIN, HIGH);
}
```

The C preprocessor will now replace every instance of `OUTPIN` with the value
`13`. This looks similar to variable assignment, but the mechanism underlying
it is very different. All of those replacements happen at compile time, and so
a constant should never be redefined after it has been given a value.

Consider:

```c
#define MYAWESOMECONSTANT "this is what I want my constant to be!"
#define MYAWESOMECONSTANT "wait I changed my mind!"
```

Gives us this compile time warning:

```c
/private/tmp/const.c:2:9: warning: 'MYAWESOMECONSTANT' macro redefined
#define MYAWESOMECONSTANT "wait I changed my mind!"
        ^
        /private/tmp/const.c:1:9: note: previous definition is here
#define MYAWESOMECONSTANT "this is what I want my constant to be!"
```

What does the program above do? It writes `HIGH` to the output pin as fast as
it can, forever. `HIGH` is an arduino constant just like the that resolves to
the maximum output voltage of the model of board you have, so for this one, 5v)

This doesn't really do that much, but you can indeed here the telltale click:

... which means that a current is being applied.

Let's change our loop... (`LOW`, as you might guess, is a constant that resolves
to the minimum output of our board, which is 0v):

```c
void loop() {
    digitalWrite(OUTPIN, HIGH);
    digitalWrite(OUTPIN, LOW);
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
        digitalWrite(OUTPIN, HIGH);
    } else {
        digitalWrite(OUTPIN, LOW);
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

[Wikipedia!](https://en.wikipedia.org/wiki/Hertz)

Using hertz (symbol Hz) as a unit is agnostic; it can refer to anything.
A light that flashes once a second is flashing at 1Hz.

Let's make this speaker "flash" at once per second:

```c
void loop() {
    digitalWrite(OUTPIN, HIGH);
    digitalWrite(OUTPIN, LOW);
    delay(1000);
}
```

(`delay()` takes an int that represents milliseconds, so this is one second)

You can hear it clicking, once per second, but it is very quiet. Look close at
what this is doing: it writes `HIGH` and then writes `LOW` as fast as it can,
and then waits a second before doing it again. There might be a better way; the
cone likely isn't even getting all the way out before being pulled back in.

Recall that the speaker cone clicks when it goes in, AND when it goes out.

```c
void loop() {
    digitalWrite(OUTPIN, HIGH);
    delay(500);
    digitalWrite(OUTPIN, LOW);
    delay(500);
}
```

Now you have your own shitty, too quiet, incredibly user unfriendly
metronome!

> Why 500ms on each delay, instead of 1000ms? A cycle means that we end where
> we started. Even though this clicks twice a second, it is still only
> completely one cycle per second, and so is still 1Hz. Out, in, and back again.

A 440hz
-------

A musical note is pitched. A pitch is denoted by a frequency, and a frequency
is denoted by a hertz value. There is a lot that goes into what it actually
*sounds* like, tonally, but the fundamental frequency of the wave, usually the
lowest or perceived frequency in a sound,is what defines the pitch that we
hear. Take another look at this chart:

![img](http://www.sengpielaudio.com/FrequenzenKlavier09.jpg)

This is a handy chart mapping a couple of octaves of notes in the middle of the
keyboard with their corresponding frequencies. A pitch is the pitch it is
because it has a specific frequency; in many ways "pitch" and "frequency"
describe the exact same thing! *

> * these frequencies are only valid as these notes in a single type of tuning
>   system, which is arbitrary. Also, it's all based on starting with A at
>   440hz, which is also arbitrary. Many european orchestras conventionally
>   tune to 439 or even 442 as an A natural in that octave, which would change
>   all of these frequencies, which are arbitrary. \</caveats\> Historical and
>   alternative tuning systems are way outside the scope of this post. Maybe
>   I'll write another post sometime about that, it's really fascinating. Did
>   you know old harpsichords were sometimes constructed with a separate Eb and
>   D# key? I know, wild, right? They are in all actuality different notes, as
>   it turns out. Really good choirs and string sections adjust for this. If
>   you play a piano you're SOL though. Sorry pianists, only one tuning system
>   at a time. Guitar isn't much better, what with the frets and all, but at
>   least we can adjust upwards a little bit. \</digression\>


We've made the speaker move in and out once per second, and we can hear a
percussive click. If we can make it move faster than that, we can make real,
pitched sounds.

To really hear this transformation from rhythm (those percussive clicks) to
pitch (where the pace of the clicking rhythm is fast enough to be perceived as
a pitched note) take a second to check out this excellent post by pianist Dan
Tepfner:

http://dantepfer.com/blog/?p=277

Let's try having it wait just 1 millisecond between `HIGH` and `LOW`...

```c
void loop() {
    digitalWrite(OUTPIN, HIGH);
    delay(1);
    digitalWrite(OUTPIN, LOW);
    delay(1);
}
```

This is one cycle every two milliseconds, which is 500 cycles per second, which
is 500Hz. Cross referencing with the chart above, our speaker should be
producing a note about 6.12Hz faster than a B above middle C. Let's see:

Super. We're almost to something musically useful. This is as fast as we can go
using `delay()` because it takes milliseconds. In order to delay a smaller
amount between `HIGH` and `LOW` we would need to delay for a shorter period
than 1ms. Luckily, we can:

```c
void loop() {
    digitalWrite(OUTPIN, HIGH);
    delayMicroseconds(1000);
    digitalWrite(OUTPIN, LOW);
    delayMicroseconds(1000);
}
```

This code is a refactor of the loop above. A millisecond is 1/1000th of a
second, but a microsecond is 1/1000th of a millisecond. We're in the
millionth's of a second here, and so can be a lot more precise!

We want to produce a tone at 440Hz, which means we will complete 440
cycles per second, and that each single cycle will take 1/440 of a second.

```
1/440 = 0.0022727...
```

Or more descriptively: One second divided into 440 sections is equal to
0.002227... seconds. That is equal to 2.227... milliseconds.

But a millisecond has a thousand microseconds in it, so this is equal to

```
2.2727... * 1000 = 2272.7272...
```

Since we can't pass floats (numbers with decimal places) into
`delayMicroseconds`, I'll floor that to 2272μs.  (The symbol for microseconds
is `μs`, which I didn't know until just now when I looked it up.)

Remember that to complete one complete cycle, we have to write `HIGH`, then
wait for 1/2 a cycle, then write `LOW`, then wait for the remaining half. Half
of 2272μs is 1136μs, so:

```c
void loop() {
    digitalWrite(OUTPIN, HIGH);
    delayMicroseconds(1136);
    digitalWrite(OUTPIN, LOW);
    delayMicroseconds(1136);
}
```

Will produce a tone at _precisely_ 440Hz.

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
void loop() {
    float delay_time = halfCycleDelay(440.0);
    digitalWrite(OUTPIN, HIGH);
    delayMicroseconds(delay_time);
    digitalWrite(OUTPIN, LOW);
    delayMicroseconds(delay_time);
}
```

This is a nice little thing to encapsulate, so I'm going to do that, and there
is no reason not to make the frequency that I'm computing the delay time for
into a argumanet that is passed into the function:

```c
void square_wave(float freq) {
    float delay_time = halfCycleDelay(freq);
    digitalWrite(OUTPIN, HIGH);
    delayMicroseconds(delay_time);
    digitalWrite(OUTPIN, LOW);
    delayMicroseconds(delay_time);
}

void loop() {
    square_wave(440.0);
}
```

So, a couple of things here... first, that name. I'm calling that function
`square_wave()` because that's the type of wave that is being produced. More on
that later. Also, notice that every loop is calling `square_wave()`,
which is calling `halfCycleDelay()`, which is doing some computations. I don't
really need to do that on every loop, it would seem better to do something like
this:

```c
void square_wave(float delay_time) {
    digitalWrite(OUTPIN, HIGH);
    delayMicroseconds(delay_time);
    digitalWrite(OUTPIN, LOW);
    delayMicroseconds(delay_time);
}

float delay = halfCycleDelay(440.0)

void loop() {
    square_wave(delay);
}
```

But I'm not going to do that, for reasons that will be clear in a moment.

This would make a great summer single: "The indefinite square wave", by Katy
Perry. You could pick a frequency and it would just go forever. It's got hit
written all over it.

Clearly, to do anything useful, we need to come up with a way to
play a note for some definite amount of time, then maybe play a different note?
I don't know, just a thought. Variety is the spice of life. Let's start
with.... one second.

Arduino provides a nice little function to check the number of milliseconds
since the board started running: `millis()`. By comparing the return value of
this function when we call it in different places, we can keep track of
relative time inside a function.

```c
void square_wave(float freq){
    float delay_time = halfCycleDelay(freq);
    unsigned long start_time = millis();

    while(millis() < start_time + 1000) {
        digitalWrite(OUTPIN, HIGH);
        delayMicroseconds(delay_time);
        digitalWrite(OUTPIN, LOW);
        delayMicroseconds(delay_time);
    }
}

void loop() {
    square_wave(440.0);
    delay(1000);
}
```

This one just beeps an A 440 for one second, and then waits for one second so
that we can hear when the notes stops and starts. This is very exciting,
actually! Let's review what we have now:

- A reliable way to produce discrete, variable pitches
- for a defined amount of time.

In other words:

- a very simple
- very shrill
- monophonic (only one note at a time)
- _musical instrument._

Now we can make some music.

There is no reason to hard code the length of the note, though, so lets change that function a little bit:

```c
void square_wave(float freq, int duration){
    float delay_time = halfCycleDelay(freq);
    unsigned long start_time = millis();

    while(millis() < start_time + duration) {
        digitalWrite(OUTPIN, HIGH);
        delayMicroseconds(delay_time);
        digitalWrite(OUTPIN, LOW);
        delayMicroseconds(delay_time);
    }
}
```

`duration` here is in milliseconds. Let's play a scale; recall that frequency
chart from before... let's enter all the _natural notes_ (white keys) into an array.

This code plays two octaves of a C major scale:

```c
float notes[15] = { 130.813, 146.832, 164.841, 174.614, 195.998, 220.000, 246.942, 261.626, 293.665, 329.628, 349.228, 391.995, 440.0, 493.883, 523.251 };

void loop() {
    for (int i = 0, i < 15, i++) {
        square_wave(notes[i], 500);
    }
}
```

Not very beautiful, but recognizably _musical_.

We can represent notes as tight little frequency/duration tuples, packed into
an array. When initializing such a `2d` array, the first number in brackets
represents the number of elements in the array and the second the number of
elements in each subarray. All of the sub arrays must have the same number of
elements in them.

```c
float c_major_trid[3][2] = {
    {261.626, 500.0},
    {329.628, 750.0},
    {391.995, 250.0}
}
```

This is an ugly. verbose way to represent melodic information, and there are
many many better and more semantic ways to do so, but for now it has the
advantage of being very straightforward and very simple, based on what we've
talked about so far. A melody is an array consisting of tuples. Each tuple
represents a "note", where the first value represents the frequency of the note
and the second value represents the duration of the note.

We do have a problem - how do we represent rests? It kind of makes
sense to pass `0` into the `square_wave()` function to represent a rest,
because a frequency of `0hz` would indeed be silence. This is a nice
coincidence, because we need to prevent the failure case of division by
zero in the `halfCycleDelay()` call, which would trigger a runtime error if we
passed `0` into `square_wave()` currently.

Let's tweak `square_wave()` to simply delay for the passed in duration in the
event of a `0` frequency.

```c
void square_wave(float freq, int duration){
    if (freq == 0) {
        delay(duration);
    } else {
        float delay_time = halfCycleDelay(freq);
        unsigned long start_time = millis();

        while(millis() < start_time + duration) {
            digitalWrite(OUTPIN, HIGH);
            delayMicroseconds(delay_time);
            digitalWrite(OUTPIN, LOW);
            delayMicroseconds(delay_time);
        }
    }
}
```

Now we have an easy way to trigger silence, and we've accounted for that edge
case, as well.

Let's abstract a function that accepts a "melody" and "plays" it! We also have
to explicitly pass in the size of the array that is holding the melody, because
of the way C treats local bindings. That gets a little hairy, just know right
now that `size_of_melody` is telling `play_melody` how many notes and rests in
total to play before exiting the `for` loop.

```c
void play_melody(float melody[][2], size_t size_of_melody) {
    for (int i = 0; i < size_of_melody / (sizeof(float) * 2); i++) {
        square_wave(melody[i][0], melody[i][1]);
    }
}
```

Now that we have this little function, we can just feed it a "melody" in the correct format, and it will play it!

```c
//                  C        D        E        F        G        A        B        C        D        E        F        G        A      B        C
//                  0        1        2        3        4        5        6        7        8        9        10       11       12     13       14
float notes[15] = { 130.813, 146.832, 164.841, 174.614, 195.998, 220.000, 246.942, 261.626, 293.665, 329.628, 349.228, 391.995, 440.0, 493.883, 523.251 };

float my_bonnie_lies_over_the_ocean[][2] = {
    {notes[4], 500},
    {notes[9], 750},
    {notes[8], 250},
    {notes[7], 500},
    {notes[8], 500},
    {notes[7], 500},
    {notes[5], 500},
    {notes[4], 500},
    {notes[2], 1000},
    {0.0,      1000},
    {notes[4], 500},
    {notes[9], 750},
    {notes[8], 250},
    {notes[7], 500},
    {notes[7], 500},
    {notes[6], 500},
    {notes[7], 500},
    {notes[8], 1500},
    {0,        1500},
    {notes[4], 500},
    {notes[9], 750},
    {notes[8], 250},
    {notes[7], 500},
    {notes[8], 500},
    {notes[7], 500},
    {notes[5], 500},
    {notes[4], 500},
    {notes[2], 1000},
    {0.0,      1000},
    {notes[4], 500},
    {notes[5], 500},
    {notes[8], 500},
    {notes[7], 500},
    {notes[6], 500},
    {notes[5], 500},
    {notes[6], 500},
    {notes[7], 1500},
    {0.0,      1000}
}

void loop() {
    play_melody(my_bonnie_lies_over_the_ocean, sizeof(my_bonnie_lies_over_the_ocean));
}
```

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
play notes faster than we can hear them:

```
nonsense white noise notes with duration at 1μs or something.
```

Here's a wicked fast flight of the bumblebee:

```c
flight of the bumble bee
```

Here's Van Halen's sick masterpiece, Eruption:

```c
```

Not bad for a couple wires and a few chips.

I've made a repo of all of the code and music from this post here:

github.com balhablah

Next time: [brief synopsis of next time]

fuck yeah mother fucker.
