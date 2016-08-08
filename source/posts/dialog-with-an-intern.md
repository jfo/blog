---
title: Dialog with an intern, or, alternately, some random unixy tips and tricks
layout: post
date: 2016-08-08
tags: rc
---

<span style="color:red;">mmeehan</span>: actually i may be able to ask it on here if u have a moment

<span style="color:blue;">jfo</span>: sure

<span style="color:red;">mmeehan</span>: so for the [work task related] thing, I added another output field [task thing stuff] and then when i recompile, i get a GET request error for adding that [thing]

<span style="color:blue;">jfo</span>: ah

<span style="color:red;">mmeehan</span>: and i wasn't sure if i was missing some other step?

<span style="color:blue;">jfo</span>: show me the diff?

<span style="color:red;">mmeehan</span>: sure...

<span style="color:red;">mmeehan</span>: this is kind of difficult to read, without the syntax highlighting...

<span style="color:blue;">jfo</span>: ooohhh pro tip!

<span style="color:red;">mmeehan</span>: ok

<span style="color:blue;">jfo</span>: how did you generate this

<span style="color:red;">mmeehan</span>: `git diff commit#..commit# | gist`

<span style="color:blue;">jfo</span>: cool!

<span style="color:blue;">jfo</span>: so, [gist](https://github.com/defunkt/gist) has a type param

<span style="color:blue;">jfo</span>: `gist -t diff` or whatever the filetype is...

<span style="color:blue;">jfo</span>: which will syntax highlight for you

<span style="color:red;">mmeehan</span>: [url to syntax highlighted gist of a diff]

<span style="color:blue;">jfo</span>: cool!

<span style="color:red;">mmeehan</span>: oO)o0

<span style="color:red;">mmeehan</span>: thank u!!!

<span style="color:blue;">jfo</span>: want another related awesome trick?

<span style="color:red;">mmeehan</span>: YES

<span style="color:red;">mmeehan</span>: i like pro tips

<span style="color:blue;">jfo</span>: this is a good one

<span style="color:blue;">jfo</span>: this will blow people's minds

<span style="color:red;">mmeehan</span>: ok i want to blow all the minds gimme

<span style="color:blue;">jfo</span>: we think of diffs as just a git thing probably

<span style="color:blue;">jfo</span>: but they are not

<span style="color:red;">mmeehan</span>: lol

<span style="color:blue;">jfo</span>: `man diff` to read about the diff tool, which is separate

<span style="color:red;">mmeehan</span>: woooah

<span style="color:blue;">jfo</span>: diff is actually a like, really specific file format that originated in perl land, I think

> well, actually, yeah... `patch` _was_ written by Larry Wall in 1985, who
> later went on to write perl, but `diff` was a unix utility before that,
> authored in the early 70's. `patch` was capable of taking the _output_ from
> `diff` and applying the changes to a file or a group of files.

<span style="color:blue;">jfo</span>: here's another one...

<span style="color:blue;">jfo</span>: `man patch`

<span style="color:blue;">jfo</span>: which you can use to apply a patch file

<span style="color:blue;">jfo</span>: a "patch" is what `git diff` produces and it's what `git apply` applies; a "patchfile" contains the plaintext diff.

> Here's a thing to try! Run some commands in an empty directory (not a git repo
> just an empty directory...)

> ```bash
> printf 'hi mom\nhi dad\n' > 1.txt
> printf 'hi mom\nhi dad\nhello world\n' > 2.txt
> cat 1.txt
> cat 2.txt
> ```

> Just makin' some files! How are they different?

> ```bash
> diff 1.txt 2.txt
> diff 2.txt 1.txt
> ```

> ```bash
> diff 1.txt 2.txt > look_a_patch_file_omg
> cat look_a_patch_file_omg
> ```

> We saved those differences into the patchfile... notice the name is
> inconsequential, it doesn't need a suffix to describe a filetype.

> Let's apply that patch, then!

> ```bash
> patch 1 < look_a_patch_file_omg
> ```
> or

> ```bash
> patch 2 < look_a_patch_file_omg
> ```

> ```bash
> cat 1.txt
> cat 2.txt
> ```

> This is basically all `git diff` and `git apply` do, but the diff is taken from
> what a file looked like at a specified ref (a ref[erence] is a commit hash, or
> a branch name, or one of a few other things...), rather than another file on
> disk like above. I do not know why `git apply` isn't `git patch`.


<span style="color:blue;">jfo</span>: it's the same stuff

<span style="color:blue;">jfo</span>: just wrapped into the git plumbing

<span style="color:blue;">jfo</span>: so this is all to say that you can apply a diff directly to a working tree

<span style="color:blue;">jfo</span>: with `git apply patch.diff` or whatever

<span style="color:blue;">jfo</span>: which is what I'll do to "checkout" your changes in a really lightweight way

