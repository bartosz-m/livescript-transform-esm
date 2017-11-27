(function(){
  var Foo, Vector, PI, MEANING_OF_LIFE, E, fn, Class, BarClass, center, center2;
  Foo = 'Foo';
  Vector = 'Vector';
  exports.Foo = Foo;
  exports['__default__'] = 'x';
  exports.Bar = 'BarBar';
  exports.FooBar = 'FooBarBar';
  exports.fooFunction = function(){
    return 'foo-bar';
  };
  exports.barFunction = function barBar(){
    return 'foo-bar';
  };
  exports.Foo = Foo;
  exports.Vector = Vector;
  exports.PI = PI = 3.14;
  exports.MEANING_OF_LIFE = MEANING_OF_LIFE = 42;
  exports.E = E = 2.718281828;
  exports.fn = fn = function(){
    return "I'm default";
  };
  exports.Class = Class = (function(){
    Class.displayName = 'Class';
    var prototype = Class.prototype, constructor = Class;
    function Class(){}
    Class.prototype.foo = function(){
      return 'bar';
    };
    return Class;
  }());
  exports.BarClass = BarClass = (function(){
    BarClass.displayName = 'BarClass';
    var prototype = BarClass.prototype, constructor = BarClass;
    function BarClass(){}
    return BarClass;
  }());
  exports.center = center = 0;
  exports.center2 = center2 = center + 1;
}).call(this);
