---
title: Dynamics
layout: post
---

There is a problem with our design! We can't control the relative volume of the
notes that we are producing. This is not ideal; dynamics are responsible a huge
amount of the expressivity of music, and if we're trying to make something that
can produce music, we should be very concerned about that.

Computer music isn't often thought of as "expressive", and usually for good
reasons. But I'd invite you to consider the fact that when you listen to a
recording of a piece that really gets to you, you are really hearing a
representation of an event produced by the same electronics that, in a vacuum,
invite criticism of unemotional-ness.

So, we need to figure out a way to modulate how much energy is being sent to
the speaker! If you'll recall, the 

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
