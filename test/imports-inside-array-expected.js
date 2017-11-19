import livescriptTransformObjectCreate from 'livescript-transform-object-create';
import livescriptTransformEsm from 'livescript-transform-esm';
import livescriptTransformImplicitAsync from 'livescript-transform-implicit-async';
var config;
export { config as default }
(function(){
  config = {
    plugins: [livescriptTransformObjectCreate, livescriptTransformEsm, livescriptTransformImplicitAsync]
  };
}).call(this);
