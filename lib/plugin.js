var imports$ = (require('livescript-compiler/lib/livescript/ast/symbols')['__default__'] || require('livescript-compiler/lib/livescript/ast/symbols'));
var assert = (require('assert')['__default__'] || require('assert'));
var fs = (require('fs')['__default__'] || require('fs'));
var path = (require('path')['__default__'] || require('path'));
var Creatable = (require('livescript-compiler/lib/core/components/Creatable')['__default__'] || require('livescript-compiler/lib/core/components/Creatable'));
var { importProperties } = require('livescript-compiler/lib/composition');
var Assign = (require('livescript-compiler/lib/livescript/ast/Assign')['__default__'] || require('livescript-compiler/lib/livescript/ast/Assign'));
var Identifier = (require('livescript-compiler/lib/livescript/ast/Identifier')['__default__'] || require('livescript-compiler/lib/livescript/ast/Identifier'));
var Literal = (require('livescript-compiler/lib/livescript/ast/Literal')['__default__'] || require('livescript-compiler/lib/livescript/ast/Literal'));
var Node = (require('livescript-compiler/lib/livescript/ast/Node')['__default__'] || require('livescript-compiler/lib/livescript/ast/Node'));
var ObjectPattern = (require('livescript-compiler/lib/livescript/ast/ObjectPattern')['__default__'] || require('livescript-compiler/lib/livescript/ast/ObjectPattern'));
var Pattern = (require('livescript-compiler/lib/livescript/ast/Pattern')['__default__'] || require('livescript-compiler/lib/livescript/ast/Pattern'));
var TemporarVariable = (require('livescript-compiler/lib/livescript/ast/TemporarVariable')['__default__'] || require('livescript-compiler/lib/livescript/ast/TemporarVariable'));
var Plugin = (require('livescript-compiler/lib/livescript/Plugin')['__default__'] || require('livescript-compiler/lib/livescript/Plugin'));
var MatchMapCascadeNode = (require('js-nodes/MatchMapCascadeNode')['__default__'] || require('js-nodes/MatchMapCascadeNode'));
var { ConditionalNode, IfNode, identity, TrueNode, JsNode } = require('js-nodes');
var { copy, asNode } = require('js-nodes/symbols');
var SourceNode = (require('livescript-compiler/lib/livescript/SourceNode')['__default__'] || require('livescript-compiler/lib/livescript/SourceNode'));
var { create, init } = require('livescript-compiler/lib/core/symbols');
var Export = (require('./livescript/ast/Export')['__default__'] || require('./livescript/ast/Export'));
var ReExport = (require('./livescript/ast/ReExport')['__default__'] || require('./livescript/ast/ReExport'));
var Import = (require('./livescript/ast/Import')['__default__'] || require('./livescript/ast/Import'));
var MatchMap = (require('./nodes/MatchMap')['__default__'] || require('./nodes/MatchMap'));
var importPlugin = (require('./import-plugin')['__default__'] || require('./import-plugin'));
var dynamicImportPlugin = (require('./dynamic-import-plugin')['__default__'] || require('./dynamic-import-plugin'));
var { copySourceLocation } = require('./utils');
var parent, type, asArray, literalToString, extractNameFromSource, x$, TemporarAssigment, BaseNode, CascadeRule, ExportRules, ExpandArrayExports, ExpandBlockExports, EnableDefaultExports, WrapLiteralExports, WrapAnonymousFunctionExports, ExpandObjectExports, ExpandObjectPatternExports, getIdentifier, ExpandCascadeExports, SplitAssignExports, InsertExportNodes, ref$, AssignParent, AssignFilename, ConditionalMutate, FilterAst, ProcessArray, RemoveNode, OnlyExports, ExportsAndReExports, RemoveNodes, RegisterExportsOnRoot, ExtractExportNameFromAssign, ExtractExportNameFromLiteral, ExtractNameFromClass, ExtractExportNameFromImport, MoveExportsToTop, isExpression, ReplaceImportWithTemporarVariable, RemoveOrReplaceImport, y$, RemoveOrReplaceImports, identifierFromVar, ReplaceVariableWithIdentifier, DisableImplicitExportVariableDeclaration, sn, z$, AddExportsDeclarations, CheckIfOnlyDefaultExports, MarkAsScript, z1$, AddImportsDeclarations, TransformESM, toString$ = {}.toString, this$ = this, slice$ = [].slice, arrayFrom$ = Array.from || function(x){return slice$.call(x);};
parent = imports$.parent, type = imports$.type;
asArray = function(it){
  if (Array.isArray(it)) {
    return it;
  } else {
    return [it];
  }
};
literalToString = function(it){
  return it.value.substring(1, it.value.length - 1);
};
extractNameFromSource = function(it){
  var this$ = this;
  return path.basename(
  function(it){
    return it[it.length - 1];
  }(
  function(it){
    return it.split(path.sep);
  }(
  function(it){
    return it.replace(/'/gi, '');
  }(
  it))));
};
x$ = TemporarAssigment = clone$(Node);
importProperties(x$, Creatable);
TemporarAssigment[type] = 'TemporarAssigment';
TemporarAssigment[init] = function(arg$){
  this.left = arg$.left, this.right = arg$.right;
  this.left[parent] = this;
  this.right[parent] = this;
};
TemporarAssigment.traverseChildren = function(visitor, crossScopeBoundary){
  var ref$;
  visitor(this.left, this, 'left');
  visitor(this.right, this, 'right');
  (ref$ = this.left).traverseChildren.apply(ref$, arguments);
  return (ref$ = this.right).traverseChildren.apply(ref$, arguments);
};
TemporarAssigment.compile = function(o){
  return this.toSourceNode({
    parts: [this.left.compile(o), ' = ', this.right.compile(o)]
  });
};
TemporarAssigment.terminator = ';';
Object.defineProperty(TemporarAssigment, 'left', {
  get: function(){
    return this._left;
  },
  set: function(v){
    v[parent] = this;
    this._left = v;
  },
  configurable: true,
  enumerable: true
});
Object.defineProperty(TemporarAssigment, 'right', {
  get: function(){
    return this._right;
  },
  set: function(v){
    v[parent] = this;
    this._right = v;
  },
  configurable: true,
  enumerable: true
});
BaseNode = clone$(null);
BaseNode.name = 'BaseNode';
BaseNode.copy = function(){
  return clone$(this);
};
BaseNode[copy] = function(){
  return clone$(this);
};
BaseNode.remove = function(){
  throw Error("Unimplemented method remove in " + this.name);
};
BaseNode.call = function(arg$){
  var args, res$, i$, to$;
  res$ = [];
  for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
    res$.push(arguments[i$]);
  }
  args = res$;
  return this.exec.apply(this, args);
};
BaseNode.apply = function(arg$, args){
  return this.exec.apply(this, args);
};
CascadeRule = {
  append: function(rule){
    var ref$;
    if (!rule.copy) {
      throw new Error("Creating node " + ((ref$ = rule.name) != null ? ref$ : '') + " without copy method is realy bad practice");
    }
    if (!rule.name) {
      throw new Error("Adding rule without a name is realy bad practice");
    }
    return this.rules.push(rule);
  },
  remove: function(ruleOrFilter){
    var idx, rule;
    idx = 'Function' === toString$.call(ruleOrFilter).slice(8, -1)
      ? this.rules.findIndex(ruleOrFilter)
      : this.rules.indexOf(ruleOrFilter);
    if (idx !== -1) {
      rule = this.rules[idx];
      this.rules.splice(idx, 1);
      return rule;
    } else {
      throw Error("Cannot remove rule - there is none matching");
    }
  }
};
ExportRules = clone$(CascadeRule);
ExportRules.name = 'Export';
ExportRules.rules = [];
ExportRules.match = function(it){
  var i$, ref$, len$, rule, m, result;
  if (it[type] === Export[type]) {
    for (i$ = 0, len$ = (ref$ = this.rules).length; i$ < len$; ++i$) {
      rule = ref$[i$];
      if (m = rule.match(it)) {
        result = {
          rule: rule,
          matched: m
        };
        break;
      }
    }
  }
  return result;
};
ExportRules.map = function(arg$){
  var rule, matched, replacer;
  rule = arg$.rule, matched = arg$.matched;
  replacer = rule.replace(matched);
  return asArray(replacer);
};
ExpandArrayExports = clone$(BaseNode);
ExpandArrayExports.name = 'ExpandArrayExports';
ExpandArrayExports.ast = {};
ExpandArrayExports.match = function(it){
  if (it.local[type] === 'Arr') {
    return it.local.items;
  }
};
ExpandArrayExports.map = function(items){
  var this$ = this;
  return items.map(function(it){
    return this$.ast.Export[create]({
      local: it
    });
  });
};
ExpandBlockExports = clone$(BaseNode);
ExpandBlockExports.name = 'ExpandBlockExports';
ExpandBlockExports.ast = {};
ExpandBlockExports.match = function(it){
  if (it.local[type] === 'Block') {
    return {
      lines: it.local.lines,
      alias: it.alias
    };
  }
};
ExpandBlockExports.map = function(arg$){
  var lines, alias, this$ = this;
  lines = arg$.lines, alias = arg$.alias;
  return lines.map(function(it){
    return this$.ast.Export[create]({
      local: it,
      alias: alias
    });
  });
};
EnableDefaultExports = clone$(BaseNode);
EnableDefaultExports.name = 'EnableDefaultExports';
EnableDefaultExports.ast = {};
EnableDefaultExports.match = function(it){
  var cascade;
  if ((cascade = it.local)[type] === 'Cascade' && cascade.input[type] === 'Var' && cascade.input.value === '__es-export-default__') {
    return {
      line: cascade.output.lines[0],
      identifierSource: cascade.input
    };
  }
};
EnableDefaultExports.map = function(arg$){
  var line, identifierSource, x$, identifier;
  line = arg$.line, identifierSource = arg$.identifierSource;
  x$ = identifier = Identifier[create]({
    name: 'default'
  });
  copySourceLocation(identifierSource, x$);
  return this.ast.Export[create]({
    local: line,
    alias: identifier
  });
};
WrapLiteralExports = clone$(BaseNode);
WrapLiteralExports.name = 'WrapLiteralExports';
WrapLiteralExports.ast = {};
WrapLiteralExports.match = function(it){
  var local, Type;
  local = it.local;
  Type = local[type];
  if (Type === 'Literal' || (Type === 'Fun' && local.name == null) || (Type === 'Class' && local.name == null)) {
    return it;
  }
};
WrapLiteralExports.map = function(node){
  var x$, tmp, assign;
  x$ = tmp = TemporarVariable[create]({
    name: 'export',
    isExport: true
  });
  copySourceLocation(node, x$);
  assign = TemporarAssigment[create]({
    left: tmp,
    right: node.local
  });
  return [
    assign, this.ast.Export[create]({
      local: assign.left,
      alias: node.alias
    })
  ];
};
WrapAnonymousFunctionExports = clone$(BaseNode);
WrapAnonymousFunctionExports.name = 'WrapAnonymousFunctionExports';
WrapAnonymousFunctionExports.ast = {};
WrapAnonymousFunctionExports.match = function(it){
  var fn;
  if ((fn = it.local)[type] === 'Fun' && fn.name != null) {
    return fn;
  }
};
WrapAnonymousFunctionExports.map = function(fn){
  var x$, identifier;
  x$ = identifier = Identifier[create]({
    name: fn.name
  }, {
    exported: true
  });
  copySourceLocation(fn, x$);
  return [
    fn, this.ast.Export[create]({
      local: identifier
    })
  ];
};
ExpandObjectExports = clone$(BaseNode);
ExpandObjectExports.name = 'ExpandObjectExports';
ExpandObjectExports.ast = {};
ExpandObjectExports.match = function(it){
  var object;
  if ((object = it.local)[type] === 'Obj') {
    return object.items;
  }
};
ExpandObjectExports.map = function(items){
  var this$ = this;
  return items.map(function(prop){
    var key, val, x$;
    key = prop.key, val = prop.val;
    x$ = this$.ast.Export[create]({
      local: val,
      alias: key
    });
    copySourceLocation(prop, x$);
    return x$;
  });
};
ExpandObjectPatternExports = clone$(BaseNode);
ExpandObjectPatternExports.name = 'ExpandObjectExports';
ExpandObjectPatternExports.ast = {};
ExpandObjectPatternExports.match = function(it){
  var object;
  if ((object = it.local)[type] === ObjectPattern[type]) {
    return object.items;
  }
};
ExpandObjectPatternExports.map = function(items){
  var this$ = this;
  return items.map(function(it){
    var x$;
    x$ = this$.ast.Export[create]({
      local: it
    });
    copySourceLocation(it, x$);
    return x$;
  });
};
getIdentifier = function(it){
  var Type;
  Type = it[type];
  switch (Type) {
  case 'Assign' || Assign[type]:
    return getIdentifier(it.left);
  case 'Var':
    return Identifier[create]({
      name: it.value
    });
  default:
    throw Error("Cannot deduce identifier at " + it.line + ":" + it.column);
  }
};
ExpandCascadeExports = MatchMap[copy]();
ExpandCascadeExports.name = 'ExpandCascadeExports';
ExpandCascadeExports.ast = {};
ExpandCascadeExports.match = function(it){
  var cascade;
  if ((cascade = it.local)[type] === 'Cascade') {
    return {
      cascade: cascade,
      alias: it.alias
    };
  }
};
ExpandCascadeExports.map = function(arg$){
  var cascade, alias, x$, identifier, ex;
  cascade = arg$.cascade, alias = arg$.alias;
  if (alias) {
    x$ = identifier = getIdentifier(cascade.input);
    copySourceLocation(cascade.input, x$);
    ex = this.ast.Export[create]({
      local: identifier,
      alias: alias
    });
    return [cascade, ex];
  } else {
    throw Error("Cannot detect export alias at " + cascade.line + ":" + cascade.column);
  }
};
SplitAssignExports = clone$(BaseNode);
SplitAssignExports.name = 'SplitAssignExports';
SplitAssignExports.ast = {};
SplitAssignExports[copy] = function(){
  return clone$(this);
};
SplitAssignExports.match = function(it){
  var assign;
  if ((assign = it.local)[type] === 'Assign') {
    return {
      alias: it.alias,
      assign: assign
    };
  }
};
SplitAssignExports.map = function(arg$){
  var alias, assign, x$, identifier;
  alias = arg$.alias, assign = arg$.assign;
  x$ = identifier = Identifier[create]({
    name: assign.left.value,
    exported: true
  });
  copySourceLocation(assign.left, x$);
  assign.left = identifier;
  return [
    assign, this.ast.Export[create]({
      local: assign.left,
      alias: alias
    })
  ];
};
SplitAssignExports.exec = function(it){
  var matched;
  if (matched = this.match(it)) {
    return this.replace(matched);
  }
};
InsertExportNodes = (ref$ = {
  name: 'InsertExportNodes',
  ast: {},
  match: function(node){
    if (node[type] === 'Cascade' && node.input.value === '__es-export__') {
      return node;
    }
  },
  map: function(cascade){
    var lines, this$ = this;
    lines = cascade.output.lines;
    if (lines.length === 0) {
      throw Error("Empty export at " + cascade.line + ":" + cascade.column);
    }
    return lines.map(function(it){
      return this$.ast.Export[create]({
        local: it
      });
    });
  },
  exec: function(value){
    var matched;
    if (matched = this.match(value)) {
      return this.map(matched);
    }
  }
}, ref$[copy] = function(){
  return clone$(this);
}, ref$);
AssignParent = {
  name: 'AssignParent',
  match: function(node){
    var childrenWithoutParent;
    childrenWithoutParent = node.getChildren().filter(function(it){
      return !(it[parent] != null);
    });
    if (childrenWithoutParent.length) {
      return {
        node: node,
        children: childrenWithoutParent
      };
    }
  },
  map: function(arg$){
    var node, children, i$, len$, child;
    node = arg$.node, children = arg$.children;
    for (i$ = 0, len$ = children.length; i$ < len$; ++i$) {
      child = children[i$];
      child[parent] = node;
    }
    return node;
  }
};
AssignFilename = {
  name: 'AssignFilename',
  match: function(node){
    if (!node.filename) {
      return node;
    }
  },
  map: function(node){
    node.filename = node[parent].filename;
    return node;
  }
};
ConditionalMutate = clone$(BaseNode);
ConditionalMutate.name = 'ConditionalMutate';
ConditionalMutate.test = TrueNode;
ConditionalMutate.mutate = identity;
ConditionalMutate.apply = function(thisArg, args){
  if (this.test.apply(thisArg, args)) {
    this.mutate.apply(thisArg, args);
  }
};
ConditionalMutate.exec = function(){
  if (this.test.apply(this, arguments)) {
    this.mutate.apply(this, arguments);
  }
};
FilterAst = clone$(BaseNode);
FilterAst.test = function(){
  return true;
};
FilterAst.exec = function(astRoot, crossScopeBoundary){
  var result, walk, this$ = this;
  result = [];
  walk = function(node, parent, name, index){
    if (this$.test(node)) {
      result.push(node);
    }
  };
  astRoot.traverseChildren(walk);
  return result;
};
ProcessArray = clone$(BaseNode);
ProcessArray.name = 'ProcessArray';
ProcessArray.each = function(){};
ProcessArray.exec = function(it){
  var i$, len$, e, results$ = [];
  for (i$ = 0, len$ = it.length; i$ < len$; ++i$) {
    e = it[i$];
    results$.push(this.each.call(null, e));
  }
  return results$;
};
RemoveNode = clone$(BaseNode);
RemoveNode.name = 'RemoveNode';
RemoveNode.exec = function(node){
  return node.remove();
};
RemoveNode.execArray = function(array){
  var i$, len$, e, results$ = [];
  for (i$ = 0, len$ = array.length; i$ < len$; ++i$) {
    e = array[i$];
    results$.push(this.exec(e));
  }
  return results$;
};
OnlyExports = clone$(FilterAst);
OnlyExports.name = 'OnlyExports';
OnlyExports.test = function(it){
  return in$(it[type], [Export[type]]);
};
ExportsAndReExports = clone$(FilterAst);
ExportsAndReExports.name = 'ExportsAndReExports';
ExportsAndReExports.test = function(it){
  var ref$;
  return (ref$ = it[type]) === Export[type] || ref$ === ReExport[type];
};
RemoveNodes = ProcessArray.copy();
RemoveNodes.name = 'RemoveNodes';
RemoveNodes.each = RemoveNode;
RegisterExportsOnRoot = clone$(BaseNode);
RegisterExportsOnRoot.name = 'RegisterExportsOnRoot';
RegisterExportsOnRoot.exec = function(astRoot){
  var exports;
  exports = OnlyExports.exec(astRoot);
  astRoot.exports = exports;
};
ExtractExportNameFromAssign = clone$(BaseNode);
ExtractExportNameFromAssign.name = 'ExtractExportNameFromAssign';
ExtractExportNameFromAssign.ast = {};
ExtractExportNameFromAssign[copy] = function(){
  return clone$(this);
};
ExtractExportNameFromAssign.match = function(it){
  var assign;
  if ((assign = it.local)[type] === 'Assign' && it.alias == null) {
    return {
      node: it,
      assign: assign
    };
  }
};
ExtractExportNameFromAssign.map = function(arg$){
  var node, assign, x$;
  node = arg$.node, assign = arg$.assign;
  x$ = node.alias = Identifier[create]({
    name: assign.left.value,
    exported: true
  });
  copySourceLocation(assign.left, x$);
  return x$;
};
ExtractExportNameFromAssign.exec = function(it){
  var exports, i$, len$, e, matched;
  exports = OnlyExports.exec(it);
  for (i$ = 0, len$ = exports.length; i$ < len$; ++i$) {
    e = exports[i$];
    if (matched = this.match(e)) {
      this.map(matched);
    }
  }
  return it;
};
ExtractExportNameFromLiteral = clone$(BaseNode);
ExtractExportNameFromLiteral.name = 'ExtractExportNameFromLiteral';
ExtractExportNameFromLiteral.ast = {};
ExtractExportNameFromLiteral[copy] = function(){
  return clone$(this);
};
ExtractExportNameFromLiteral.match = function(it){
  var assign;
  if ((assign = it.local)[type] === 'Literal' && it.alias == null) {
    return {
      node: it,
      name: literalToString(it.local)
    };
  }
};
ExtractExportNameFromLiteral.map = function(arg$){
  var node, name, x$;
  node = arg$.node, name = arg$.name;
  x$ = node.alias = Identifier[create]({
    name: name
  });
  copySourceLocation(node.local, x$);
  return x$;
};
ExtractExportNameFromLiteral.exec = function(it){
  var exports, i$, len$, e, matched;
  exports = OnlyExports.exec(it);
  for (i$ = 0, len$ = exports.length; i$ < len$; ++i$) {
    e = exports[i$];
    if (matched = this.match(e)) {
      this.map(matched);
    }
  }
  return it;
};
ExtractNameFromClass = MatchMap[copy]();
ExtractNameFromClass.name = 'ExtractNameFromClass';
ExtractNameFromClass.ast = {};
ExtractNameFromClass[copy] = function(){
  return clone$(this);
};
ExtractNameFromClass.match = function(it){
  var _class;
  if ((_class = it.local)[type] === 'Class' && it.alias == null) {
    return {
      node: it,
      name: _class.title.value
    };
  }
};
ExtractNameFromClass.map = function(arg$){
  var node, name, x$, y$;
  node = arg$.node, name = arg$.name;
  x$ = node;
  y$ = x$.alias = Identifier[create]({
    name: name
  });
  copySourceLocation(node.local, y$);
  return x$;
};
ExtractExportNameFromImport = clone$(MatchMap);
ExtractExportNameFromImport.name = 'ExtractExportNameFromImport';
ExtractExportNameFromImport.ast = {};
ExtractExportNameFromImport.match = function(it){
  var _import, ref$, ref1$, name, that;
  if ((_import = it.local)[type] === Import[type] && ((ref$ = (ref1$ = _import.names) != null ? ref1$[type] : void 8) === 'Literal' || ref$ === 'Identifier' || ref$ === Literal[type]) && it.alias == null) {
    name = (that = _import.names.value)
      ? that
      : _import.names.name;
    return {
      name: name,
      _import: _import
    };
  }
};
ExtractExportNameFromImport.map = function(arg$){
  var _import, name, x$, tmp, y$, exportId, _export;
  _import = arg$._import, name = arg$.name;
  x$ = tmp = TemporarVariable[create]({
    name: 'import',
    isImport: true
  });
  copySourceLocation(_import, x$);
  _import.names = tmp;
  y$ = exportId = Identifier[create]({
    name: name
  });
  copySourceLocation(_import.names, y$);
  _export = this.ast.Export[create]({
    local: tmp,
    alias: exportId
  });
  return [_import, _export];
};
MoveExportsToTop = clone$(BaseNode);
MoveExportsToTop.name = 'MoveExportsToTop';
MoveExportsToTop.exec = function(astRoot){
  var exports;
  exports = OnlyExports.exec(astRoot);
  RemoveNodes.exec(exports);
  astRoot.exports = exports;
  astRoot.isModule = astRoot.isModule || astRoot.exports.length !== 0;
};
isExpression = function(it){
  var node, result, parentNode;
  node = it;
  result = false;
  while ((parentNode = node[parent]) && !result) {
    result = in$(parentNode[type], ['Arr']) || (parentNode[type] === 'Assign' && parentNode.right === node);
    node = parentNode;
  }
  return result;
};
ReplaceImportWithTemporarVariable = (ref$ = clone$(BaseNode), ref$.name = 'ReplaceImportWithTemporarVariable', ref$.exec = function(_import){
  var x$, names;
  x$ = names = TemporarVariable[create]({
    name: 'import',
    isImport: true
  });
  copySourceLocation(_import, x$);
  _import.replaceWith(names);
  return _import.names = names;
}, ref$);
RemoveOrReplaceImport = IfNode[copy]();
RemoveOrReplaceImport.name = 'RemoveOrReplaceImport';
RemoveOrReplaceImport.test = isExpression;
RemoveOrReplaceImport.then = ReplaceImportWithTemporarVariable;
RemoveOrReplaceImport['else'] = RemoveNode;
y$ = RemoveOrReplaceImports = clone$(ProcessArray);
y$.name = 'RemoveOrReplaceImports';
y$.each = RemoveOrReplaceImport;
identifierFromVar = JsNode['new'](function(someVar){
  var x$;
  x$ = Identifier[create]({
    name: someVar.value
  });
  copySourceLocation(someVar, x$);
  return x$;
});
ReplaceVariableWithIdentifier = ConditionalMutate.copy();
ReplaceVariableWithIdentifier.name = 'ReplaceVariableWithIdentifier';
ReplaceVariableWithIdentifier.test = function(context, node, parent, name, index){
  return node[type] === 'Assign' && node.left[type] === 'Var' && context.exportsNames.has(node.left.value);
};
ReplaceVariableWithIdentifier.mutate = function(context, node, parent, name, index){
  var identifier;
  identifier = identifierFromVar.exec(node.left);
  node.left.replaceWith(identifier);
};
DisableImplicitExportVariableDeclaration = (ref$ = {
  name: 'DisableImplicitExportVariableDeclaration',
  copy: function(){
    return clone$(this);
  }
}, ref$[copy] = function(){
  return clone$(this);
}, ref$.replacer = ReplaceVariableWithIdentifier, ref$.call = function(thisArg){
  var args, res$, i$, to$;
  res$ = [];
  for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
    res$.push(arguments[i$]);
  }
  args = res$;
  return this.exec.apply(this, args);
}, ref$.exec = function(astRoot){
  var context, exportsNames, i$, ref$, len$, e, ref1$, walk, crossScopeBoundary, this$ = this;
  context = {};
  context.exportsNames = exportsNames = new Set;
  for (i$ = 0, len$ = (ref$ = astRoot.exports).length; i$ < len$; ++i$) {
    e = ref$[i$];
    if ((ref1$ = e.local) != null && ref1$.value) {
      exportsNames.add(e.local.value);
    }
  }
  walk = function(node, parent, name, index){
    this$.replacer.exec(context, node, parent, name, index);
  };
  crossScopeBoundary = false;
  astRoot.traverseChildren(walk, crossScopeBoundary);
}, ref$);
sn = function(node){
  var parts, res$, i$, to$, result, e;
  node == null && (node = {});
  res$ = [];
  for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
    res$.push(arguments[i$]);
  }
  parts = res$;
  try {
    result = new SourceNode(node.line, node.column, null, parts);
    result.displayName = node[type];
    return result;
  } catch (e$) {
    e = e$;
    console.dir(parts);
    throw e;
  }
};
z$ = AddExportsDeclarations = JsNode.copy();
z$.name = 'AddExportsDeclarations';
z$.jsFunction = function(result){
  var exports, getVariableName, variablesToDeclare, exportsDeclaration, this$ = this;
  exports = this.exports.map(function(it){
    return sn(it, it.compile({
      scope: this$.scope
    }), '\n');
  });
  getVariableName = function(it){
    return it.local.compile({});
  };
  variablesToDeclare = this.exports.filter(function(it){
    return !it.local.isImport;
  }).map(function(it){
    return it.local;
  });
  exportsDeclaration = variablesToDeclare.length ? "var " + variablesToDeclare.map(function(it){
    return it.compile({});
  }).join(',') + ";\n" : "";
  return sn.apply(null, [this, exportsDeclaration].concat(arrayFrom$(exports), arrayFrom$(result.children)));
};
CheckIfOnlyDefaultExports = clone$(BaseNode);
CheckIfOnlyDefaultExports.name = 'CheckIfOnlyDefaultExports';
CheckIfOnlyDefaultExports.exec = function(astRoot){
  var onlyDefaults, i$, ref$, len$, e;
  onlyDefaults = true;
  for (i$ = 0, len$ = (ref$ = astRoot.exports).length; i$ < len$; ++i$) {
    e = ref$[i$];
    onlyDefaults = onlyDefaults && e['default'];
  }
  if (onlyDefaults) {
    for (i$ = 0, len$ = (ref$ = astRoot.exports).length; i$ < len$; ++i$) {
      e = ref$[i$];
      e.overrideModule = true;
    }
  }
};
MarkAsScript = JsNode.copy();
MarkAsScript.name = 'MarkAsScript';
MarkAsScript.jsFunction = function(astRoot){
  Object.defineProperty(astRoot, 'isModule', {
    configurable: true,
    enumerable: true,
    get: function(){
      return false;
    },
    set: function(){}
  });
};
z1$ = AddImportsDeclarations = JsNode.copy();
z1$.name = 'AddImportsDeclarations';
z1$.jsFunction = function(result){
  var imports, i$, ref$, len$, imp;
  imports = [];
  for (i$ = 0, len$ = (ref$ = this.imports).length; i$ < len$; ++i$) {
    imp = ref$[i$];
    imports.push(imp.compile({}), '\n');
  }
  return sn.apply(null, [this].concat(arrayFrom$(imports), arrayFrom$(result.children)));
};
module.exports = TransformESM = clone$(Plugin);
Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
TransformESM.name = 'transform-esm';
TransformESM.config = {};
TransformESM.enable = function(){
  var x$, specialLex, Nodelivescript, MyExport, y$, EnableExports, ExportNodes, z$, ref$, z1$, z2$, z3$, z4$, z5$;
  x$ = specialLex = JsNode[copy]();
  x$.jsFunction = function(lexed){
    var result, i, buffer, l, rest, ref$;
    result = [];
    i = -1;
    buffer = [lexed[0], lexed[1]];
    while (++i < lexed.length) {
      l = lexed[i];
      rest = slice$.call(l, 2);
      if (l[0] === 'DECL' && l[1] === 'export') {
        result.push(['ID', '__es-export__'].concat(arrayFrom$(rest)));
        if (i + 2 < lexed.length && lexed[i + 2][0] === 'DEFAULT') {
          result.push(lexed[++i]);
          ++i;
          ref$ = l = lexed[i], rest = slice$.call(ref$, 2);
          result.push(['ID', '__es-export-default__'].concat(arrayFrom$(rest)));
        }
      } else {
        result.push(l);
      }
    }
    return result;
  };
  this.livescript.lexer.tokenize.append(specialLex);
  Nodelivescript = this.livescript;
  MyExport = Export[copy]();
  this.livescript.ast.Export = MyExport;
  this.livescript.ast.ReExport = ReExport[copy]();
  assert(MyExport[type]);
  assert.equal(MyExport[type], Export[type]);
  y$ = EnableExports = ConditionalNode[copy]();
  y$.condition = JsNode['new'](function(it){
    return it[type] === Export[type];
  });
  y$.next = ExportNodes = MatchMapCascadeNode[copy]();
  z$ = ExportNodes;
  z$.append(ExtractNameFromClass);
  z$.append((ref$ = clone$(ExpandArrayExports), ref$.ast = this.livescript.ast, ref$));
  z$.append((ref$ = clone$(ExpandBlockExports), ref$.ast = this.livescript.ast, ref$));
  z$.append((ref$ = clone$(EnableDefaultExports), ref$.ast = this.livescript.ast, ref$));
  z$.append((ref$ = clone$(ExpandObjectExports), ref$.ast = this.livescript.ast, ref$));
  z$.append((ref$ = clone$(ExpandObjectPatternExports), ref$.ast = this.livescript.ast, ref$));
  z$.append((ref$ = clone$(ExtractExportNameFromImport), ref$.ast = this.livescript.ast, ref$));
  z1$ = this.livescript.expand;
  z1$.append((ref$ = clone$(InsertExportNodes), ref$.ast = this.livescript.ast, ref$));
  z1$.append(EnableExports);
  z2$ = this.livescript.postprocessAst;
  z2$.append(RegisterExportsOnRoot);
  if (this.config.format !== 'cjs') {
    z3$ = ExportNodes;
    z3$.append((ref$ = clone$(WrapLiteralExports), ref$.ast = this.livescript.ast, ref$));
    z3$.append((ref$ = clone$(WrapAnonymousFunctionExports), ref$.ast = this.livescript.ast, ref$));
    z3$.append((ref$ = clone$(SplitAssignExports), ref$.ast = this.livescript.ast, ref$));
    z3$.append((ref$ = clone$(ExpandCascadeExports), ref$.ast = this.livescript.ast, ref$));
    z4$ = this.livescript.postprocessAst;
    z4$.append(MoveExportsToTop);
    z4$.append(DisableImplicitExportVariableDeclaration);
    this.livescript.ast.Block.Compile.append(AddExportsDeclarations);
  } else {
    z5$ = this.livescript.postprocessAst;
    z5$.append(ExtractExportNameFromAssign);
    z5$.append(ExtractExportNameFromLiteral);
    z5$.append(CheckIfOnlyDefaultExports);
    z5$.append(MarkAsScript);
    MyExport.compile[asNode].jsFunction = function(o){
      var name, inner, wrapDefault, property, namedDefaultExport;
      name = this.name.compile(o);
      inner = this.local.compile(o);
      wrapDefault = function(it){
        if (it === "'default'") {
          return "Symbol.for('default.module')";
        } else {
          return it;
        }
      };
      property = this['default']
        ? "['__default__']"
        : this.name.reserved
          ? ['[', this.name.compile(o), ']']
          : ['.', name];
      if (this.overrideModule) {
        namedDefaultExport = this.local[type] === 'Literal'
          ? []
          : [this.local.terminator, "\n", o.indent, "Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports})"];
        return this.toSourceNode({
          parts: ["module.exports = ", inner].concat(arrayFrom$(namedDefaultExport))
        });
      } else {
        return this.toSourceNode({
          parts: ["exports"].concat(arrayFrom$(property), [" = ", inner])
        });
      }
    };
  }
  this.livescript.ast.Block.Compile.append(AddImportsDeclarations);
  importPlugin.install(this.livescript, this.config);
  dynamicImportPlugin.install(this.livescript, this.config);
};
function clone$(it){
  function fun(){} fun.prototype = it;
  return new fun;
}
function in$(x, xs){
  var i = -1, l = xs.length >>> 0;
  while (++i < l) if (x === xs[i]) return true;
  return false;
}
//# sourceMappingURL=plugin.js.map
