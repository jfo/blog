---
title: How React Do?
date: 2016-09-20
tags: rc
layout: post
---

I like doing things from total scratch, or at least what _seems_ like total
scratch to me. For this reason a lot of modern javascript has baffled me. I can't
keep up with all the frameworks because I always want to know what's going on at the root of
things. I think this is maybe a laudable impulse, but I have a lot of FOMO with
all the new hotnesses because I just don't have the patience or time to learn all the
API's before some other thing comes along. In practice, I really _would_
like to be better at javascript, but the number of possible entry points can be
overwhelming.

I spend a lot of my time as a product engineer writing javascript, and
sometimes, I write really bad javascript! I know that thinking about front end
development in a more modern, coherent way would benefit me whether I'm working
in a framework or not, but I've been waiting for something to grab me- some
project or idea that really makes me want to learn the ins and outs of the
language. I finally got the itch last week while helping a coworker hack on his
React project. So this weekend I scratched the itch!

A thing about javascript is that there seem to be a million different ways to
package it up. The tooling is sometimes as impenetrable as the coding itself. I
want to start by skipping _all_ of that.  I want to make the simplest simple
app I can. How do I do this???

This is kind of sort of a tutorial, but it's really, really not. It's more of a
dev log that I wrote _while_ I was learning about React, so I wouldn't take
this as the source of truth or anything. In fact, I would encourage readers
who know better to let me know if there is anything strange in here! I do
provide ample links to resources that I found helpful, though, so [you don't
have to take my word for it](https://www.youtube.com/watch?v=JjuzxiuIbjs).

This post got kind of long, so here's a

<a name=toc />

Table of Contents:
------------------

- [mkdir](#mkdir)
- [injecting a single React element into the dom](#singleel)
- [element properties](#elprops)
- [Think of the Children](#children)
- [No more inline js](#notinline)
- [Elements](#elements)
- [Let's make a box](#box)
- [Let's make two boxes](#boxes)
- [Let's make a row of boxes](#row)
- [Let's make a grid of rows of boxes](#grid)
- [Dynamically sizing with `props`](#sizing)
- [Giving it dimensions](#dimensions)
- [Multiplying elements (with a cheeky little lambda)](#multi)
- [The State of the Dom](#statedom)
- [Coda](#coda)

Anyway, let's start! This project will be called "boxes", and it will start
from `mkdir`. The repo of all the code is
[here](https://github.com/urthbound/boxes). You can follow along with it if you want to!

<a name=mkdir />
#mkdir


```
mkdir boxes && cd boxes
```

I'll start with an `index.html` file that can look like this:

```html
<!DOCTYPE html>

<html>
    <head>
    </head>

    <body>
        <div>Hello World!</div>
    </body>
</html>
```

Since this is completely static, you can simply open the `index.html` file in a
browser and it will act exactly as if it's been served to you.

You don't have to, but you could also run a tiny little development server I
like to use by typing...

```
python -m SimpleHTTPServer 4321
```

I alias this to `serve`, it simply serves the working directory on the specified port.

Visiting `localhost:4321` now will yield what we would expect, the same as
opening the file in the browser.

```
Hello World!
```

And in the `head` tag of the index file:

```html
<script>
    console.log("Hello Warld!");
</script>
```

Now reloading the page gives me both "Hello World!" in the browser window and
"Hello Warld!" in the console. All is right with the world.

Ok. So. Now. React. How do I _get React_, into the right place, so I can use it?
There are one billion ways to do this, and I am sure countless best practices
that I don't care about yet because I haven't been bitten by awful dependency
hell, or something. I want to know the _absolute simplest_ way to get this into
my page. This is almost definitely not the best way to do this.

https://facebook.github.io/react/downloads.html

Looks like I can _download it directly from a CDN_. Ok.

I'll dump those two script tags into my `index.html`'s `<head>`, like it's
2003, and also console.log the two objects I get back. I know these are the
objects I get back from those calls because
[this](https://facebook.github.io/react/docs/package-management.html).

```html
<script src="https://unpkg.com/react@15.3.1/dist/react.js"></script>
<script src="https://unpkg.com/react-dom@15.3.1/dist/react-dom.js"></script>
<script>
    console.log(React);
    console.log(ReactDOM);
</script>
```

...which yields in the console:

```js
> Object {__SECRET_DOM_DO_NOT_USE_OR_YOU_WILL_BE_FIRED: Object, __SECRET_DOM_SERVER_DO_NOT_USE_OR_YOU_WILL_BE_FIRED: Object, Children: Object, PropTypes: Obj... // etc
> Object {version: "15.3.1"}
```

[Lol.](https://www.reddit.com/r/javascript/comments/3m6wyu/found_this_line_in_the_react_codebase_made_me/cvcyo4a)

<sub><a href='#toc'>toc</a></sub>
<a name=singleel />
#Injecting a single react element into the dom

Ok, now I want to inject a React element into the dom. To do that I first need
a reference to a container that already exists in the dom. Let's see if I can
get one this way:

```html
<!DOCTYPE html>

<html>
    <head>
        <script src="https://unpkg.com/react@15.3.1/dist/react.js"></script>
        <script src="https://unpkg.com/react-dom@15.3.1/dist/react-dom.js"></script>
        <script>
            console.log(document.getElementById("example"));
        </script>
    </head>

    <body>
        <div id="example"></div>
    </body>
</html>
```

This logs `null` to the console, and is just the kind of garbage javascript
that ruins lives and families. _of course_ I can't access that div yet, it
hasn't been rendered at the time the script is trying to access it. This is
exactly the kind of dumb mistake that proper dependency management solves, but
I'm doing it the "easy" way.

Anyway it's more best practicy these days to put your script tags at the end of
the `body` tag, so that the dom is fully formed and jarvascrapt can access it
without wrapping everything in
[`$(document).ready()`](http://stackoverflow.com/questions/9899372/pure-javascript-equivalent-to-jquerys-ready-how-to-call-a-function-when-the/9899701#9899701).

Also it lets the browser go ahead and render a lot of the visible dom before
loading all the javascript dependencies in random script tags (react is ~20,000
lines, after all!)

```html
<!DOCTYPE html>

<html>
    <head>
    </head>

    <body>
        <div id="example"></div>
        <script src="https://unpkg.com/react@15.3.1/dist/react.js"></script>
        <script src="https://unpkg.com/react-dom@15.3.1/dist/react-dom.js"></script>
        <script>
            console.log(document.getElementById("example"));
        </script>
    </body>
</html>
```

This logs:

```js
> div#example
```

Which is a DOM object that you can open up and mess with in the console which
is what I wanted hooray.

This so far is loosely coupled with
[this](https://facebook.github.io/react/docs/getting-started.html):


So let's try dropping in that React code directly. This should work, right? I
know that I have access to the ReactDOM object there, after all.

```html
<!DOCTYPE html>

<html>
    <head>
    </head>

    <body>

        <div id="example"></div>

        <script src="https://unpkg.com/react@15.3.1/dist/react.js"></script>
        <script src="https://unpkg.com/react-dom@15.3.1/dist/react-dom.js"></script>
        <script>
            ReactDOM.render(
                <h1>Hello, world!</h1>,
                document.getElementById('example')
            );
        </script>
    </body>

</html>
```

This won't work! I get a syntax error in the console:

```
index.html:13 Uncaught SyntaxError: Unexpected token <
```

Astute readers will notice that I did not include `babel` like in the facebook example:

```html
<script src="https://unpkg.com/babel-core@5.8.38/browser.min.js"></script>
```

Wtf is [babel](https://babeljs.io/)? Do I want to use it? Eventually, yes I do.
In this case, it's turning `<h1>Hello, world!</h1>,` from inlined `JSX` into
vanilla javascript.

[More on JSX here!](https://facebook.github.io/react/docs/jsx-in-depth.html).
I'll come back to it in a minute.

Maybe I can just pass in a string of html, then?

```js
ReactDOM.render(
    "<h1>Hello, world!</h1>",
    document.getElementById('example')
);
```

Nope! But I _do_ get a helpful error message!

```
react.js:20150 Uncaught Invariant Violation: ReactDOM.render(): Invalid
component element. Instead of passing a string like 'div', pass
React.createElement('div') or <div />.

```

I can't pass `<div />` yet, because that's JSX and I'm not transpiling yet. (To
see what that would get turned into, try this [ REPL
](https://babeljs.io/repl/#?babili=false&evaluate=true&lineWrap=false&presets=es2015%2Creact%2Cstage-2&code=%3Cdiv%20%2F%3E%0A)).

But I can pass the other one!

```js
ReactDOM.render(
    React.createElement("div"),
    document.getElementById('example')
);
```

No errors! It isn't immediately apparent what this does, but if you inspect the
DOM now you'll see something new added to it:

```html
<div id="example">
    <div data-reactroot></div>
</div>
```

That `data-reactroot` div is the element I created! Interesting to note, but
you can pass any string into that `createElement()` and you will get a tag of
that name. What the rendering browser does with that is up to it, but the React
function doesn't heel you to a particular set of elements. [Here's a pedantic
Stack Overflow thread about
arbitrary tags](http://stackoverflow.com/questions/3593726/whats-stopping-me-from-using-arbitrary-tags-in-html).

```js
ReactDOM.render(
    React.createElement("thingamadoodad"),
    document.getElementById('example')
);
```

yields

```html
<div id="example">
    <thingamadoodad data-reactroot></thingamadoodad>
</div>
```

If we check out the `React.createElement` in the console we can see a few lines
of the source, including the argument list:

```js
> React.createElement

< function (type, props, children) {
    var validType = typeof type === 'string' || typeof type === 'function';
    // We warn in this case but don't throw. We expect the element creation to
    // suc…
```

We can see the whole source by calling `toString` on the function:

```js
> React.createElement.toString()
< "function (type, props, children) {
    var validType = typeof type === 'string' || typeof type === 'function';
    // We warn in this case but don't throw. We expect the element creation to
    // succeed and there will likely be errors in render.
    if (!validType) {
        'development' !== 'production' ? warning(false, 'React.createElement: type should not be null, undefined, boolean, or ' + 'number. It should be a string (for DOM elements) or a ReactClass ' + '(for composite components).%s', getDeclarationErrorAddendum()) : void 0;
    }

    var element = ReactElement.createElement.apply(this, arguments);

    // The result can be nullish if a mock or a custom function is used.
    // TODO: Drop this when these are no longer allowed as the type argument.
    if (element == null) {
        return element;
    }

    // Skip key warning if the type isn't valid since our key validation logic
    // doesn't expect a non-string/function type and can throw confusing errors.
    // We don't want exception behavior to differ between dev and prod.
    // (Rendering will throw with a helpful message and as soon as the type is
    // fixed, the key warnings will appear.)
    if (validType) {
        for (var i = 2; i < arguments.length; i++) {
            validateChildKeys(arguments[i], type);
        }
    }

    validatePropTypes(element);

    return element;
}"
```

Sweet, sweet code comments! This looks like a light wrapper around
`ReactElement.createElement.apply()` that does a little bit of error handling.

<sub><a href='#toc'>toc</a></sub>
<a name=elprops />
# Element props

The function takes three arguments: `type`, `props`, and `children`. We know
what 'type' is, how about 'props'? I would expect that to map to [html
attributes](http://www.w3schools.com/html/html_attributes.asp). Perhaps a
string?

```js
ReactDOM.render(
    React.createElement("div", "name='thing'"),
    document.getElementById('example')
);
```

Nope! But this does give me two error messages!

```
react.js:20483 Warning: React.createElement(...): Expected props argument to be a plain object. Properties defined in its prototype chain will be ignored.

react.js:20483 Warning: Unknown props `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9` on <div> tag. Remove these props from the element. For details, see https://fb.me/react-unknown-prop in div
```

Aha! Using an object as a key/value dictionary makes a lot of sense wrt
properties/attributes, since that's essentially what they are!

As for that other error- it comes with a long stack trace that I don't feel
like digging into right now, but I would put money on the string being
`split()` into an array of characters at some point and then `keys()` called on
it somewhere and then some iterator iterating over that somewhere, or something
like that... like try it in the console!:

```js
var thing = "this is a string".split('').keys()
thing.next()
thing.next()
thing.next()
thing.next()
// etc...
```

That's a guess anyway, but it doesn't matter right now! We're experimenting!
Move fast and maintain a cursory understanding of the architecture that
underpins your systems, that's what I always say!

```js
ReactDOM.render(
    React.createElement("thingy", { name: "doodad" }),
    document.getElementById('example')
);
```

Does indeed give me:

```html
<thingy data-reactroot name="doodad"></thingy>
```

Woot Woot!

Here's a classy classic React gotcha! Let's make an element with a class on
it, something we're likely to do all the time.

```js
ReactDOM.render(
    React.createElement("whatsit", { class: "hoohaa" }),
    document.getElementById('example')
);
```

Does not work! Gives this warning:

```
Warning: Unknown DOM property class. Did you mean className?
```

Lol! This actually makes sense though... since "class" is a reserved word in
javascript and can muck up the chains if you throw it around! The same is true
for `for`, which mapes to `htmlFor` in react land. [Here's an explanation of
    this from a react core team
    human.](https://www.quora.com/Why-do-I-have-to-use-className-instead-of-class-in-ReactJs-components-done-in-JSX)

```
ReactDOM.render(
    React.createElement(
        "whatsit",
        { className: "hoohaa", htmlFor: "derp" }
    ),
    document.getElementById('example')
);
```

```html
<whatsit data-reactroot class="hoohaa" for="derp"></whatsit>
```

<sub><a href='#toc'>toc</a></sub>

<a name=children />

#Think of the Children

And as for the last argument to the function, `children`, You pass any child
elements and/or strings and/or numbers and/or arrays you want to be rendered!

```js
ReactDOM.render(
    React.createElement(
        "h1",
        {},
        "string",
        React.createElement("sup", {}, "UPP"),
        123,
        React.createElement("sub", {}, "little doooown"),
        ["what", 78]
    ),
    document.getElementById('example')
);
```

This yields this html, basically:

```html
<h1 data-reactroot>
    string<sup>UPP</sup>123<sub>little doooown</sub>what78
</h1>
```

Notice some things... the array was flattened and each element was just treated
like it was passed in individually. Some of these children are themselves React
Elements. Also, I haven't passed in an array of things, I've just passed in an
arbitrary number of args. Funny story about `children`... it's never even
accessed in the function body! it's simply a semantic placeholder, and the
entire argument list is passed through into the sub call as an array (accessed
by the [arguments](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/arguments) keyword). You can see this in the function body above!

Ok back to safety:

```js
ReactDOM.render(
    React.createElement("h1", {}, "Hello, ", "World!"),
    document.getElementById('example')
);
```

```html
<h1 data-reactroot>Hello, World!</h1>
```

And we're back where we started, but with React in the mix. This Single Page
App is going to be so sweeeeeeeet!

<hr>

<sub><a href='#toc'>toc</a></sub>

<a name=notinline />

# ok let's not inline the js in the template

Ok this inline JS thing is cute and all but let's put that in its own file, in
the same directory as the index.html file.

```html
<script src="./index.js"></script>
```

```js
// index.js
ReactDOM.render(
    React.createElement("h1", {}, "Hello, ", "World!"),
    document.getElementById('example')
);
```

Also, now that we know what JSX renders into (just a plain old javascript
function call, as it turn out!) I can see the great benefit of it.

```html
<script src="https://unpkg.com/babel-core@5.8.38/browser.min.js"></script>
<script type="text/babel" src="./index.js"></script>
```

This fails when loaded directly as a file (on chrome at least) because of cross
site scripting safeties! I can however run that little web server I mentioned
earlier with

```bash
python -m SimpleHTTPServer 4321
```

And go to `localhost:4321` in the browser, and _that_ will work! Or whatever
dev server you have lying around will work, really.

Now I can freely use JSX inlined in the js file, like this! Both of those lines
are equivalent:

```diff

diff --git a/index.js b/index.js
index 031694d..090b3af 100644
--- a/index.js
+++ b/index.js
@@ -1,4 +1,4 @@
 ReactDOM.render(
-    React.createElement("h1", {}, "Hello, ", "World!"),
+    <h1>Hello World!</h1>,
     document.getElementById('example')
 );
```

Using babel (or I guess some other toolchain? I am sure there are others...) to
transpile inlined JSX in React is the accepted Way of Things. I can see why.
JSX simply turns into regular JS at the end of the day, and it is a lot easier
to work with, especially for nested structures (it is essentially just XML
after all) and especially for designers, most of whom are already familiar with
html tags and maybe not so familiar with function calls. Of course it doesn't
really matter who you are, it's not especially controversial to prefer this:

```
<App props="this">
    <div>Wow</div>
    <ol>
        <li>hey</li>
        <li>here</li>
        <li>is</li>
        <li>an</li>
        <li>ordered</li>
        <li>list</li>
    </ol>
</App>
```

to this:

```js
React.createElement(App,{ props: "this" },
        React.createElement( "div", null, "Wow"),
        React.createElement( "ol", null,
            React.createElement( "li", null, "hey"),
            React.createElement( "li", null, "here"),
            React.createElement( "li", null, "is"),
            React.createElement( "li", null, "an"),
            React.createElement( "li", null, "ordered"),
            React.createElement( "li", null, "list")
        )
);
```

So here we are!

<a name=elements />
#Elements

In JSX land, you can interpolate arbitrary javascript code by wrapping it in
curlies. (Sorry, my syntax highlighter doesn't like inlined JSX at all.)

```js
var thing = "Hello World!";

ReactDOM.render(
    <h1>{thing}</h1>,
    document.getElementById('example')
);
```

That will be the same thing as this:

```js
var thing = "Hello World!";

ReactDOM.render(
    React.createElement("h1", null, thing),
    document.getElementById('example')
);
```

Ok, so, what if I want to style this thing? I know how to add attributes in
JSX, how about this?

```js
var thing = "Hello World!";

ReactDOM.render(
    <h1 style="color:red;">{thing}</h1>,
    document.getElementById('example')
);
```

Seems reasonable! Doesn't work! Another gotcha gotme. But a wild good error
message appeared!

```
react.js:20150 Uncaught Invariant Violation: The `style` prop expects a mapping from style properties to values, not a string. For example, style={{marginRight: spacing + 'em'}} when using JSX.
```

This, once again, makes sense, but I wouldn't have guessed it offhand!

```js
var thing = "Hello World!";

ReactDOM.render(
    <h1 style={ {color:"red"} }>{thing}</h1>,
    document.getElementById('example')
);
```

Notice the double curlies- the first for inlining the js into the jsx and the
second is just the object notation. This works! I get a big red `Hello World!`.

Alright alright. What if I want a random color on page load?

```js
var text = "Hello World!";
var colors = [ "red", "blue", "orange", "green" ];
var color = colors[Math.floor(Math.random() * colors.length)];

ReactDOM.render(
    <h1 style={ {color:color} }>{thing}</h1>,
    document.getElementById('example')
);
```

> lol @

> ```js
> var color = colors[Math.floor(Math.random() * colors.length)];
> ```

> This is a total aside, but I could monkeypatch `Array.prototype` to have a
> legit `random` "method" like this!

> ```js
> Array.prototype.random = function() {
>     return this[Math.floor(Math.random() * this.length)];
> }
> ```

> And then I could call `colors.random()`! I'm not going to do that right now,
> prototypes make my head blow up a little bit.

Aside aside, this gives me a new color on every page load! Success!

Now. Let's see how React reacts. Here is a dumb function that is set to run on
a loop, once every second.

```js
setInterval(function() {
    color = colors[Math.floor(Math.random() * colors.length)];
}, 1000)
```

But... React doesn't do anything! Shouldn't it like, you know, react?

Of course not! I am simply changing the state of a variable in memory... React
doesn't know anything about that, and I already used it to set the style the
first time through!

```js
setInterval(function() {
    color = colors[Math.floor(Math.random() * colors.length)];
    console.log(color);
}, 1000)
```

You can see that the var is being updated, but of course it's not going to
affect the dom in any way.

Now, in vanilla javascript, this would be "simple." I just grab the element out
of the DOM and manipulate its style property directly!

```js
setInterval(function() {
    color = colors[Math.floor(Math.random() * colors.length)];
    document.getElementById('example').children[0].style.color = color
}, 1000)
```

This works! I will see the color change every second.

But it is _so, so, ugly._

It's bad in so many ways... I'm reaching into the DOM from an arbitrary place
in the code. The selector is brittle and if I moved that div _at all_ I'd have
to update every place I touch it. What if I wanted to transform this based on
its state? Like say I wanted to avoid the color that it already is? I'd have to
either keep a reference to that around, which means maintaining multiple
sources of truth (the reference and also the truth in the dom) _or_ reaching
into the dom anytime I want to get that truth out (state in the dom!)

State in the DOM is one of javascript's original sins! It may be a single
source of truth, kind of, but from javascript's perspective you can grab that
out from anywhere, anytime, and mutate it, or make branching decisions on it,
or all manner of things. You can have multiple references in the js code to the
same dom element that depend on similarly brittle selectors to the one above
that are tough to keep track of and easy to get out of sync. It's a big mess is
what it is.


This is one of the _exact problems_ that react was meant to solve. I don't want
to have to manage the state of the DOM procedurally like that, I want the dom
to manage itself based on a description of what it should look like in various
states.

I can do this very simply, by _rerendering the entire ReactDOM anytime the state changes!_

```js
var thing = "Hello World!";
var colors = [ "red", "blue", "orange", "green" ];

setInterval(function() {
    var color = colors[Math.floor(Math.random() * colors.length)];
    ReactDOM.render(
        <h1 style={ {"color":color} }>{thing}</h1>,
        document.getElementById('example')
    );
}, 1000)
```

"But wait!" I hear you saying, "Isn't that inefficient?? Rerendering the whole
tree everytime anything changes at all?"

No!! It is not! Consider this snippet:

```js
var thing = "Hello World!";
var colors = [ "red", "blue", "orange", "green", "yellow"];

setInterval(function() {
        var color = colors[Math.floor(Math.random() * colors.length)];
        ReactDOM.render(
            <div>
            <h1 style={ {"color":"brown"} }>{thing}</h1>
            <h1 style={ {"color":"purple"} }>{thing}</h1>
            <h1 style={ {"color":color} }>{thing}</h1>
            <h1 style={ {"color":"pink"} }>{thing}</h1>
            <h1 style={ {"color":"indigo"} }>{thing}</h1>
            </div>,
            document.getElementById('example')
            );
        }, 100)
```

This updates the whole ReactDom _10 times a second_. But it only ever _touches
the real DOM_ where it's _actually_ changing!

This is one of React's superpowers. It maintains a _virtual dom_ in addition to
the "real" dom in the browser. When state is updated or when
`ReactDOM.render()` is invoked, it can look at the differences between the
virtual and real DOM's and generate a _minimal changeset_ of DOM manipulations
to reconcile the real dom to the virtual one. This has all sorts of benefits! I
as the programmer no longer have to reach into the DOM to find state, or worry
about when and how to manipulate DOM nodes directly, or in what order! I no
longer have to litter every code path with jQuery selectors that may or may not
represent the same nodes at the same or different times. I think
this is a really Good idea, and in fact it's the thing that made me really
want to actually learn React in the first place!

[Check out this great stack overflow answer about this from one of the
authors.](http://stackoverflow.com/a/23995928)

> A silly thing I noticed about this is that the color change seems a little
> choppy. At first I thought maybe it was choking a little bit on the dom
> manipulations, but it happens at lower speeds too. Turns out that with only 5
> possible colors the odds of repeating the same one are pretttttty high, and
> that's what makes it seems like that. Better to just produce a random hexcode!
> That would reduce the repeating chance from 20% to 0.00000596%.

> [I found this rad page with lots of little solutions to how to make a hexcode
> form nothing and stole
> one!](http://www.paulirish.com/2009/random-hex-color-code-snippets/) Thanks,
> the internet. ([me rn](http://i.imgur.com/SZPjHwz.jpg))


Components
-----------

I was confused about components for a while, thinking that they were somehow a
superset of elements but with more stuff in them or something. _the truth is
much stranger!_

All of the following things are basically equivalent as written, where an
element can be produced from either a pure function (the first two), or an
Object (the last two).

```js
var randColor = function() {
    return '#'+Math.floor(Math.random()*16777215).toString(16);
}


var ExampleOne = (props) => <h1 style={{color: props.color}}>{props.text}</h1>;

var ExampleTwo = function(props) {
    return <h1 style={{color: props.color}}>{props.text}</h1>;
}

var ExampleThree = React.createClass({
    render() {
        return <h1 style={{color:this.props.color}}>{this.props.text}</h1>;
    }
})

class ExampleFour extends React.Component {
    render() {
        return <h1 style={{color:this.props.color}}>{this.props.text}</h1>;
    }
}

setInterval(function() {
    ReactDOM.render(
        <div>
            <ExampleOne text="it came from a stabby proc function!" color={randColor()} />
            <ExampleTwo text="it came from a function!" color={randColor()} />
            <ExampleThree text="it came from React.createClass!" color={randColor()} />
            <ExampleFour text="it came from an ES6 class that extends React.Component" color={randColor()} />
        </div>,
        document.getElementById('example')
    );
}, 100)
```

[I found a good doc about this!!](https://facebook.github.io/react/blog/2015/12/18/react-components-elements-and-instances.html)

> also it includes this gem:

> ["React is like a child asking “what is Y” for every “X is Y” you explain to them
> until they figure out every little thing in the world."](https://youtu.be/4u2ZsoYWwJA?t=7m37s)

The difference in using an object (or class with the es6 syntax) is that
_objects can maintain state_.

What I've learned is to try to use the simplest choice. If your component
needn't hold state or react to events inside of itself, it should be a pure
function of the properties passed into it when possible. More complex things
might require the class extension or the `React.createClass()`, but it's
important to note that all of these things basically boil down to the same
thing at the end of the day. JavaScript!

<hr>

<sub><a href='#toc'>toc</a></sub>

<a name=box />
#Let's make a box

With this in mind, let's make a box.

```js
var randColor = function() {
    return '#'+Math.floor(Math.random()*16777215).toString(16);
}

var Box = () => {
    return <div style={{
        background: randColor(),
        width: "100px",
        height: "100px"
    }} />;
}

setInterval(function() {
    ReactDOM.render(
        <Box />,
        document.getElementById('example')
    );
}, 100)
```

Everytime this is rendered (10 times a second!) we get a new color box. Let's make 2!

<sub><a href='#toc'>toc</a></sub>

<a name=boxes />
#Let's make two boxes

```js
ReactDOM.render(
    <div>
        <Box />
        <Box />
    </div>,
    document.getElementById('example')
);
```

Hmm... I wanted these side by side, but they are on top of each other. This is
a classic styling thinger! Divs are `block` elements, and by default stack on top of each other. Easy fix!

```js
var Box = () => {
    return <div style={{
        display: "inline-block",
        background: randColor(),
        width: "100px",
        height: "100px"
    }} />;
}
```

It feels really weird to me to have all this styling directly on the element
itself instead of in an external style sheet... but this is the react way. Self
contained composable units!

> Since I'm using es6, I'm going to go ahead and change those `var` declarations
> to `let` and `const` declarations. [Here's a little more about
> that.](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/let)

<sub><a href='#toc'>toc</a></sub>

<a name=row />
#Let's make a row of boxes

Now that boxes can be put next to each other, I can make a `Row` component that
composes 5 of them side by side!

```js
const Row = () => {
    return <div>
        <Box />
        <Box />
        <Box />
        <Box />
        <Box />
    </div>
}
```

<sub><a href='#toc'>toc</a></sub>

<a name=grid />
#Let's make a grid of rows of boxes

I can do a very similar thing by stacking 5 rows together to make a `Grid` component.

```js
const Grid = () => {
    return <div>
        <Row />
        <Row />
        <Row />
        <Row />
        <Row />
    </div>
}
```

Now, rendering a `Grid` element will give me a 5x5 grid of statically sized
100x100 pixel boxes!

```js
setInterval(()=>{
    ReactDOM.render(
        <Grid />,
        document.getElementById('example')
    );
}, 100)
```

<sub><a href='#toc'>toc</a></sub>

<a name=sizing />
#Dynamically sizing the grid with `props`

What I would like, though, is a dynamically sized grid. This is fairly simple-
I can pass height and width in as props to the grid and set the style
accordingly...

```js
const Grid = (props) => {
    return <div style={{
        display: "inline-block",
        height: props.height,
        width: props.width
    }}>
        <Row />
        <Row />
        <Row />
        <Row />
        <Row />
    </div>
}

setInterval(()=>{
    ReactDOM.render(
        <Grid height="500px" width="500px" />,
        document.getElementById('example')
    );
}, 100)
```

This limits the size of the enclosing `Grid` element to what I specify. I would
like to cascade that value down through the hierarchy.

```js
const Row = (props) => {
    return <div style={{
        height: props.height,
        width: props.width
    }}>
        <Box />
        <Box />
        <Box />
        <Box />
        <Box />
    </div>
}

const Grid = (props) => {
    return <div style={{
        display: "inline-block",
        height: props.height,
        width: props.width
    }}>
        <Row height={props.height / 5} width={props.width} />
        <Row height={props.height / 5} width={props.width} />
        <Row height={props.height / 5} width={props.width} />
        <Row height={props.height / 5} width={props.width} />
        <Row height={props.height / 5} width={props.width} />
    </div>
}
```

Notice something important here- the `Row`s don't do the calculation to know
their own height- they simply respond to the input. Passing in the full size of
the grid and then doing the calculation inside the `Row` would give the Row
knowledge about its parent, which feels like an antipattern maybe? I don't
know. Feels like it though.

A similar pass for the `Box`:

```js
const Box = (props) => {
    return <div style={{
        display: "inline-block",
        background: randColor(),
        height: props.height,
        width: props.width
    }} />;
}

const Row = (props) => {
    return <div style={{
        height: props.height,
        width: props.width
    }}>
        <Box height={props.height} width={props.width / 5} />
        <Box height={props.height} width={props.width / 5} />
        <Box height={props.height} width={props.width / 5} />
        <Box height={props.height} width={props.width / 5} />
        <Box height={props.height} width={props.width / 5} />
    </div>
}
```

<sub><a href='#toc'>toc</a></sub>
<a name=dimensions />
#Giving it dimensions

The grid really has two things I'd like to specify- the absolute size that I've been working with so far, and also the x y values of how many boxes are inside of it.

```js
const randColor = function() {
    return '#'+Math.floor(Math.random()*16777215).toString(16);
}

const Box = (props) => {
    return <div style={{
        display: "inline-block",
        background: randColor(),
        height: props.height,
        width: props.width
    }} />;
}

const Row = (props) => {
    return <div style={{
        height: props.height,
        width: props.width
    }}>
        <Box height={props.height} width={props.width / props.count} />
        <Box height={props.height} width={props.width / props.count} />
        <Box height={props.height} width={props.width / props.count} />
        <Box height={props.height} width={props.width / props.count} />
        <Box height={props.height} width={props.width / props.count} />
    </div>
}

const Grid = (props) => {
    return <div style={{
        display: "inline-block",
        height: props.height,
        width: props.width
    }}>
        <Row height={props.height / props.dimensions.y} width={props.width} count={props.dimensions.y}/>
        <Row height={props.height / props.dimensions.y} width={props.width} count={props.dimensions.y}/>
        <Row height={props.height / props.dimensions.y} width={props.width} count={props.dimensions.y}/>
        <Row height={props.height / props.dimensions.y} width={props.width} count={props.dimensions.y}/>
        <Row height={props.height / props.dimensions.y} width={props.width} count={props.dimensions.y}/>
    </div>
}

setInterval(()=>{
    ReactDOM.render(
        <Grid height={500} width={500} dimensions={{x: 5, y: 5}} />,
        document.getElementById('example')
    );
}, 100)
```

Now, I want to dynamically generate the number of boxes based on those
dimension values, and compute the absolute height and width values of these
children on the fly. Step one is to recognize that I can return _an array of
React elements_ inside of a jsx curly brace block. This will be munged and
rendered as if I had written them by hand as before.

```
const Row = (props) => {
    return <div style={{
        height: props.height,
        width: props.width
    }}>{[
        <Box height={props.height} width={props.width / props.count} />,
        <Box height={props.height} width={props.width / props.count} />,
        <Box height={props.height} width={props.width / props.count} />,
        <Box height={props.height} width={props.width / props.count} />,
        <Box height={props.height} width={props.width / props.count} />
    ]}</div>
}
```

A wild error message appears!

```
react.js:20483 Warning: Each child in an array or iterator should have a unique
"key" prop. Check the render method of `Grid`. See
https://fb.me/react-warning-keys for more information.  in Row (created by
Grid) in Grid
```

[https://fb.me/react-warning-keys](https://fb.me/react-warning-keys).

Duly noted, I need to manually assign these keys when I create an array of
elements, then, so that react knows how to keep track of them.

<sub><a href='#toc'>toc</a></sub>

<a name=multi />
#Multiplying elements (with a cheeky little lambda)

Ok! I need to create a little block that returns an array of elements whose
length is the `count` that I pass in! This is a fun one! A first pass might
look something like this:

```js
function(count) {
    let out = [];
    for (let i = 0; i < count; i++) {
        out.push(<Row
                    height={props.height / props.dimensions.y}
                    width={props.width}
                    count={props.dimensions.x}
                    key={i}
                    />
        );
    }
    return out;
}(props.dimensions.y)
```

This will totally work! But it's so imperative! Let's get more functional.

I start with the number, and I want to end with an array. I can start by making
an Array with that number of elements.

```js
Array(props.dimensions.y)
```

This will return a reference to an Array that has its `length` property set to
that number (if you pass more than one argument to this constructor, it simply
makes an array out of them).

If I want to map over this array, I need to fill in the array with a
placeholder value (this is weird that I have to do this, but whatever- it's all
in the service of a good one liner!)

```js
Array(props.dimensions.y).fill()
```

Will do this. This returns (for a y value of `5`, say) ....

```js
[undefined, undefined, undefined, undefined, undefined]
```

Since I didn't pass in anything to `fill()`.

Now, I can map over this array! I pass it a function (yay stabby procs!)

```js
Array(5).fill().map(()=>3)
```

Would return

```js
[3, 3, 3, 3, 3]
```

Instead of those `3`'s, I'll simply return the element I wanted!

The map function takes two arguments, positionally they are `(element, index)`.
I can use that index as the `key` of the element I'm producing! (Keys only need
to be unique amongst their siblings, so this won't interfere with other rows of
keys boxes, for example.)

```js
Array(props.dimensions.y).fill().map((_, i) => {
    return <Row
            height={props.height / props.dimensions.y}
            width={props.width}
            count={props.dimensions.x}
            key={i} />;
})
```

And Robert's your sister's husband's father-in-law's cousin's cousin!

I thought that one could use some splainin' because... while it's very simple,
it looks pretty weird.

<sub><a href='#toc'>toc</a></sub>

<a name=statedom />
#The State of the Dom

Ok, it's about to get pretty wild in here. So far, this has been fairly
straightforward... just passing in some props and generating a dom based on
that. But what if some of those elements had state of their own? I have to use
the es6 class syntax to add state into one of these Elements- because the pure
function doesn't maintain a reference to itself.

```js
class Box extends React.Component {
    constructor() {
        super();
        this.state = {
            color: randColor()
        }
    }

    render() {
        return <div style={{
            display: "inline-block",
            background: this.state.color,
            height: this.props.height,
            width: this.props.width,
        }} onMouseOver={()=> this.setState({color: randColor()})}/>;
    }
}
```

You'll notice that the `render()` method returns exactly what it was returning before, but the color refers to `state`, not to a `prop`. This is important!

Also notice I've attached an event handler to the onMouseOver event. It simply
updates the color- that's it! But, now, I take away the interval function that
was rewriting the whole dom every second or so, and just replace it with a
single call, once, to `ReactDOM.render()`

```js
ReactDOM.render(
    <Grid height={window.innerHeight}
          width={window.innerWidth}
          />,
    document.getElementById('grid')
);
```

_But now, something magical happens._

When I mouse over a box, the onMouseOver callback is triggered, which updates
that box's state. When the state is update _the box just rerenders itself into
the dom_.

IT'S LIKE MAGIC! This is the MAGIC part of React! I don't have to
crossreference state between what I have in memory and what the dom actually
shows, all the bookkeeping is done for me, and React decides when to (drum
roll) react to state changes!

If there were child elements that depended on this state, they would also be
rerendered! This is amaze and I think I really like it.

Case in point!

```js
class Grid extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            x: 1,
            y: 1
        }
    }

    render() {
        return <div>
        <div style={{
            position: "fixed",
            padding: "6px"
        }}>
            <input type="range" value={this.state.x} min={1} max={25} onChange={(e)=>this.setState({x: parseInt(e.target.value)})} />
            <input type="range" value={this.state.y} min={1} max={25} onChange={(e)=>this.setState({y: parseInt(e.target.value)})} />
        </div>
        <div style={{
            display: "inline-block",
            height: this.props.height,
            width: this.props.width
        }}>{
            Array(this.state.y).fill().map((_, i) => {
                return <Row height={this.props.height / this.state.y}
                            width={this.props.width}
                            count={this.state.x}
                            key={i} />;
            })
        }</div>
        </div>
    }
}
```

I've added two sliders for the x and y dimension values. Now, instead of
passing them in as props, they are given a default value of 1, and when the
sliders are moved, the whole dom is efficiently rerendered! This means that the
cells are resized _but the colors stay the same_, because the boxes each
maintain that state on their own.

The sliders and the rows/boxes are sibling elements that share a common
ancestor- in this case the containing Grid itself. Because the state of the
sliders affects the properties of the rows/boxes (specifically their
dimensions), that state must live on that common ancestor (the Grid
component.)

If the DOM was a lot bigger, or if, say, the sliders were somewhere way down in
the dom tree away from the boxes they affect, I might have to pass bound
functions down the hierarchy to get those states hooked up properly. My very
limited understanding of the flux pattern is that it solves this problem by
maintaining a global store singleton that acts as an event handler/dispatcher
at the very top level of the application. But I don't know much about that yet.

You can see a working examply of this "final" product
[here](http://codepen.io/urthbound/full/wzzGok/). (It might not work quite
right on mobile, I'm sure there is a way to fix that but it's beyond the scope
of this post.)

<sub><a href='#toc'>toc</a></sub>

<a name=coda />
#Coda

This app doesn't really do that much! But I think I kind of sort of get the basic
ideas behind react and also how to sort of use it! The next thing I would want
to learn is how to bundle dependencies, so I could separate the "library"
code that would expose the `Grid` component from the "application" code that
just amounts to that initial `ReactDOM.render()` call.

I guess I could use gulp or webpack or browserify or require or bower or AMD
or... npm? Can npm do that by itself? I think some of these are the same thing.
Or different things. I have no idea yet, really. Maybe I'll write another post
on that!

And then also a proper development server that does hot reloading on file
changes would be nice... do I have to write that myself, too, out of my
somewhat misguided NIH syndrome? Hmm....

In the meantime,
[create-react-app](https://github.com/facebookincubator/create-react-app) looks
really interesting!

A friend of mine told me I should put some keywords at the bottom of the post,
so here's that part: javascript node node react javascript jquery horse-js npm
install.

Thanks for reading!
