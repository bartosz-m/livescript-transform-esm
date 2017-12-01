import lsCompile from './ls-compile';
import imports$ from '../compiler.config.ls';
(function(){
  var x$;
  x$ = lsCompile;
  x$.watch = false;
  x$.config = imports$;
}).call(this);
