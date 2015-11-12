---
title: monome part bi
date: 2015-05-16 02:09 UTC
layout: post
tags: hs, monome, music, programming
---


In the last post I talked about figuring out what signals are coming from the monome when I press buttons. The obvious next goal is to find out what signals I can send _to_ the monome.

I'd like to say I reverse engineered this bit, too, but I'd be lying. I assumed it would follow a similar pattern of 3 bytes per signal- x and y coordinates and an on or off byte, in some kind of order or another, but I didn't want to start guessing. To check my intuition, I instead turned to the [protocol itself](http://monome.org/docs/tech:serial). I was right, for the most part.

The document linked to above, I suppose, is pretty comprehensive. It details the [OSC](http://opensoundcontrol.org/introduction-osc) grammar in addition to the bare byte serial one I was looking for. OSC seems really robust and awesome, and I imagine when I actually start writing useful things for the monome it will be using that, but I don't know anything about it yet.

Around line 30 or so, under "led-grid", I found what I was looking for. There are a lot of options for setting the leds to 'on' and 'off', mostly in terms of groupings. Though I am most interested in controlling one light at a time, one option did catch my eye... to control all the lights at one time, you only have to send a single byte! `\x13` for on or `\x12` for off. Cool!

I've already established that it's pretty easy to send data to the device by writing directly to the file that shows up in `/dev/`, so let's try that. bash represents hex like `\x..` where "." is some digit `0-f`. How about...

```bash
echo "\x13" > dev/tty.usbserial-m1000065
```

Hey, this worked! The whole grid lights up!

![A lit up monome](https://igcdn-photos-b-a.akamaihd.net/hphotos-ak-xaf1/t51.2885-15/11271045_1648449182043465_1140557603_n.jpg)

Now I'll try to turn it off

```bash
echo "\x12" > dev/tty.usbserial-m1000065
```

Hmm. Nothing. It just sits there, brightly mocking me. Oh and when I unplug it and plug it back in to reset, sometimes it crashes my computer, so that's not great. Turns out `echo` appends a newline character ("\n") to whatever you pass to it (for completely reasonable reasons, I'm sure), so I was actually sending _two_ bytes to the monome, the latter of which it didn't know what to do with. A `-n` flag will remove that newline:

```bash
echo -n "\x12" > dev/tty.usbserial-m1000065
```

Or, alternately, `printf` doesn't append a newline at all:

```bash
printf "\x12" > dev/tty.usbserial-m1000065
```

Really, anything that gets those bytes into standard out will work just fine, there are probably a bunch of other utilities that do this in some capacity.

According to the protocol, if I want to control individual leds, I send a _different_ on or off byte ("\x11" and "\x10", respectively) followed by the x and y coordinates of the button I'm targeting. So, if I want to turn on the first led:

```bash
echo -n "\x11\x00\x00" > dev/tty.usbserial-m1000065
```

or turn it off:

```bash
echo -n "\x10\x00\x00" > dev/tty.usbserial-m1000065
```
Now that I have a basic vocabulary with which to communicate in both directions with the device, I'm ready to write my first "application" for it. It's going to be so cutting edge, y'all, like when I push a button the light is going to come on, and when I release the button, the light is going to go off it's going to be so awesome oh wow.

Because we're talking over serial here, any language with a serial protocol library (so I guess all of them, right?) can be used. Here's "turn all the lights on, then wait a second, then turn all the lights off" in Ruby...

First I'll set up the port object (that I'll be using for the rest of the post)

```ruby
require 'serialport'
ser = SerialPort.new("/dev/tty.usbserial-m1000065", 9600)
```
[Serialport](https://rubygems.org/gems/serialport/versions/1.3.1) is a serial comm library, as you might have been able to guess. The `9600` being passed into the object initializer is the [baud rate declaration](http://en.wikipedia.org/wiki/Baud) for that now open port. `9600` is plenty fast for this right now.

Then write the bytes to the port:

`<blink>`!

```ruby
ser.write("\x13")
sleep 1
ser.write("\x12")
```

`</blink>`!

Basically, I want to write a server that listens to this port and responds to signals with an instruction to do a thing based on that signal. The server is an open ear, patiently running on a loop until it hears something that it knows what to do with.

There are various methods and ways to get data into the program, but for now I'm going to use the Serialport class's `getc` method, which attempts to read just one character from the stream. (This is a method of Ruby's `IO` class, which is `SerialPort`'s direct parent).

Here is a loop that prints the input to the screen:

```ruby
loop do
    print ser.getc
end
```

And it's our old friend "!"! This little program, by the way, acts exactly like `cat`ting the device file from the prompt. I've a little more facility in this context, though, so lets get it to print something that makes sense. This is just a matter of formatting... how about the hex values, since that's what we've been looking at thus far?

```ruby
loop do
    puts ser.getc.ord.to_s(16)
end
```

`ord` converts the input to its bitwise numerical value (in decimal) and `to_s(16)` changes the type from a decimal int to a string representing the value of the int you've called it on in the base of the arg you pass to it.

I know, this one is pretty confusing, but:

```ruby
7.to_s(16) # 7
8.to_s(16) # 8
9.to_s(16) # 9
10.to_s(16) # a
11.to_s(16) # b
12.to_s(16) # c
13.to_s(16) # d
14.to_s(16) # e
15.to_s(16) # f
16.to_s(16) # 10
17.to_s(16) # 11
18.to_s(16) # 12
19.to_s(16) # 13
```

etc... or

```ruby
7.to_s(2) # 111
8.to_s(2) # 1000
9.to_s(2) # 1001
10.to_s(2) # 1010
11.to_s(2) # 1011
12.to_s(2) # 1100
13.to_s(2) # 1101
14.to_s(2) # 1110
15.to_s(2) # 1111
16.to_s(2) # 10000
17.to_s(2) # 10001
18.to_s(2) # 10010
19.to_s(2) # 10011
```

Step last is simply to respond to a button press with a signal to turn that button's light on, and a button release to turn that button's light off.

```ruby
loop do
    thinger = ser.getc().ord.to_s(16)
    if thinger == "21"
        x = ser.getc
        y = ser.getc
        ser.write("\x11" + x + y)
    elsif thinger == "20"
        x = ser.getc
        y = ser.getc
        ser.write("\x10" + x + y)
    end
end
```

And it pretty much does what I wanted now! Except, it misses a lot of events, and if you press or release a lot of buttons at one time, it will miss a lot of those as well, but this is most probably a consequence of the single threadedness of the above loop, and the fact that the signal from a button press could be lost while the program is executing other code besides the primary loop...

There are a lot of problems with this model, actually, but they are problems that have no doubt been dealt with and optimized in the standard and/or mostly-in-use IO libraries for the monome, like [libmonome](https://github.com/monome/libmonome) which I'll probably be switching over to now that I kind of feel like I get the gist of how this protocol works. This was fun to figure out though.

`<blink></blink>`!
