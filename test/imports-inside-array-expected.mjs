import imports$ from 'livescript-transform-object-create';
import imports1$ from 'livescript-transform-esm';
import imports2$ from 'livescript-transform-implicit-async';
import imports3$ from 'livescript-transform-object-create/lib/plugin';
import imports4$ from 'livescript-transform-esm/lib/plugin';
import imports5$ from 'livescript-transform-implicit-async/lib/plugin';
var config;
export { config as default }
(function(){
  config = {
    plugins: [imports$, imports1$, imports2$, imports3$, imports4$, imports5$]
  };
}).call(this);
