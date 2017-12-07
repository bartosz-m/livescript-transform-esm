Transform for livescript adding support for modules.

**Repository** on [github](https://github.com/bartosz-m/livescript-transform-esm)

# Usage

## CLI

First install livescript and transfrom-esm

    npm i -D https://github.com/gkz/LiveScript livescript-transform-esm


to transpile from `src` to `tmp`

    node_modules/.bin/lsc -r livescript-transform-esm/register -c -o tmp src

to run script use CommonJS module format option e.g. running `test/index.ls`

    node -r livescript-transform-esm/register/cjs -c -o tmp src

# Features

This plugin comes equiped with some extra features which won't be seen in js-land any time soon.


## Injecting imports to scope

Tired of manual polluting scope with hundreds of identifiers, let compiler do it for you. 
(for now only relative module are resolved)

```livescript
import ...
    './symbols'
```

```livescript
import 
    './symbols' : ...
```
both generate
```js
import { init, create } from './symbols';

```



## Globs/wildcards
Importing multiple files never was so easy, you can pass any string compatible with [globby](https://www.npmjs.com/package/globby) and compiler will do the rest.
Globs are expanded during compilation making them transparent for other tools and browser.

```livescript
import 'modules/**'
```

```js
import foo from './modules/foo';
import Math from './modules/Math';
import Vector from './modules/Vector';
```

## glob + exports = index
If you've ever wanted to generated index file base on content of directory it is trivial with this plugin, take export, import, some glob mix the together and here you have:

```livescript
# inside of modules there are: foo.ls, Match.ls, Vector.ls
export { import './modules/**' }
```

```js
import import$ from './modules/foo';
import import1$ from './modules/Math';
import import2$ from './modules/Vector';
export { import$ as foo }
export { import1$ as Math }
export { import2$ as Vector }
```

## imports as expressions
Guys in js-land need to put imports into top scope otherwise its gives theme nice shinny error. But we don't like to obey those silly rules and we can but imports wherever it will make sense. 

```livescript
export default config =
    plugins: [
        import \livescript-transform-object-create
        import \livescript-transform-esm
        import \livescript-transform-implicit-async
        import \livescript-transform-object-create/lib/plugin
        import \livescript-transform-esm/lib/plugin
        import \livescript-transform-implicit-async/lib/plugin
    ]
```

```js
import import$ from 'livescript-transform-object-create';
import import1$ from 'livescript-transform-esm';
import import2$ from 'livescript-transform-implicit-async';
import import3$ from 'livescript-transform-object-create/lib/plugin';
import import4$ from 'livescript-transform-esm/lib/plugin';
import import5$ from 'livescript-transform-implicit-async/lib/plugin';
var config;
export { config as default }
config = {
  plugins: [import$, import1$, import2$, import3$, import4$, import5$]
};
```

## dynamic imports
A riddle: `how to make dynamic import?`  
Answer: `async it`


```livescript
foo = async import \./modules/foo
vector-path = \./modules/Vector
Vector = async import vector-path
```

```js
var foo, vectorPath, Vector;
foo = import('./modules/foo');
vectorPath = './modules/Vector';
Vector = import(vectorPath);
```

## import all

```livescript
import all
    \react
    \./symbols
```

```js
import * as symbols from './symbols';
import * as react from 'react';
```


# Integration

## Atom 

If you are using Atom editor you may be interested in my packages which provide realtime code preview supporting this plugin. 

* [livescript-ide-preview](https://atom.io/packages/livescript-ide-preview) - show transpiled code
* [atom-livescript-provider](https://atom.io/packages/atom-livescript-provider) - provides compilation service


![](https://github.com/bartosz-m/livescript-ide-preview/raw/master/doc/assets/screenshot-01.gif)


## Webpack loader

If you are using Webpack you can try my [loader](https://www.npmjs.com/package/livescript-plugin-loader) whith support for this and other plugins.


# License

[BSD-3-Clause](License.md)