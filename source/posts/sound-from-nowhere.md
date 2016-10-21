---
title: Sound from nowhere
layout: post
date: 2016-10-21
tags: rc
---

"Daisy Bell" was composed by Harry Dacre in 1892. It's one of those 19th
century popular songs with a sticky, saccharine melody... nostalgic even though
nobody alive now remembers that time. There's a musty melancholy to it, like
the memory of a well lived love, long past.

<iframe width="560" height="315" src="https://www.youtube.com/embed/PqvuNb8DevE" frameborder="0" allowfullscreen></iframe>


> In 1961, the IBM 7094 became the first computer to sing, singing the song Daisy
> Bell. Vocals were programmed by John Kelly and Carol Lockbaum and the
> accompaniment was programmed by [Max
> Mathews](http://www.mitpressjournals.org/doi/pdf/10.1162/comj.2009.33.3.9). -
> _from the video description_

<iframe width="560" height="315" src="https://www.youtube.com/embed/41U78QP8nBk" frameborder="0" allowfullscreen></iframe>

> In 1962 Arthur C. Clarke, who wrote the novel – and co-wrote the screenplay for
> the movie – “2001: A Space Odyssey”, visited Bell Labs before putting the
> finishing touches on the work. There, he was treated to a performance of the
> song ‘Daisy Bell’ (or, ‘A Bicycle Built for Two’) by the IBM 704 computer. This
> evidently inspired him to have HAL sing the song as an homage to the
> programmers of the 704 at Bell Labs - _[link](http://www.universetoday.com/44482/why-did-hal-sing-daisy/)_

It's a remarkable moment in a remarkable film, a retreat into "youth" at the
end of "life," and the detail of that particular song is based on the true
story of the first computer to sing, at the infancy of the information age.

<iframe width="560" height="315" src="https://www.youtube.com/embed/OuEN5TjYRCE" frameborder="0" allowfullscreen></iframe>

<hr>
<hr>
<hr>

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/Simple_sine_wave.svg/1024px-Simple_sine_wave.svg.png" />

There is a very quiet room, somewhere around sea level. The room is full of
air. The air is made of particles, of atoms, of different types of gases... it
doesn't really matter. What matters is that all of the particles and atoms and
gases are equidistant from each other, roughly speaking. It is a very quiet
room.

Let's pretend that two disembodied hands clap together one time, suspended in
the very middle of the room. Like two cousins It from the Addam's Family.

Where the hands meet, air moves out of the way. that air bumps into more air,
which bumps into more air, etc. A pressure wave moves from the epicenter (where
the hands met) outward in all directions, until the pressure wave hits the wall
of the now not so quiet room, where it bounces off, again in all directions,
until the wave is dissipated, and the room is once again a very quiet room.

That is what sound is: a bunch of pressure differentials travelling through the
air. This is what we are sensing when we hear anything: music, boiling water,
my neighbor's dogs barking all the time forever and ever... it's all a giant
mess of different pressure waves interacting with each other and the world and
getting to our ears where we process it into brain assembly language.

Let's talk about that wave diagram up there. The X axis is time, and the Y
value is the level of pressure at a static point at that static time. There are
lots of ways to measure this, but it's easiest to think of this pressure being
somewhere between -1 and 1, where 0 would be the room at rest. Just like the
ocean goes below sea level immediately following a wave, a negative pressure
follows the positive, hence, -1

Let's look at a speaker; here's a teeny tiny one:

<img src="https://scontent-lga3-1.cdninstagram.com/t51.2885-15/e35/14717617_620959634751773_6623307970975367168_n.jpg?ig_cache_key=MTM2NTY1OTUxOTUxOTUzMTIwNw%3D%3D.2" />

And here's the back of it:

<img src="https://scontent-lga3-1.cdninstagram.com/t51.2885-15/e35/14547775_1058797607552477_2148373500799221760_n.jpg?ig_cache_key=MTM2NTY1OTkwNTg5MDQxOTU3MA%3D%3D.2" />

I want to point out some important bits. There is a speaker cone. There is a
magnet. There are two nodes on the other side of the back that connect to an
electromagnet inside the speaker. When a current is applied, this electromagnet
becomes charged. You'll hear a little click. This is the sound that the speaker
makes when it is *physically moving*.

The electromagnet, when charged, becomes attracted to the magnet, and pulls the
speaker cone inwards. Here's something I never realized before: If you reverse the
direction of the input current, the speaker cone moves in the opposite
direction! The electromagnet is being attracted instead of being repelled. This
makes perfect sense, but had never occurred to me. I love stuff like that!

Controlling _exactly_ when and how much current is applied to this speaker is how we can
control the sound that is coming out of it.

Let's Arduino!
-------------

We're going to plug the speaker directly into the board. This may seem kind of
silly, but it totally works! The arduino has an output voltage of 5v, which is
not much at all, but it's enough to drive the speaker, and it makes the code
hellah simple.

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
hardware and write bare C for chips someday, that day is not today, so this is
very nice. We just have to write two methods, flash to the board using the IDE,
and the Arduino will work. :sparkles: Rapid indeed! Here is a simple program:

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

The preprocessor will now replace every instance of `OUTPIN` with the value
`13`. This looks similar to variable assignment, but the mechanism underlying
it is very different. All of those replacements happen at (but really _just
before_) compile time, and so a constant should never be redefined after it has
been given a value.

Something like:

```c
#define MYAWESOMECONSTANT "this is what I want my constant to be!"
#define MYAWESOMECONSTANT "wait I changed my mind!"
```

would give us this compile time warning:

```c
/private/tmp/const.c:2:9: warning: 'MYAWESOMECONSTANT' macro redefined
#define MYAWESOMECONSTANT "wait I changed my mind!"
        ^
        /private/tmp/const.c:1:9: note: previous definition is here
#define MYAWESOMECONSTANT "this is what I want my constant to be!"
```

What does the program above do? It writes `HIGH` to the output pin as fast as
it can, forever. `HIGH` is an arduino library constant that resolves to the
maximum output voltage of the model of board you have, so for this one, 5v)

This doesn't really do that much, but you can indeed hear the telltale click
when the program first starts to run, which means that a current _is_ being applied.

Let's change the loop... (`LOW`, as you might guess, is a constant that resolves
to the minimum output of our board, which is 0v):