<span style="color:red;">mmeehan</span>: O0o0o0o i get it woow ahh thats so helpful! So whenever you want to see what someone else's diff does on your own machine you just `git apply patch.diff`

<span style="color:blue;">jfo</span>: yup! or at least that is one way to do
it. It's outside of a lot of the git tracking and checking out and branches and
stuff... it's as if you typed all the changes in yourself. It doesn't commit anything for
you, which means you can get back to a clean head with a `git reset --hard` if
that is what you want

<span style="color:blue;">jfo</span>: but you might have already known that...

<span style="color:red;">mmeehan</span>: i didn't know about that

<span style="color:blue;">jfo</span>: oh good!

<span style="color:blue;">jfo</span>: well want more? theres another level that's even more cool

<span style="color:blue;">jfo</span>: I'm on a pedagogical roll here

<span style="color:red;">mmeehan</span>: go for it hahah

<span style="color:blue;">jfo</span>: well, git apply reads a patchfile, just
like patch does. As far as I can tell they pretty much do the same thing
basically, just with different invocation syntax and I am sure there are more
subtle differences but the main point is they both apply a patch file.

<span style="color:blue;">jfo</span>: but

<span style="color:blue;">jfo</span>: what about [url to raw gist of diff on github]

<span style="color:blue;">jfo</span>: that is the diff we want

<span style="color:blue;">jfo</span>: in plaintext... just that it's living on the server right now.

<span style="color:blue;">jfo</span>: so

<span style="color:blue;">jfo</span>: `curl [url]`

<span style="color:blue;">jfo</span>: would fetch the diff from the server and print it to standard out.

<span style="color:blue;">jfo</span>: so from there...

<span style="color:blue;">jfo</span>: you could `curl [url] > /tmp/file.diff`, which redirects the diff into a temporary file,

> omg did you know about `/tmp`? It's the best. Basically the whole directory
> gets cleaned out by the OS every so often, so for ephemeral crap that you just
> want to hold onto for a little while (tmporarily?) you can just put it in
> `/tmp` and you will get cleaned up after.

<span style="color:blue;">jfo</span>: and then `git apply /tmp/file.diff` in the working tree

