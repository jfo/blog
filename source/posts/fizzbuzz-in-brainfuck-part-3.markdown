---
title: fizzbuzz in brainfuck, part 3
date: 2013/10/07
layout: post
categories:
- Programming
---

Alright. I have a memory array loaded with the information I need to get going, and I have a program blueprint that I should be able to implement. I only need to be able to use if/else and if. I looked up some algorithms to use for this bit, and these are the ones I settled on...

If ...

```
temp0[-]
temp1[-]
x[temp0+temp1+x-]temp0[x+temp0-]+
temp1[temp0-temp1[-]]
temp0[

    (code)

temp0-]
```

and If/Else...

```
temp0[-]+
temp1[-]
x[

    (code1)

temp0-
x[temp1+x-]
]
temp1[x+temp1-]
temp0[

    (code2)

temp0]
```

Note that the inline "variable" names are actually describing whatever location that cell happens to be. When we get to the final code, those plain text names will be appended with the pointer motions necessary to arrive at them. Both of these algorithms were lifted from <a href="http://esolangs.org/wiki/brainfuck_algorithms" target="_blank">here</a>. For every cell I want to evaluate, I need two more cells to hold temporary information. This is why I left two empty cells next to each multiples counter in the last post, and it is also why I'll need to slap a couple more empty cells onto the beginning of the whole program when we get around to putting in the final "Buzz" block that needs to be nested into the "Fizz" block. But notice! There is already a problem here... for If/Else, this algorithm runs the first block IF the cell it's evaluating is "TRUE" (meaning it's holding a value other than 0). For our "Fizz" and "Buzz" statements, we want them to run if the value of the cell is "0". Sad Trombone. But it's an easy fix, of course! We just have to invert all the code we had <a title="fizzbuzz in brainfuck, part one" href="http://www.jeffalanfowler.com/blog/fizzbuzz-in-brainfuck-part-one/" target="_blank">before</a>. Just keep that in mind. Lets write the inverted program in psuedo-code and then fill it all in with the specifics...

```ruby
number = 0

until number == 100 do
  if number   % 3 != 0
    if number % 5 != 0
      print number
    else
      print "Buzz"
    end

  else
    print "Fizz"

    if number % 5 == 0
      print "Buzz"
    end
  end

number += 1
end
```

Keep in mind that we've taken care of all the variable assignments and memory allocation in the last post, so this really is all we have left.

Here is the complete, annotated program, which you can also view and run <a href="http://replit.com/Kr0/3" target="_blank">here</a>. This is EXACTLY the same code as the giant block of bf symbols I put in the <a title="fizzbuzz in brainfuck, part one" href="/2013/09/fizzbuzz-in-brainfuck-part-one.html" target="_blank">first part</a>, just spread out with indentation etc.

```

MOVE 20 CELLS TO THE RIGHT TO "CLEAR" MEMORY
>>>>>>>>>>>>>>>>>>>>
>>>>>>>>>>>>>>>>>>>>
>>>>>>>>>>>>>>>>>>>>


Initially Move to cell 7

+++
>>>+++++
>>>

Increment hundreds counter
+

Move to cell 8 Increment tens counter
>
+++++ +++++

To 9 inc ones counter
>
+++++ +++++

to 10 hold space char
>
+++++ +++++

to 11 hold hundreds place "0"
>
+++++ +++++ +++++ +++++
+++++ +++++ +++++ +++++
+++++ +++

to 12 hold tens place "0"
>
+++++ +++++ +++++ +++++
+++++ +++++ +++++ +++++
+++++ +++

to 13 hold ones place "0"
>
+++++ +++++ +++++ +++++
+++++ +++++ +++++ +++++
+++++ +++


to 20 21 22 23 24 to spell "FizBu" 25 is count hold
>>>>>>> >>>>>
20:
>>>>>+++++ ++[<<<<<+++++ +++++>>>>>-]

+++++ +++++ +[<<<<+++++ +++++>>>>-]<<<<----->>>>

+++++ ++[<<<+++++ +++++>>>-]<<<---->>>

+++++ +++++ ++[<<+++++ +++++>>-]<<--->>

+++++ +++++ ++[<+++++ +++++>-]<++

<<<<
to 10 to begin program
<<<<< <<<<< <<<<<


open hundreds loop
<<<[>>>
    open tens loop
    <<[>>
        open ones loop
        <[>

                IF NUMBER % 3 != 0
                if cell1 == true
                <<<<<<<<<
                >temp0[-]+
                >temp1[-]
                <<x[

                    IF NUMBER % 5 != 0
                    >>>>>>>>>
                    <<<<<<
                    >temp0[-]
                    >temp1[-]
                    <<x[>temp0+>temp1+<<x-]>temp0[<x+>temp0-]
                    >temp1[
                        >>>>
                        print current number
                        .>.>.>.<<<
                        <<<<
                    temp1[-]]
                    >>>>
                    <<<<<<<<<

               ELSIF NUMBER % 3 == 0
                elsif cell1 == false
                >temp0-
                <x[>>temp1+<<x-]

                ]

                PRINT FIZZ
                >>temp1[<<x+>>temp1-]
                <temp0[
                >>>>>>>>

                    .
                    >>>>>>>>>>>>>>>
                    .>.>>>..<<<<
                    <<<<<<<<<<<<<<<

                    IF NUMBER % 5 == 0
                    <<<<<<
                    >temp0[-]
                    >temp1[-]
                    <<x[>temp0+>temp1+<<x-]>temp0[<x+>temp0-]+
                    >temp1[<temp0->temp1[-]]
                    <temp0[>>>>>

                    PRINT BUZZ
                    >>>>>>>>>>>>>>>
                    >>.>.>..<<<<
                    <<<<<<<<<<<<<<<

                    <<<<<
                    temp0-]
                    >>>>>


                    cell 1 = 3
                    <<<<<<<<<+++>>>>>>>>>

                <<<<<<<<
                temp0-]
                >>>>>>>>

        ELSIF NUMBER % 5 == 0
        <<<<<<
        >temp0[-]+
        >temp1[-]
        <<x[>temp0-<x[>>temp1+<<x-]]
        >>temp1[<<x+>>temp1-]
        <temp0[
          <+++++>

          PRINT BUZZ
          >>>>>
          .
          >>>>>>>>>>
          >>>>>
          >>.>.>..<<<<
          <<<<<
          <<<<<<<<<<
          <<<<<
        temp0-]
        >>>>>



        increment ones place
        >>>+<<<
        decrement 3s counter
        <<<<<<<<<->>>>>>>>>
        decrement 5s counter
        <<<<<<->>>>>>
        Decrement ones counter
        <-]

    reset ones counter
    +++++ +++++
    rest ones place to 0
    >>>> ----- -----
    increment 10s place
    <+<<

decrement 10s counter
<<-]

reset tens counter to
+++++ +++++ >>>> ----- -----
<+<
<<<-]

PRINT BUZZ FOR 100
>>>.
>>>>>>>>>>>>>>>>
>.>.>..
```

So, that's basically that. This is super hard to read, because of the crazy syntax and how unreadable brainfuck is, but maybe having it parsed out so much will help some people understand it better. I sure learned a hell of a lot about memory allocation, cursors, and logic gates. All in all, now that I have a couple of weeks between it and me, it was worth the time.

Next time in the brainfuck series maybe: <a href="https://github.com/urthbound/esoteric/blob/master/brainfuckint.rb" target="_blank">writing a compiler / interpreter for brainfuck in ruby. </a> Sometime. But don't hold your breath. All you brainfuck fans out there. In Ukraine. Don't think I don't see your ip's.

Oh and just to wrap this up: it feels pretty good to say that I am never going to write another fizzbuzz again; FizzBuzz is officially checked of the bucket list.

Goodnight and goodluck, interwebs.
