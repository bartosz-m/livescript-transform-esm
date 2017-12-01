var imports$ = (require('livescript-transform-esm/lib/plugin')['__default__'] || require('livescript-transform-esm/lib/plugin'));
var livescriptTransformObjectCreate = (require('livescript-transform-object-create')['__default__'] || require('livescript-transform-object-create'));
var livescriptTransformImplicitAsync = (require('livescript-transform-implicit-async')['__default__'] || require('livescript-transform-implicit-async'));
(function(){
  var config;
  module.exports = config = {
    plugins: [{
      plugin: imports$,
      config: {
        format: 'cjs'
      }
    }]
  };
  Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
}).call(this);
