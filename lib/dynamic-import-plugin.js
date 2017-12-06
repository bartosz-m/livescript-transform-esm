var imports$ = (require('livescript-compiler/lib/livescript/ast/symbols')['__default__'] || require('livescript-compiler/lib/livescript/ast/symbols'));
var assert = (require('assert')['__default__'] || require('assert'));
var Plugin = (require('livescript-compiler/lib/livescript/Plugin')['__default__'] || require('livescript-compiler/lib/livescript/Plugin'));
var { JsNode } = require('js-nodes');
var { copy, asNode } = require('js-nodes/symbols');
var { create, init } = require('livescript-compiler/lib/core/symbols');
var Export = (require('./livescript/ast/Export')['__default__'] || require('./livescript/ast/Export'));
var ReExport = (require('./livescript/ast/ReExport')['__default__'] || require('./livescript/ast/ReExport'));
var DynamicImport = (require('./livescript/ast/DynamicImport')['__default__'] || require('./livescript/ast/DynamicImport'));
var Import = (require('./livescript/ast/Import')['__default__'] || require('./livescript/ast/Import'));
var MatchMap = (require('./nodes/MatchMap')['__default__'] || require('./nodes/MatchMap'));
var parent, type, InsertDynamicImport, x$, DynamicImportTransform, slice$ = [].slice, arrayFrom$ = Array.from || function(x){return slice$.call(x);};
parent = imports$.parent, type = imports$.type;
InsertDynamicImport = MatchMap[copy]();
InsertDynamicImport.name = 'InsertDynamicImport';
InsertDynamicImport.ast = {};
InsertDynamicImport.match = function(node){
  var head, call;
  if (node[type] === 'Chain' && (head = node.head)[type] === 'Var' && head.value === '__dynamic-import__' && (call = node.tails[0])[type] === 'Call') {
    return call.args;
  }
};
InsertDynamicImport.map = function(sources){
  return this.ast.DynamicImport[create]({
    sources: sources
  });
};
module.exports = x$ = DynamicImportTransform = clone$(Plugin);
module.exports = x$;
x$.name = 'dynamic-import';
x$.config = {};
x$.enable = function(){
  var x$, specialLex, y$, ref$;
  x$ = specialLex = JsNode[copy]();
  x$.jsFunction = function(lexed){
    var result, i, buffer, l, rest, source, x$, fnName;
    result = [];
    i = -1;
    buffer = [lexed[0], lexed[1]];
    while (++i < lexed.length) {
      l = lexed[i];
      rest = slice$.call(l, 2);
      if (l[0] === 'ID' && l[1] === 'async' && i + 2 < lexed.length && lexed[i + 1][0] === 'IMPORT') {
        source = lexed[i + 2];
        rest = slice$.call(l, 2);
        x$ = fnName = ['ID', '__dynamic-import__'].concat(arrayFrom$(rest));
        x$.spaced = true;
        result.push(x$);
        rest = slice$.call(source, 2);
        result.push(['CALL(', ''].concat(arrayFrom$(rest)));
        i++;
        i++;
        result.push(source);
        result.push([')CALL', ''].concat(arrayFrom$(rest)));
      } else {
        result.push(l);
      }
    }
    return result;
  };
  this.livescript.lexer.tokenize.append(specialLex);
  this.livescript.ast.DynamicImport = DynamicImport[copy]();
  y$ = this.livescript.expand;
  y$.append((ref$ = clone$(InsertDynamicImport), ref$.ast = this.livescript.ast, ref$));
  if (this.config.format === 'cjs') {
    this.livescript.ast.DynamicImport.compile[asNode].jsFunction = function(o){
      var sources, this$ = this;
      sources = this.sources.map(function(it){
        return it.compile(o);
      });
      return this.toSourceNode({
        parts: ["Promise.resolve( require(", sources, ") )"]
      });
    };
  }
};
Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
function clone$(it){
  function fun(){} fun.prototype = it;
  return new fun;
}
//# sourceMappingURL=dynamic-import-plugin.js.map
