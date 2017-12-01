(function(){
  var foo, vectorPath, Vector;
  foo = Promise.resolve( require('./modules/foo') );
  vectorPath = './modules/Vector';
  Vector = Promise.resolve( require(vectorPath) );
}).call(this);
