---
layout: post
date: 2014/2/27
title: Recursion in 3 steps.
---

Recursion is not as difficult a concept as people would have you believe when you first start out. Textbook definition says:

> Recursion in computer science is a method where the solution to a problem depends on solutions to smaller instances of the same problem (as opposed to iteration).

Ok, great. If you're a beginner, that's not **super** helpful, and if you ask your grizzled old dev friends about it they are likely to either start yammering about how awesome recursion is from a to the metal on the stack implementation perspective or advise you to not worry about it. Either response maintains the mystery.

So what is recursion? At a basic level, you are using recursion if you are calling a function from inside of itself. It makes more sense as a demonstration.

Let's define a function that returns nothing (in Python, because why not):

```python
def myfunc():
    return None
```

Now here is a function that does nothing but call itself:

```python
def myfunc():
    myfunc()
```

Calling this will produce the following, almost immediately:

```
RuntimeError: maximum recursion depth exceeded
```

So, we've succeeding in making recursion occur, to no external effect. What's happening under the hood? The computer takes your instructions and dutifully executes them. Whenever you give it a new instruction (including as a subsection of the original instruction) it puts the original instruction aside to complete the new instruction. Once it completes the new instuction (and all sub instructions of that one, as well...) it picks up the original instruction and completes its steps.

It is easy to imagine literally piling these nested instruction sets up on a table top- just you know, stacking them up. Stacking. Stack.

Eventually you're going to run out of room- maybe you hit the ceiling, or something. Once you have no more space to set aside these instruction sets, you have run out of stack, and you will no longer be able to keep track of new nested instructions. You will have reached your maximum recursion depth.

A recursive function MUST have a way to know when to stop calling itself. This is called a "base case" and it looks something like this... if we pass in a number and evaluate against that:

```python
def myfunc(some_number):
    if some_number == 0:
        return "Base case"
    else:
        myfunc(some_number)
```

But here is the tricky part. Each new call to the function is passing in the same number. If we start at 0, it will not reach the recursive call. But if we do not start at 0, we have the same problem as before. Every time you call the function inside of itself, therfore, you want to change the value that you are passing into it.

```python
def myfunc(some_number):
    if some_number == 0:
        return "Base case"
    else:
        myfunc(some_number - 1)
```

This will cause the function calls to move towards the base case. Assuming you have enough space on your table to stack up all of those instructions, the variable will eventually reach 0 and propogate back through the stack of instructions that you had set aside.

Astute readers, of course, may ask what would happen if you start from a negative number. Clearly, subtracting one will never reach 0. The function also needs a way to exit if it finds itelf pursuing a line of instructions that will never reach a base case...

```python
def myfunc(some_number):
    if some_number < 0:
        raise StandardError('Value will never reach base case')
    elif some_number == 0:
        print "Base case"
    else:
        myfunc(some_number - 1)
```

This function has "knowledge" about a situation that would cause it to enter an infinite recursive loop. It moves towards a base case and will eventually reach it, provided it has enough space to store the stack of instructions as it is executing them. What if it doesn't?

If I call this function passing in 998, it works fine. 999, I will get a stack overflow. It still runs out of memory, at least in the particular python that I ran it in on my machine (memory allocation may differ depending on some other factors...)!

The way different languages deal with this problem is dependant on the priorities and style of the language, and is beyond the scope of this simple post. Suffice to say that for many problem spaces, recursion can be overkill where iteration would work fine. Here is the same function iteratively:

```python
def myiter(some_number):

    if some_number < 0
      raise StandardError('This will subtract forever')

    while some_number > 0:
      some_number = some_number - 1

    print "You made it!"
```
This does not have to keep track of how many instructions it has set aside. It simply mutates the given variable in the specified way until it reaches the condition set. Once again, we have caught numbers that would never reach 0 before they reach the loop... (errors cut off the code evaluation at the point at which they were raised.)

Languages like Python and Ruby implicitly discourage recursiveness through their design decisions. Functional languages like Scheme and Clojure (from the lisp lineage) have built in optimizations to make recursion less brittle. Hilariously, a common technique is tail call optimization, which under certain circumstances turns a recursive function into an iterative one at the machine level.

Recursion is powerful and can be conceptually difficult at first, but... for some problem spaces it is by far the best computational method.

More on that later!
