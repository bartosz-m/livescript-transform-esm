import export$ from 'livescript-transform-object-create';
import export1$ from 'livescript-transform-esm';
import export2$ from 'livescript-transform-implicit-async';
import export3$ from 'livescript-transform-object-create/lib/plugin';
import export4$ from 'livescript-transform-esm/lib/plugin';
import export5$ from 'livescript-transform-implicit-async/lib/plugin';
var config;
export { config as default }
(function(){
  config = {
    plugins: [export$, export1$, export2$, export3$, export4$, export5$]
  };
}).call(this);
