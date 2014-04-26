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

But if you want to fiddle and have the freedom to spin up and destroy VM's on a whim while learning about the process, AWS fits the bill. As long as you don't keep more than one instance running at a time and are judicious about what you host and how you share it, you won't get blasted. Tom showed me his account history, and most months were less than 25 cents. The largest bill he ever got was for 100 dollars, and that was a month that he was hosting a Minecraft server, which is most likely not something you can easily do accidentally.

But do take care to select the "free tier." They will try to upsell you: my favorite is the page that says that the free tier has "very poor" transfer rates. Ok I get it, it's free after all, but it's totally adequate for pooping around with, so don't sweat it.

<h4>Step One.5: click on the right thing.</h4>

This one doesn't really deserve a whole step, but it does deserve special mention. After you sign up for an account, you'll sign in to the account. And then I think you have to click on "My account" and then "AWS Management Console." Then you will be greeting with exactly 1287 icons with inexplicable letters next to them. Many of them are, I'm sure, very useful, if you know what they do. Even if you know what they do, they are all named by acronyms, or cutesy Amazon specific names, or both. **All I wanted was shell access to a VM.** If that is what you want, too, then click on:

<h2>EC2</h2>

Again: that is the second icon in the list that looks like a squished screw or a dumbbell with no bar in the middle of it or a server farm (I guess) and it says

<h2>EC2- Virtual Servers in the Cloud</h2>

Great, moving on.

<h4>Step Two: Create and Launch an Instance</h4>

Amazon's free tier gives you something like 750 hours of free computation time a month, which is a hair over 31 days worth. Enough for even August! Wow! If you keep one instance up all the time, you won't exceed that number ever, because math. BUT, you could also spread them out. If you want to run 2 machines simultaneously for 375 hours each and then cut them off, you can do that. If you want to run 750 machines for an hour each all at once, or 45,000 machines for a minute, then I guess you could do that, also, but you'll be tempting the fates. As long as you don't have more than one instance running at a time, you won't be charged for computation time during the first year.

So with that in mind, click that big button that says **launch instance**. Now pick an OS. I picked Ubuntu, because I've worked with it before, so the rest of this post will assume you did, too. Should work about the same with any Linux distro though. Just make sure that it is labeled "Free tier eligible."

Now select "Micro Instance." Which is the only option that is free tier eligible on the next page. Ignore the upselling and the "Very Low" network performance. It's fine. You're not writing Twitter right now, and your blog doesn't need to scale.

There are a few more configuration options steps, but I would just ignore them and go ahead and launch it. We'll get to the important ones in a moment, and it's mostly more upsells.

So launch! Boom!

<h4>Step Three: connecting to your VM</h4>

On the left side of the page, click "Instances." You'll have a list of your running instances, which right now is just the one that you just launched. Select the instance with the little box next to it to get some info. Again, there is lot of info there, but right now, the only thing we need is the **Public IP**. Take out a pen and paper and write that down. Just kidding. Or do that, if you want. Just, hold on. We're going to need that number in a second.

Now comes the commandlinefu part. Open a terminal and type "which ssh." Did it say /usr/bin/ssh? Or something like that? Great, you've got SSH already. I thought you might! If you don't you can brew install it, or apt-get install it. 

Type this:

```
yourawesomeprompt$ ssh [your public IP]
```

Did it work? No? Haha, fooled you! that was a learning experience! What kind of service would it be if you could just ssh willy nilly into where ever all the time? That would be sub-optimal, from a network security standpoint.
