var imports$ = (require('livescript-transform-object-create')['__default__'] || require('livescript-transform-object-create'));
var imports1$ = (require('livescript-transform-esm')['__default__'] || require('livescript-transform-esm'));
var imports2$ = (require('livescript-transform-implicit-async')['__default__'] || require('livescript-transform-implicit-async'));
var imports3$ = (require('livescript-transform-object-create/lib/plugin')['__default__'] || require('livescript-transform-object-create/lib/plugin'));
var imports4$ = (require('livescript-transform-esm/lib/plugin')['__default__'] || require('livescript-transform-esm/lib/plugin'));
var imports5$ = (require('livescript-transform-implicit-async/lib/plugin')['__default__'] || require('livescript-transform-implicit-async/lib/plugin'));
(function(){
  var config;
  module.exports = config = {
    plugins: [imports$, imports1$, imports2$, imports3$, imports4$, imports5$]
  };
  Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
}).call(this);
