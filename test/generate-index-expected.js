var import$ = (require('./../foo')['__default__'] || require('./../foo'));
var import1$ = (require('./../Math')['__default__'] || require('./../Math'));
var import2$ = (require('./../Vector')['__default__'] || require('./../Vector'));
(function(){
  exports.foo = import$;
  exports.Math = import1$;
  exports.Vector = import2$;
}).call(this);
