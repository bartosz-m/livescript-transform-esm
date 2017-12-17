(function(){
  var foo, vectorPath, Vector;
  foo = Promise.resolve( require('./modules/foo')['__default__'] || require('./modules/foo') );
  vectorPath = './modules/Vector';
  Vector = Promise.resolve( require(vectorPath)['__default__'] || require(vectorPath) );
}).call(this);