```c
void loop() {
    digitalWrite(OUTPIN, HIGH);
    digitalWrite(OUTPIN, LOW);
}
```

This does more... I mean, it makes a ... sound. :\

<iframe src="https://vine.co/v/5w11Hdx3Aq5/embed/simple" width="480" height="480" frameborder="0"></iframe>

This loop is writing high and low to the pin as fast as it can. The speaker is
moving back and forth, and we can hear a high pitched, messy squeal as a result.

We want a more control over this, but let's start by making something pretty
close to white noise.

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

With that program, there is a 50/50 chance for either high or low. It sounds like this:

<iframe src="https://vine.co/v/5w11zw1KXAn/embed/simple" width="480" height="480" frameborder="0"></iframe>

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

<iframe src="https://vine.co/v/5w1dBnKBPve/embed/simple" width="600" height="600" frameborder="0"></iframe>

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

<iframe src="https://vine.co/v/5w1JPlIMBt9/embed/simple" width="480" height="480" frameborder="0"></iframe>

Now you have your own shitty, too quiet, incredibly user unfriendly
metronome!

> Why 500ms on each delay, instead of 1000ms? A cycle means that we end where
> we started. Even though this clicks twice a second, it is still only
> completing one cycle per second, and so is still 1Hz. Out, in, and back again.

A 440hz
-------

A musical note is pitched.

A pitch is denoted by a frequency, and a frequency is denoted by a hertz value.
It's really the same thing... 1Hz is once per second, and once per second is a
frequency, in this case of waves per second.

There is a lot more that goes into what a note actually *sounds* like, tonally,
but the fundamental frequency of the wave, usually but not always the lowest
frequency in a sound, is what defines the pitch that we perceive. Take a look at
this chart:

