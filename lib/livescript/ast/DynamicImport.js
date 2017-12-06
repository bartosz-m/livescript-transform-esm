var assert = (require('assert')['__default__'] || require('assert'));
var Node = (require('livescript-compiler/lib/livescript/ast/Node')['__default__'] || require('livescript-compiler/lib/livescript/ast/Node'));
var { JsNode, ObjectNode } = require('js-nodes');
var { copy, js, asNode } = require('js-nodes/symbols');
var { parent, type } = require('livescript-compiler/lib/livescript/ast/symbols');
var { init } = require('livescript-compiler/lib/core/symbols');
var DynamicImport, ref$, toString$ = {}.toString;
module.exports = DynamicImport = Node[copy]();
Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
DynamicImport[asNode].name = 'DynamicImport';
DynamicImport[asNode].importEnumerable((ref$ = {}, ref$[type] = 'DynamicImport.ast.livescript', ref$[init] = function(arg$){
  this.sources = arg$.sources;
}, ref$.childrenNames = [], Object.defineProperty(ref$, 'sources', {
  get: function(){
    return this._sources;
  },
  set: function(v){
    if (v != null) {
      v[parent] = this;
    }
    this._sources = v;
  },
  configurable: true,
  enumerable: true
}), ref$.traverseChildren = function(visitor, crossScopeBoundary){
  var i$, ref$, len$, childName, child, j$, len1$, k, v;
  for (i$ = 0, len$ = (ref$ = this.childrenNames).length; i$ < len$; ++i$) {
    childName = ref$[i$];
    if (child = this[childName]) {
      if ('Array' === toString$.call(child).slice(8, -1)) {
        for (j$ = 0, len1$ = child.length; j$ < len1$; ++j$) {
          k = j$;
          v = child[j$];
          visitor(v, this, childName, k);
        }
      } else {
        visitor(child, this, childName);
      }
    }
  }
  for (i$ = 0, len$ = (ref$ = this.childrenNames).length; i$ < len$; ++i$) {
    childName = ref$[i$];
    if (child = this[childName]) {
      if ('Array' === toString$.call(child).slice(8, -1)) {
        for (j$ = 0, len1$ = child.length; j$ < len1$; ++j$) {
          k = j$;
          v = child[j$];
          v.traverseChildren.apply(this, arguments);
        }
      } else {
        child.traverseChildren.apply(this, arguments);
      }
    }
  }
}, ref$.compile = function(o){
  var sources, this$ = this;
  sources = this.sources.map(function(it){
    return it.compile(o);
  });
  return this.toSourceNode({
    parts: ["import(", sources, ")"]
  });
}, ref$.terminator = ';', ref$));
//# sourceMappingURL=DynamicImport.js.map
