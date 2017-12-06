var Node = (require('livescript-compiler/lib/livescript/ast/Node')['__default__'] || require('livescript-compiler/lib/livescript/ast/Node'));
var { parent, type } = require('livescript-compiler/lib/livescript/ast/symbols');
var { copy, js, asNode } = require('js-nodes/symbols');
var ObjectNode = (require('js-nodes/ObjectNode')['__default__'] || require('js-nodes/ObjectNode'));
var { init } = require('livescript-compiler/lib/core/symbols');
var ReExport, ref$;
module.exports = ReExport = Node[copy]();
Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
ReExport[asNode].name = 'ReExport';
ReExport[asNode].importEnumerable((ref$ = {}, ref$[type] = 'ReExport.ast.livescript', ref$[init] = function(arg$){
  this.names = arg$.names, this.source = arg$.source;
}, ref$.childrenNames = ['names', 'source'], ref$.traverseChildren = function(visitor, crossScopeBoundary){
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
  return this.toSourceNode({
    parts: ["export ", this.names.compile(o), " from ", this.source.compile(o)]
  });
}, ref$.terminator = ';', Object.defineProperty(ref$, 'names', {
  get: function(){
    return this._names;
  },
  set: function(v){
    v[parent] = this;
    this._names = v;
  },
  configurable: true,
  enumerable: true
}), Object.defineProperty(ref$, 'source', {
  get: function(){
    return this._source;
  },
  set: function(v){
    v[parent] = this;
    this._source = v;
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
  throw Error("Node is not a child of ReExport");
}, ref$));
//# sourceMappingURL=ReExport.js.map