![img](http://www.sengpielaudio.com/FrequenzenKlavier09.jpg)

This is a handy chart mapping a couple of octaves of notes in the middle of the
keyboard with their corresponding frequencies. A pitch is the pitch it is
because it has a specific frequency.

>   these frequencies are only valid as these notes in a single type of tuning
>   system, which is arbitrary. Also, it's all based on starting with A at
>   440hz, which is also arbitrary. Many orchestras conventionally
>   tune to 439 or even 442 as an A natural in that octave, which would change
>   all of these frequencies, which, again, are arbitrary. \</caveats\> Historical and
>   alternative tuning systems are way outside the scope of this post. Maybe
>   I'll write another post sometime about that, it's really fascinating. Did
>   you know old harpsichords were [sometimes constructed](https://en.wikipedia.org/wiki/Split_sharp) with a separate flat and
>   sharp enharmonic keys? I know, wild, right? They are in all actuality different notes, as
>   it turns out. Really good choirs and string sections adjust for this. If
>   you play a piano you're SOL though. Sorry pianists, only one tuning system
>   at a time. Guitar isn't much better, what with the frets and all, but at
>   least we can adjust upwards a little bit. \</digression\>


We've made the speaker move in and out once per second, and we can hear a
percussive click. If we can make it move faster than that, we can make real,
pitched sounds.

> To really hear this transformation from rhythm (those percussive clicks) to
> pitch (where the pace of the clicking rhythm is fast enough to be perceived as
> a pitched note) check out [this excellent
> post](http://dantepfer.com/blog/?p=277) by pianist [Dan
> Tepfer](https://www.youtube.com/watch?v=0Rdb19JG19k):


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

<iframe src="https://vine.co/v/5w119r3zaV3/embed/simple" width="480" height="480" frameborder="0"></iframe>

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

<iframe src="https://vine.co/v/5w1njzB1eEI/embed/simple" width="480" height="480" frameborder="0"></iframe>

> Did I say "will" and "precisely?" I meant "should." It does not. It almost
> does! It's only a few cents flat, but it's not precise. The reason is weird
> and subtle and has to do with the arduino's hardware clock, so I'm going to
> ignore that for now. Let's all just pretend it's accurate, ok? I'll explore
> the specifics in another post.

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
`delayMicroseconds()` casts it to an `int` anyway. NBD.

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
into a argument that is passed into the function:

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

Clearly, to do anything useful, we need to come up with a way to
play a note for some defined amount of time, then maybe play a different note?
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
actually!

<iframe src="https://vine.co/v/5w1nhuxFnXE/embed/simple" width="480" height="480" frameborder="0"></iframe>

Let's review what we have now:

- A reliable way to produce discrete, variable pitches
- for a defined amount of time.

In other words:

- a very simple
- very shrill
- monophonic (only one note at a time)
- _musical instrument_

Now I can make music.

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
chart from before... I'll enter all the _natural notes_ (white keys) into an array.

This code plays two octaves of a C major scale:

```c
float notes[15] = { 130.813, 146.832, 164.841, 174.614, 195.998, 220.000, 246.942, 261.626, 293.665, 329.628, 349.228, 391.995, 440.0, 493.883, 523.251 };

void loop() {
    for (int i = 0, i < 15, i++) {
        square_wave(notes[i], 500);
    }
}
```

<iframe src="https://vine.co/v/5w1vB7FFnaH/embed/simple" width="480" height="480" frameborder="0"></iframe>

Not very beautiful (and still out of tune), but recognizably _musical_.

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

<a href="https://www.instagram.com/p/BLzxOcDlqGr/" target="_blank">Sing oh sing that song little speaker.</a>

<hr>

The arduino code for this is [here](https://github.com/urthbound/soundfromnowhere).

<iframe width="560" height="315" src="https://www.youtube.com/embed/CTnECKaEP6c" frameborder="0" allowfullscreen></iframe>

<script src="https://platform.vine.co/static/scripts/embed.js"></script>
