import imports$ from 'livescript-transform-esm/lib/plugin';
import livescriptTransformObjectCreate from 'livescript-transform-object-create';
import livescriptTransformImplicitAsync from 'livescript-transform-implicit-async';
var config;
export { config as default }
(function(){
  config = {
    plugins: [{
      plugin: imports$,
      config: {
        format: 'cjs'
      }
    }]
  };
}).call(this);
