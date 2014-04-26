---
title: Into the cloud- a quick AWS primer
date: 2014-04-26 17:54 UTC
layout: post
tags:
---

Amazon Web Services used to scare the hell out of me.

There are **so many things to click on all the time everywhere**. Is this what I want? That? This? Everything is an abbreviation or an acronym and the UX feels like the table of contents for a technical manual. And the very first thing they ask for is your credit card information.

Wait- I thought this was free? Or something? Didn't someone say this was free? What?

Errrmgh, yes and no. Mostly yes... you just have to click on the right things. But also no... my bill last month was for nine cents, which hardly breaks the bank, but does officially qualify as "not free." It took me a few attempts to get through the process... I would give up at some obscure menu or get spooked by the credit card info part. It wasn't until Tom Ballinger sat down with and gave me a walk through that I realize how easy it is to get set up.

I've since helped quite a few of my fellow batchlings with the same process, so I thought it would be worthwhile to write a post about it. As of now, all this information is accurate. If you're reasonably comfortable on the command line, then in 20 or so minutes you too can have access to a virtual linux box up in the "cloud" for basically nothing (caveats ahead though!). This is going to be pretty step by step, but let me know if I miss anything or if anything is slightly unclear.

<h4>Step one: get an account.</h4>

This one is pretty easy, but has a couple gotchas. Go [here](http://aws.amazon.com/) and click on "sign up." Yes, I know you have an Amazon account already probably. Isn't it the same account then? Why do I need to put in my credit card info right now? I signed in with the other account... uh...? Yeah it's fine. It is the same/new account.

Now for the main reason AWS scared me off so many times. You give them your credit card right now at the beginning, and they can charge you if you go over their free usage tier. Yikes! This makes AWS **not ideal** for any project that you are expecting to receive a moderate amount of non-commercial traffic for. If you're just playing around with the process and trying to learn about how to do some sysadmin-y things, great! Also: great! if you have a project which will generate some income via its traffic. But there is a large use case in between those that does kind of give me the creeps. What about the slim chance that I accidentally write a hit blog post? Am I going to get slammed with a huge bill? Or make a little app that goes viral or something... these possibilities exists, and if you  are worried about them you should look into Heroku, or Github pages, or even something like Linode that has a fixed fee (more on that later.)

But if you want to fiddle and have the freedom to spin up and destroy VM's on a whim while learning about the process, AWS fits the bill. As long as you don't keep more than one instance running at a time and are judicious about what you host and how you share it, you won't get blasted. Tom showed me his account history, and most months were less than 25 cents. The largest bill he ever got was for 100 dollars, and that was a month that he was hosting a Minecraft server.


