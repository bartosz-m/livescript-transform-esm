import lsCompile from './ls-compile';
import export$ from '../compiler.config.ls';
(function(){
  var x$;
  x$ = lsCompile;
  x$.watch = false;
  x$.config = export$;
}).call(this);
