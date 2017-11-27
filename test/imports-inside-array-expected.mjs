import import$ from 'livescript-transform-object-create';
import import1$ from 'livescript-transform-esm';
import import2$ from 'livescript-transform-implicit-async';
import import3$ from 'livescript-transform-object-create/lib/plugin';
import import4$ from 'livescript-transform-esm/lib/plugin';
import import5$ from 'livescript-transform-implicit-async/lib/plugin';
var config;
export { config as default }
(function(){
  config = {
    plugins: [import$, import1$, import2$, import3$, import4$, import5$]
  };
}).call(this);
