var assert = (require('assert')['__default__'] || require('assert'));
var Node = (require('livescript-compiler/lib/livescript/ast/Node')['__default__'] || require('livescript-compiler/lib/livescript/ast/Node'));
var JsNode = (require('js-nodes/JsNode')['__default__'] || require('js-nodes/JsNode'));
var { copy, js, asNode } = require('js-nodes/symbols');
var ObjectNode = (require('js-nodes/ObjectNode')['__default__'] || require('js-nodes/ObjectNode'));
var { parent, type } = require('livescript-compiler/lib/livescript/ast/symbols');
var { parent, type } = require('livescript-compiler/lib/livescript/ast/symbols');
var { init } = require('livescript-compiler/lib/core/symbols');
var Import, ref$;
module.exports = Import = Node[copy]();
Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
Import[asNode].importEnumerable((ref$ = {}, ref$[type] = 'Import.ast.livescript', ref$[init] = function(arg$){
  this.names = arg$.names, this.source = arg$.source, this.all = arg$.all;
}, Object.defineProperty(ref$, 'names', {
  get: function(){
    return this._names;
  },
  set: function(v){
    if (v != null) {
      v[parent] = this;
    }
    this._names = v;
  },
  configurable: true,
  enumerable: true
}), Object.defineProperty(ref$, 'source', {
  get: function(){
    return this._source;
  },
  set: function(v){
    if (v != null) {
      v[parent] = this;
    }
    this._source = v;
  },
  configurable: true,
  enumerable: true
}), ref$.traverseChildren = function(visitor, crossScopeBoundary){
  var ref$;
  if (this.names) {
    visitor(this.names, this, 'names');
  }
  if (this.source) {
    visitor(this.source, this, 'source');
  }
  if (this.names) {
    (ref$ = this.names).traverseChildren.apply(ref$, arguments);
  }
  if (this.source) {
    (ref$ = this.source).traverseChildren.apply(ref$, arguments);
  }
}, ref$.compile = function(o){
  var names;
  names = this.names.compile(o);
  return this.toSourceNode({
    parts: ["import ", names, " from ", this.source.compile(o), this.terminator]
  });
}, ref$.terminator = ';', ref$));
//# sourceMappingURL=Import.js.map
