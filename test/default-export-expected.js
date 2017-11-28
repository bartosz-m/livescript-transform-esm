(function(){
  module.exports = function(){
    return console.log('ok');
  };
  Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
}).call(this);
