var lsCompile = (require('./ls-compile')['__default__')] || require('./ls-compile'));
var import$ = (require('../compiler.config.ls')['__default__')] || require('../compiler.config.ls'));
(function(){
  var x$;
  x$ = lsCompile;
  x$.watch = false;
  x$.config = import$;
}).call(this);
