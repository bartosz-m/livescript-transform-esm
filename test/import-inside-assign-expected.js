var lsCompile = require('./ls-compile');
var import$ = require('../compiler.config.ls');
(function(){
  var x$;
  x$ = lsCompile;
  x$.watch = false;
  x$.config = import$;
}).call(this);
