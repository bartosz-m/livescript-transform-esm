var Foo,Bar,FooBar,fooFunction,barBar,Foo,Vector,PI,MEANING_OF_LIFE,E,export6$,center,center2;
export { Foo }
export { Foo as default }
export { export$ as default }
export { export1$ as Bar }
export { export2$ as FooBar }
export { export3$ as fooFunction }
export { barBar }
export { Foo }
export { Vector }
export { PI }
export { MEANING_OF_LIFE }
export { E }
export { export4$ as default }
export { export5$ as default }
export { export6$ }
export { center }
export { center2 }
(function(){
  var Bar;
  Foo = 'Foo';
  Vector = 'Vector';
  export$ = 'x';
  export1$ = 'BarBar';
  export2$ = 'FooBarBar';
  export3$ = function(){
    return 'foo-bar';
  };
  function barBar(){
    return 'foo-bar';
  }
  PI = 3.14;
  MEANING_OF_LIFE = 42;
  E = 2.718281828;
  export4$ = function(){
    return "I'm default";
  };
  export5$ = (function(){
    var prototype = constructor.prototype;
    function constructor(){}
    constructor.prototype.foo = function(){
      return 'bar';
    };
    return constructor;
  }());
  export6$ = Bar = (function(){
    Bar.displayName = 'Bar';
    var prototype = Bar.prototype, constructor = Bar;
    function Bar(){}
    return Bar;
  }());
  center = 0;
  center2 = center + 1;
}).call(this);