<span style="color:blue;">jfo</span>: (the suffixes are inconsequential btw, just conventional, you don't have to call it `.diff`, it could be whatever you want)

<span style="color:blue;">jfo</span>: but doesn't it seem like you should be able to do that in one step?

<span style="color:red;">mmeehan</span>: yes it sure does

<span style="color:blue;">jfo</span>: well you sure can!

<span style="color:blue;">jfo</span>: in at least TWO different ways!

<span style="color:red;">mmeehan</span>: !!

<span style="color:blue;">jfo</span>: OMG I KNOW

<span style="color:red;">mmeehan</span>: hahaha

<span style="color:blue;">jfo</span>: you can pipe it like `curl [url] | git apply`

<span style="color:red;">mmeehan</span>: so piping sends the output of the first command to the second command?

<span style="color:blue;">jfo</span>: basically yes, when used like that the stdout stream coming from the left side command feeds into the stdin stream of the right side command. You can chain things as much as you want, btw, it's the unix way <sup>tm</sup>. Want to know how many `README` files are on your whole computer?

```
tree / | grep README | wc -l
```

<span style="color:blue;">jfo</span>: That's a terrible and inefficient way to do that, but it would totally work. I always forget the flag for multi pattern grepping and end up piping things through multiple instances of grep instead, like a wally.

<span style="color:red;">mmeehan</span>: what is curl exactly?

<span style="color:red;">mmeehan</span>: i feel like i have seen it in a few different contexts...

<span style="color:blue;">jfo</span>: curl is a command line http client

<span style="color:blue;">jfo</span>: you can do all sorts of stuff with it,

<span style="color:blue;">jfo</span>: omg

<span style="color:blue;">jfo</span>: this is so fun

<span style="color:blue;">jfo</span>: check this out

<span style="color:blue;">jfo</span>: open a terminal window

<span style="color:blue;">jfo</span>: and run `nc -l localhost 5000`

<span style="color:red;">mmeehan</span>: what does nc do?

<span style="color:blue;">jfo</span>: it's short for 'netcat', which is a simple little utility that reads and writes data across networks.

<span style="color:blue;">jfo</span>: ok ready?

<span style="color:red;">mmeehan</span>: yea

<span style="color:blue;">jfo</span>: then open another terminal window

<span style="color:red;">mmeehan</span>: ok

<span style="color:blue;">jfo</span>: and run `curl localhost:5000`

<span style="color:red;">mmeehan</span>: ok ok

<span style="color:red;">mmeehan</span>: what is happening

<span style="color:blue;">jfo</span>: haha did it work?

<span style="color:red;">mmeehan</span>: o0o0o i see i wasn't sure what nc is

<span style="color:red;">mmeehan</span>: cool

<span style="color:blue;">jfo</span>: curl is the most basic client, it sends simple get request headers and then prints the response to std out

> If the commands worked you should have seen something like

> ```
> GET / HTTP/1.1
> Host: localhost:5000
> User-Agent: curl/7.43.0
> Accept: */*
> ```

> Appear in the netcat window. Those are the 'headers' I'm referring to.

<span style="color:red;">mmeehan</span>: that's crazy

<span style="color:blue;">jfo</span>: you can also post with it, not sure of the flags off the top of my head...

<span style="color:blue;">jfo</span>: :sparkles: networking :sparkles:

<span style="color:blue;">jfo</span>: notice too, that

<span style="color:blue;">jfo</span>: the window you ran curl in

<span style="color:red;">mmeehan</span>: yeah

<span style="color:blue;">jfo</span>: is waiting on a response

<span style="color:red;">mmeehan</span>: yeah it's so smart!

<span style="color:blue;">jfo</span>: it will never get one, because it sent the request to netcat, which isn't a server that knows how to handle that request, and it also isn't piping to anything that responds, either.

<span style="color:red;">mmeehan</span>: this is supa cool

<span style="color:blue;">jfo</span>: but you could wire up like, the dumbest server ever, using pipes and random utilities, probably

<span style="color:red;">mmeehan</span>: ooo right i see

<span style="color:blue;">jfo</span>: but the last thing I was going to say

<span style="color:blue;">jfo</span>: is this weird unix operator that I learned about last year

<span style="color:blue;">jfo</span>: <(arbitrary commands or whatever)

<span style="color:blue;">jfo</span>: run `echo <(cat /dev/random)`

<span style="color:red;">mmeehan</span>: ok

<span style="color:red;">mmeehan</span>: hmm i don't understand the return

<span style="color:blue;">jfo</span>: you get a path, right? to a device file!

<span style="color:blue;">jfo</span>: which is weird, right?

<span style="color:blue;">jfo</span>: :D

<span style="color:red;">mmeehan</span>: yeah i got a path ... where is it comin from? random? lol

<span style="color:blue;">jfo</span>: under the hood, *nix is implementing interfaces to processes as device files, which represent streams in some form or another!

<span style="color:blue;">jfo</span>: a usual path represents what we think of as data on disk

<span style="color:blue;">jfo</span>: but a stream can come from anywhere... like a stream of audio data could be coming in through an analog to digital converter, which is an external _device_, that the OS interfaces with through a _device file_!

<span style="color:blue;">jfo</span>: what that `<(...)` command does, it exposes the internal device file representation of the process you run inside of it

<span style="color:blue;">jfo</span>: so you can access the return of that process like any other file

<span style="color:blue;">jfo</span>: that is to say

<span style="color:blue;">jfo</span>: that this will also work:

<span style="color:blue;">jfo</span>: `git apply <(curl [url to raw diff])`

<span style="color:blue;">jfo</span>: and essentially it does the same thing as writing the curl output to a file with `curl [url] > /tmp/filename` and then reading it with `git apply`

<span style="color:blue;">jfo</span>: but it skips the writing to disk step

<span style="color:blue;">jfo</span>: computers! :D

<span style="color:blue;">jfo</span>: now, I will actually look at the diff

<span style="color:red;">mmeehan</span>: this all sounds cool but i would have to read more into device files and streams and such to fully grasp the awesomeness ...

<span style="color:red;">mmeehan</span>: lol

<span style="color:blue;">jfo</span>: yeah it's a little mind bendy!

<span style="color:blue;">jfo</span>: sorry for getting excited about it!

<span style="color:red;">mmeehan</span>: y r u sry i am glad to learn !!

<span style="color:blue;">jfo</span>: you are right I am not sorry I am just being polite in case you hate this

<span style="color:red;">mmeehan</span>: i am excited to understand it better ... under the terminal hood

<span style="color:blue;">jfo</span>: I should write this all up in a blog post or something

<span style="color:red;">mmeehan</span>: yeah !

<span style="color:blue;">jfo</span>: oh yeah last tip for now and this is a small one

<span style="color:blue;">jfo</span>: you can put '.diff' on the end of any github pull request url

<span style="color:blue;">jfo</span>: like `https://github.com/username/reponame/pull/#####.diff`

<span style="color:blue;">jfo</span>: and you'll get the raw diff of the whole changeset

<span style="color:blue;">jfo</span>: try it!

<span style="color:blue;">jfo</span>: or `.patch` too

<span style="color:blue;">jfo</span>: either will work

<span style="color:red;">mmeehan</span>: right wow!

<span style="color:blue;">jfo</span>: lol

<span style="color:blue;">jfo</span>: ok back to this ticket

_jfo and mmeehan work on a javascript bug until the heat death of the universe in the year 41201 AD. Scene._
