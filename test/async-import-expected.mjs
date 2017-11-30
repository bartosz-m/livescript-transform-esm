(function(){
  var foo, vectorPath, Vector;
  foo = import('./modules/foo');
  vectorPath = './modules/Vector';
  Vector = import(vectorPath);
}).call(this);
