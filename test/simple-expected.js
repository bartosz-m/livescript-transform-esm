(function(){
  var Foo, Vector, export$, export1$, export2$, export3$, export4$, PI, MEANING_OF_LIFE, E, center, center2;
  Foo = 'Foo';
  Vector = 'Vector';
  export { Foo };
  export { Foo as default };
  export$ = 'x';
  export { export$ as default };
  export1$ = 'BarBar';
  export { export1$ as Bar };
  export2$ = 'FooBarBar';
  export { export2$ as FooBar };
  export3$ = function(){
    return 'foo-bar';
  };
  export { export3$ as fooFunction };
  function barBar(){
    return 'foo-bar';
  }
  export { barBar };
  export { Foo };
  export { Vector };
  PI = 3.14;
  export { PI };
  MEANING_OF_LIFE = 42;
  export { MEANING_OF_LIFE };
  E = 2.718281828;
  export { E };
  (function(Zero){
    export4$ = Zero;
  }.call(this, {
    x: 0,
    y: 0
  }));
  export { export4$ as ZeroVector };
  export { export4$ as VectorZero };
  center = 0;
  export { center };
  center2 = center + 1;
  export { center2 };
}).call(this);
