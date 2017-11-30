var import$ = (require('./modules/foo')['__default__'] || require('./modules/foo'));
var import1$ = (require('./modules/Math')['__default__'] || require('./modules/Math'));
var import2$ = (require('./modules/Vector')['__default__'] || require('./modules/Vector'));
(function(){
  exports.foo = import$;
  exports.Math = import1$;
  exports.Vector = import2$;
}).call(this);
