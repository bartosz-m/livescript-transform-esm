var assert = (require('assert')['__default__'] || require('assert'));
var Node = (require('livescript-compiler/lib/livescript/ast/Node')['__default__'] || require('livescript-compiler/lib/livescript/ast/Node'));
var { parent, type } = require('livescript-compiler/lib/livescript/ast/symbols');
var { copy, js, asNode } = require('js-nodes/symbols');
var ObjectNode = (require('js-nodes/ObjectNode')['__default__'] || require('js-nodes/ObjectNode'));
var { init } = require('livescript-compiler/lib/core/symbols');
var Export, ref$, slice$ = [].slice, arrayFrom$ = Array.from || function(x){return slice$.call(x);};
module.exports = Export = Node[copy]();
Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
Export[asNode].name = 'Export';
Export[asNode].importEnumerable((ref$ = {}, ref$[type] = 'Export.ast.livescript', ref$[init] = function(arg$){
  this.local = arg$.local, this.alias = arg$.alias;
}, ref$.childrenNames = ['local', 'alias'], ref$.traverseChildren = function(visitor, crossScopeBoundary){
  var i$, ref$, len$, childName, child;
  for (i$ = 0, len$ = (ref$ = this.childrenNames).length; i$ < len$; ++i$) {
    childName = ref$[i$];
    if (child = this[childName]) {
      visitor(child, this, childName);
    }
  }
  for (i$ = 0, len$ = (ref$ = this.childrenNames).length; i$ < len$; ++i$) {
    childName = ref$[i$];
    if (child = this[childName]) {
      child.traverseChildren.apply(child, arguments);
    }
  }
}, Object.defineProperty(ref$, 'name', {
  get: function(){
    var ref$;
    return (ref$ = this.alias) != null
      ? ref$
      : this.local;
  },
  configurable: true,
  enumerable: true
}), Object.defineProperty(ref$, 'default', {
  get: function(){
    var ref$;
    return ((ref$ = this.alias) != null ? ref$.name : void 8) === 'default';
  },
  configurable: true,
  enumerable: true
}), ref$.compile = function(o){
  var alias, inner;
  alias = this.alias
    ? this.alias.name !== 'default'
      ? [" as ", this.alias.compile(o)]
      : [" as default"]
    : [];
  inner = this.local.compile(o);
  return this.toSourceNode({
    parts: ["export { ", inner].concat(arrayFrom$(alias), [" }"])
  });
}, ref$.terminator = ';', Object.defineProperty(ref$, 'local', {
  get: function(){
    return this._local;
  },
  set: function(v){
    v[parent] = this;
    this._local = v;
  },
  configurable: true,
  enumerable: true
}), Object.defineProperty(ref$, 'alias', {
  get: function(){
    return this._alias;
  },
  set: function(v){
    if (v != null) {
      v[parent] = this;
    }
    this._alias = v;
  },
  configurable: true,
  enumerable: true
}), ref$.replaceChild = function(child, node){
  var i$, ref$, len$, childName;
  for (i$ = 0, len$ = (ref$ = this.childrenNames).length; i$ < len$; ++i$) {
    childName = ref$[i$];
    if (this[childName] === child) {
      this[childName] = node;
      node[parent] = this;
      child[parent] = null;
      return child;
    }
  }
  throw Error("Node is not a child of Export");
}, ref$));
//# sourceMappingURL=Export.js.map
