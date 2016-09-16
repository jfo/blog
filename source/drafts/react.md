---
title: React
layout: post
---

I like doing things from total scratch, or at least what _seems_ like total
scratch to me. For this reason a lot of javascript has mystified me. I can't
keep up with the frameworks, I want to know what's going on at the root of
things. I think this is a laudable impulse, but I often have FOMO with all the
new hotnesses because I just don't have the patience

BUT NO MORE!

I've written enough terrible js to know there must be something better out there!

And react is an out there to start with!

But I want to make the simplest simplest app I can. How can I do this???

This project will be called "boxes".

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
2003, and also console.log the two objects I get back. I just happen to know
what those objects are called.

```html
<script src="https://unpkg.com/react@15.3.1/dist/react.js"></script>
<script src="https://unpkg.com/react-dom@15.3.1/dist/react-dom.js"></script>
<script>
    console.log(React);
    console.log(ReactDOM);
</script>
```

...which yields...

```js
> Object {__SECRET_DOM_DO_NOT_USE_OR_YOU_WILL_BE_FIRED: Object, __SECRET_DOM_SERVER_DO_NOT_USE_OR_YOU_WILL_BE_FIRED: Object, Children: Object, PropTypes: Obj... // etc
> Object {version: "15.3.1"}
```

[Lol.](https://www.reddit.com/r/javascript/comments/3m6wyu/found_this_line_in_the_react_codebase_made_me/cvcyo4a)

Ok, now I want to inject a React component into the dom. To do that I first need a reference to a container that already exists in the dom. Let's see if I can get one this way:

```html
<!DOCTYPE html>

<html>
    <head>
        <script src="https://unpkg.com/react@15.3.1/dist/react.js"></script>
        <script src="https://unpkg.com/react-dom@15.3.1/dist/react-dom.js">console.log("djfio");</script>
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

```javascript
> div#example
```

Which is a DOM object that you can open up and mess with in the console.

This so far is loosely coupled with this:

https://facebook.github.io/react/docs/getting-started.html

So let's try dropping in that React code.

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

Do I want to use babel? Eventually, yes I do. In this case, it's turning
`<h1>Hello, world!</h1>,` from inlined `jsx` into vanilla javascript.

[More on jsx here.](https://facebook.github.io/react/docs/jsx-in-depth.html)

Maybe I can pass in a string of html, then?

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

I can't pass `<div />` yet, because that's JSX. (To see what that would get
turned into, try this [ REPL
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
that name. What the rendering browser does with that is up to it, but it's neat
to note that the React function doesn't heel you to a particular set of
elements. [Here's a pedantic Stack Overflow thread about
it](http://stackoverflow.com/questions/3593726/whats-stopping-me-from-using-arbitrary-tags-in-html).

```js
ReactDOM.render(
    React.createElement("thingamadoodad"),
    document.getElementById('example')
);
```

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

The function takes three arguments: `type`, `prop`, and `children`. We know
what 'type' is, how about 'props'? I would expect that to map to [html
attributes](http://www.w3schools.com/html/html_attributes.asp). Perhaps a
string?

```js
ReactDOM.render(
    React.createElement("div", "name=thing"),
    document.getElementById('example')
);
```

Nope! But this does give me two error messages!

```
react.js:20483 Warning: React.createElement(...): Expected props argument to be a plain object. Properties defined in its prototype chain will be ignored.

react.js:20483 Warning: Unknown props `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9` on <div> tag. Remove these props from the element. For details, see https://fb.me/react-unknown-prop in div
```

Aha! Using an object as a key/value dictionary makes a lot of sense wrt properties/attributes, since that's essentially what they are!

As for that other error- it comes with a long stack trace that I don't feel
like digging into right now, but I would put money on the string being
`split()` into an array of characters at some point and then `keys()` called
on it somewhere and then some iterator iterating over that somewhere... like try it in
the console!:

```js
var thing = "this is a string".split('').keys()
thing.next()
thing.next()
thing.next()
thing.next()
// etc...
```

That's a guess anyway, but it doesn't matter right now! We're experimenting!

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
    React.createElement("whatsit", { className: "hoohaa", htmlFor: "derp" }),
    document.getElementById('example')
);
```

```html
<whatsit data-reactroot class="hoohaa" for="derp"></whatsit>
```

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
by the `arguments` keyword). You can see this in the function body above!

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
