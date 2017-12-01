Transform for livescript adding support for modules.

# Usage

## CLI

First install livescript and transfrom-esm

npm i -D https://github.com/gkz/LiveScript livescript-transform-esm

next assuming transpilation from src to tmp

node_modules/.bin/lsc -r livescript-transform-esm/register -c -o tmp src 


# Features
## Injecting imports to scope
Tired of manual polluting scope with hundreds of identifiers, let compiler do it for you. 
(for now only relative module are resolved)

```livescipt
    import ...
        './symbols'
```

```livescipt
    import 
        './symbols' : ...
```
both generate
```js
  import { init, create } from './symbols';
  (function(){

  }).call(this);

```



## globs
Globs are expanded during compilation making them transparent for other tools and browser.

```livescipt
    import 'modules/**'
```

```js
  import foo from './modules/foo';
  import Math from './modules/Math';
  import Vector from './modules/Vector';
  (function(){

  }).call(this);
```

## glob + exports = index

```livescipt
    export { import 'modules/**' }
```

```js
  import import$ from './modules/foo';
  import import1$ from './modules/Math';
  import import2$ from './modules/Vector';
  export { import$ as foo }
  export { import1$ as Math }
  export { import2$ as Vector }
  (function(){

  }).call(this);

```

## imports as expressions

```livescipt
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
    (function(){
      config = {
        plugins: [import$, import1$, import2$, import3$, import4$, import5$]
      };
    }).call(this);
```

## async imports
```livescipt
    foo = async import \./modules/foo
    vector-path = \./modules/Vector
    Vector = async import vector-path
```

```js
  (function(){
    var foo, vectorPath, Vector;
    foo = import('./modules/foo');
    vectorPath = './modules/Vector';
    Vector = import(vectorPath);
  }).call(this);
```

