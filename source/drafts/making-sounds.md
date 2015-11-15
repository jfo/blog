---
title: Making Sounds
layout: post
---

What the hell is sound.

Sound is pressure waves in the air. Wow! that's easy! How does that map to a sine wave at all? Y axis is the pressure of the wave, x axis is time (assuming a fixed point). Let's explain that a little bit more.

How can I make controlled pressure waves in the air? Hey look, a speaker! Speakers are very simple. When they receive current, the electromagnet inside them activates, and pushes the speaker cone out. When they receive current the other way, it pushes in. At rest, it stays at 0. here watch the cone going in and out:

if you listen really closely you can hear a little click when the current is applied, that is the pressure wave moving from the speaker cone to your ears. wow awesome!

picture of cone going in and out.

talk about frequencies... the number of pressure waves per second. (what is a hertz? per second)

let's make a note. I'll start with 440 hz. (don't say anything about the square wave-ness yet.)

talk about arduino, simple arduino code to play a single note. Make note that changing the frequency programmatically would be relatively easy, but probably not do it yet.

but wait, let's see what that wave really looks like. (through d3 or something?) oh no! it is a square wave! This is awful! we want something like a sine wave, smooth, controlled.

here is where we will have to write about the nyquist theorum, sample rates, and what all that shit means. 

how are we going to send a variable amount of energy through the speaker at such an amazingly controlled rate> HOW? 

At first I tried puls width modulation. This would work fine for a led, but because the CARRIER WAVE frequency actually interacts destructively with the output frequency, it sounds like absoulute ASS! Some solutions to this include making a circuit that have a band filter on it, and the carrier freq would be filtered out of that way, but if our goal is hi-fi audio. this is leass than ideal. 

a note here is that we have been using just the output voltage of the arduino, which is also kind of silly. Normally we would want a high-Z output that was consistent and send it through an amplifier, we will probably get to that.

instead of a PWM, which works fine for motors and other things like that, let's explore a concept called an R2R resistance ladder. Incredibly, we get a really clean way to turn binary output into an apporpriate amount of voltage anywhere between 0-1 with an arbitrary max value. the resolution of that is limited only by the bit depth. Right now we're going to use 8 bits, so we should be able to quite easily make sounds that sound like nintendo shit.

but we have to either compute the next sample in a series, OR use a wavetable, OR send in values from an external source (need to use buffers, etc)

maybe mention max mathews and his paper here at some point (-1..1) thing

can we now send a midi file through to the arduino?

maybe now we switch over
