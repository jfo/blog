---
title: Rubyks, a gem
date: 2013/11/12
layout: post
categories:
- Programming
---

After writing the initial iteration of the [The Chorder](/2013/10/the-chorder-prototype.html), I started thinking about other systems that I might be able to model, and the rubiks cube seemed perfect. It is visual, easy to conceptualize, and completely contained- any possible combination can be arrived at by starting at the solved cube (the "base case") and shuffling. All I had to do was model the state of the cube in some sort of data structure and implement the various transformations accurately and the program would be accurate. Easy, right?!


And actually, it was pretty easy... not at first, necessarily- there was a fair amount of head scratching about how, exactly, I was going to store the state of the cube at any one time (I'm not convinced I picked the best method, either... but more on that later...)

I eventually settled on a two dimensional array containing 6 other arrays (one for each face of the whole cube) of 9 elements each (one for each square on each face.) More about the structure from the README:

```
@cube[0] - top
@cube[1] - left
@cube[2] - back
@cube[3] - right
@cube[4] - front
@cube[5] - bottom
```

The first element @cube[x][0] in any array describes the center square of that face, and remains static in relation to the other sides, just as a real cube's center square would.

The remaining array elements from [1] - [8] start at "12 o'clock" and move clockwise. Thus: Even numbers are middle cubies and odd numbers are always corner cubies.

"12 o'clock" is constant amongst all sides of the cube, and refers to what "north" would be if the cube was unfolded into two dimensions like so:

```
        1
    5,4,0,2
        3
````

When cube orientation procedures are applied, the "address" of each side remains consistent with the above diagram, even as the sides themselves represent different numbers. (The sides could just as easily be assigned any symbol or string or whatnott, just as long as each side started off all the same thing, the cube would be in a legal state).

If you created a new cube and then applied Cube#turn, the sides would appear like so:

        4
    5,3,0,1
        2

But the address of the location of these sides would remain static. This is so that complex move combinations can be applied to a cube regardless of its orientation to the "viewer."

This does have the advantage of offering a static "address" for each mini square on each face of the cube, but doesn't offer any scalability- I can't instantiate a cube of an arbitrary size (like Cube.new(n), for example) because the relationships between the different faces is defined in the methods that act upon them, and not in the data structure itself.

After the data structure was designed, implementing the transformations was fairly straightforward. there are only 6 basic moves- each face can be turned clockwise once (turning a face counterclockwise is the same as turning it clockwise three times). here is the method for turning the top face clockwise once:

```ruby
def u
    cubetemp = Marshal.load(Marshal.dump(@cube))

    cubetemp[1][4] = @cube[4][2]
    cubetemp[1][5] = @cube[4][3]
    cubetemp[1][6] = @cube[4][4]

    cubetemp[4][2] = @cube[3][8]
    cubetemp[4][3] = @cube[3][1]
    cubetemp[4][4] = @cube[3][2]

    cubetemp[3][8] = @cube[2][6]
    cubetemp[3][1] = @cube[2][7]
    cubetemp[3][2] = @cube[2][8]

    cubetemp[2][6] = @cube[1][4]
    cubetemp[2][7] = @cube[1][5]
    cubetemp[2][8] = @cube[1][6]

    cubetemp[0][1] = @cube[0][7]
    cubetemp[0][2] = @cube[0][8]
    cubetemp[0][3] = @cube[0][1]
    cubetemp[0][4] = @cube[0][2]
    cubetemp[0][5] = @cube[0][3]
    cubetemp[0][6] = @cube[0][4]
    cubetemp[0][7] = @cube[0][5]
    cubetemp[0][8] = @cube[0][6]

    @hist << 'u'
    @cube = Marshal.load(Marshal.dump(cubetemp))
    self
  end
```


Simple- just reassigning all the colors based on how the cube is moving. Notice that, because I didn't understand deep copying of data, I used the (then magical) "Marshal" incantation to create a duplicate temporary array to operate on before I redumped the transformed state back into the main attribute. If I didn't do that, the color assignment would happen sequentially on the main data structure and it wouldn't be able to properly assign the new values.

Marshal, by the way, is Ruby's serialization module... it takes any type of data and turns it into a simple byte stream. This was totally overkill. I should have just made a brand new deep copied array by using Array#dup, which does the same thing in a simpler, more secure way. Maybe I'll update that.

You can see the entire source at the <a href="https://github.com/urthbound/rubyks" target="_blank">Github repo</a>. I also wrote a little interface to interact with the model.

I packaged all this up as a Gem and made it available at <a href="https://rubygems.org/gems/rubyks" target="_blank">rubygems.org</a> for anyone who wants to make use of my data structure and transformation methods to write their own solver.

<a href="http://github.com/urthbound/rubyks" target="_blank">Here is the source.</a>
