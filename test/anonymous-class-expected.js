(function(){
  exports.default = (function(){
    var prototype = constructor.prototype;
    function constructor(){}
    constructor.prototype.foo = function(){
      return 'bar';
    };
    return constructor;
  }());
}).call(this);
