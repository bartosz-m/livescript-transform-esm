(function(){
  module.exports = (function(){
    var prototype = constructor.prototype;
    function constructor(){}
    constructor.prototype.foo = function(){
      return 'bar';
    };
    return constructor;
  }());
  Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
}).call(this);
