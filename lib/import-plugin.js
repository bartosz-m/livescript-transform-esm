var assert = (require('assert')['__default__'] || require('assert'));
var path = (require('path')['__default__'] || require('path'));
var fs = (require('fs')['__default__'] || require('fs'));
var globby = (require('globby')['__default__'] || require('globby'));
var Plugin = (require('livescript-compiler/lib/livescript/Plugin')['__default__'] || require('livescript-compiler/lib/livescript/Plugin'));
var { parent, type } = require('livescript-compiler/lib/livescript/ast/symbols');
var Pattern = (require('livescript-compiler/lib/livescript/ast/Pattern')['__default__'] || require('livescript-compiler/lib/livescript/ast/Pattern'));
var ObjectPattern = (require('livescript-compiler/lib/livescript/ast/ObjectPattern')['__default__'] || require('livescript-compiler/lib/livescript/ast/ObjectPattern'));
var Literal = (require('livescript-compiler/lib/livescript/ast/Literal')['__default__'] || require('livescript-compiler/lib/livescript/ast/Literal'));
var Assign = (require('livescript-compiler/lib/livescript/ast/Assign')['__default__'] || require('livescript-compiler/lib/livescript/ast/Assign'));
var Identifier = (require('livescript-compiler/lib/livescript/ast/Identifier')['__default__'] || require('livescript-compiler/lib/livescript/ast/Identifier'));
var TemporarVariable = (require('livescript-compiler/lib/livescript/ast/TemporarVariable')['__default__'] || require('livescript-compiler/lib/livescript/ast/TemporarVariable'));
var { ConditionalNode, JsNode, TrueNode, IfNode, identity, MatchMapCascadeNode } = require('js-nodes');
var { copy, asNode } = require('js-nodes/symbols');
var Copiable = (require('js-nodes/components/Copiable')['__default__'] || require('js-nodes/components/Copiable'));
var { create } = require('livescript-compiler/lib/core/symbols');
var Import = (require('./livescript/ast/Import')['__default__'] || require('./livescript/ast/Import'));
var Export = (require('./livescript/ast/Export')['__default__'] || require('./livescript/ast/Export'));
var MatchMap = (require('./nodes/MatchMap')['__default__'] || require('./nodes/MatchMap'));
var { copySourceLocation } = require('./utils');
var literalToString, debug, isExpression, extractNameFromSource, ConvertImports, InsertImportNodes, InsertImportBlock, ExtractImportFromAssign, InsertImportAllNodes, InsertScopeImports, sourceToName, ExtractNamesFromSource, identifierFromLiteral, ExpandObjectImports, ConvertImportsObjectNamesToPatterns, ArrayExpander, ExpandArrayImports, ExpandGlobImport, ExpandGlobImportAsObject, ExpandMetaImport, ExportResolver, removeNode, x$, RemoveNode, FilterAst, OnlyImports, ProcessArray, ReplaceImportWithTemporarVariable, ref$, RemoveOrReplaceImport, y$, RemoveOrReplaceImports, MoveImportsToTop, z$, EnableImports, slice$ = [].slice, this$ = this, arrayFrom$ = Array.from || function(x){return slice$.call(x);};
literalToString = function(it){
  return it.value.substring(1, it.value.length - 1);
};
debug = {
  log: function(){}
};
isExpression = function(it){
  var node, result, parentNode, ref$;
  node = it;
  result = false;
  while ((parentNode = node[parent]) && !result) {
    result = ((ref$ = parentNode[type]) === 'Arr' || ref$ === Export[type]) || parentNode.right === node;
    node = parentNode;
  }
  return result;
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
ConvertImports = clone$(MatchMap);
ConvertImports.name = 'ConvertImports';
ConvertImports.Import = Import;
ConvertImports.match = function(it){
  if (it[type] === 'Import' && it.left.value === 'this') {
    return {
      source: it.right,
      all: it.all
    };
  }
};
ConvertImports.map = function(arg$){
  var all, source;
  all = arg$.all, source = arg$.source;
  debug.log(this.name);
  return this.Import[create]({
    all: all,
    source: source
  });
};
InsertImportNodes = clone$(MatchMap);
InsertImportNodes.name = 'InsertImportNodes';
InsertImportNodes.ast = {};
InsertImportNodes.match = function(chain){
  if (chain[type] === 'Chain' && chain.head.value === '__static-import__') {
    return {
      args: chain.tails[0].args,
      chain: chain
    };
  }
};
InsertImportNodes.map = function(arg$){
  var chain, args, items, this$ = this;
  chain = arg$.chain, args = arg$.args;
  debug.log(this.name);
  if (args.length === 0) {
    throw Error("Empty import at " + chain.line + ":" + chain.column);
  }
  if (args.length > 0) {
    if (args[0][type] === 'Splat') {
      items = slice$.call(args, 1);
      return items.map(function(it){
        var x$;
        x$ = this$.ast.EsImport[create]({
          source: it,
          all: true
        });
        copySourceLocation(it, x$);
        return x$;
      });
    } else {
      return args.map(function(it){
        var x$;
        x$ = this$.ast.EsImport[create]({
          source: it
        });
        copySourceLocation(it, x$);
        return x$;
      });
    }
  } else {
    return this.ast.EsImport[create]({
      source: args[0]
    });
  }
};
InsertImportBlock = clone$(MatchMap);
InsertImportBlock.name = 'InsertImportBlock';
InsertImportBlock.ast = {};
InsertImportBlock.match = function(chain){
  if (chain[type] === 'Chain' && chain.head.value === '__static-import__') {
    return {
      args: chain.tails[0].args,
      chain: chain
    };
  }
};
InsertImportBlock.map = function(arg$){
  var chain, args, items, this$ = this;
  chain = arg$.chain, args = arg$.args;
  debug.log(this.name);
  debug.log(chain[parent]);
  if (args.length === 0) {
    throw Error("Empty import at " + chain.line + ":" + chain.column);
  }
  if (args.length > 0 && args[0][type] === 'Splat') {
    items = slice$.call(args, 1);
    return items.map(function(it){
      var x$;
      x$ = this$.ast.EsImport[create]({
        source: it,
        all: true
      });
      copySourceLocation(it, x$);
      return x$;
    });
  } else {
    return this.ast.EsImport[create]({
      source: args[0]
    });
  }
};
ExtractImportFromAssign = clone$(MatchMap);
ExtractImportFromAssign.name = 'ExtractImportFromAssign';
ExtractImportFromAssign.ast = {};
ExtractImportFromAssign.match = function(node){
  var assign;
  if (node[type] === 'Cascade' && (assign = node.input)[type] === 'Assign' && assign.right.value === '__static-import__') {
    return {
      lines: node.output.lines,
      assign: assign,
      cascade: node
    };
  }
};
ExtractImportFromAssign.map = function(arg$){
  var assign, lines, cascade, x$, esImport, nAssign;
  assign = arg$.assign, lines = arg$.lines, cascade = arg$.cascade;
  debug.log(this.name);
  if (lines.length === 0) {
    throw Error("Empty import at " + cascade.line + ":" + cascade.column);
  }
  if (lines.length !== 1) {
    throw Error("Expected import specifier on the same line " + cascade.line + ":" + cascade.column);
  }
  x$ = esImport = this.ast.EsImport[create]({
    source: lines[0]
  });
  x$[parent] = assign;
  x$.filename = cascade.filename;
  x$.line = x$.first_line = assign.last_line;
  x$.column = x$.first_column = assign.last_column + 1;
  x$.last_line = lines[0].last_line;
  x$.last_column = lines[0].last_column;
  cascade.output = {};
  cascade.input = {};
  return nAssign = Assign[create]({
    left: assign.left,
    right: esImport
  });
};
InsertImportAllNodes = clone$(MatchMap);
InsertImportAllNodes.name = 'InsertImportAllNodes';
InsertImportAllNodes.ast = {};
InsertImportAllNodes.match = function(node){
  if (node[type] === 'Cascade' && node.input.value === '__static-import-all__') {
    return node;
  }
};
InsertImportAllNodes.map = function(cascade){
  var lines, this$ = this;
  debug.log(this.name);
  lines = cascade.output.lines;
  if (lines.length === 0) {
    throw Error("Empty import at " + cascade.line + ":" + cascade.column);
  }
  return lines.map(function(it){
    return this$.ast.EsImport[create]({
      source: it,
      all: 'all'
    });
  });
};
InsertScopeImports = clone$(MatchMap);
InsertScopeImports.name = 'InsertScopeImports';
InsertScopeImports.ast = {};
InsertScopeImports.match = function(node){
  if (node[type] === 'Cascade' && node.input.value === '__import-to-scope__') {
    return node;
  }
};
InsertScopeImports.map = function(cascade){
  var lines, this$ = this;
  debug.log(this.name);
  lines = cascade.output.lines;
  if (lines.length === 0) {
    throw Error("Empty import at " + cascade.line + ":" + cascade.column);
  }
  return lines.map(function(it){
    return this$.ast.EsImport[create]({
      source: it,
      all: 'all'
    });
  });
};
sourceToName = function(literal){
  var this$ = this;
  return function(it){
    return path.basename(it, path.extname(it));
  }(
  function(it){
    return it.replace(/\'/gi, '');
  }(
  literal.value));
};
ExtractNamesFromSource = clone$(MatchMap);
ExtractNamesFromSource.name = 'ExtractNamesFromSource';
ExtractNamesFromSource.match = function(it){
  var value;
  if (!it.names && (value = it.source.value)) {
    return {
      node: it,
      names: sourceToName(it.source)
    };
  }
};
ExtractNamesFromSource.map = function(arg$){
  var node, names, x$;
  node = arg$.node, names = arg$.names;
  debug.log(this.name);
  x$ = node.names = Identifier[create]({
    name: names
  });
  copySourceLocation(node.source, x$);
  return node;
};
identifierFromLiteral = function(literal){
  var x$;
  x$ = Identifier[create]({
    name: literalToString(literal)
  });
  copySourceLocation(literal, x$);
  return x$;
};
ExpandObjectImports = clone$(MatchMap);
ExpandObjectImports.name = 'ExpandObjectImports';
ExpandObjectImports.Import = Import;
ExpandObjectImports.match = function(it){
  var ref$;
  if (((ref$ = it.source) != null ? ref$[type] : void 8) === 'Obj') {
    return it.source.items;
  }
};
ExpandObjectImports.map = function(items){
  var this$ = this;
  debug.log(this.name);
  return items.map(function(it){
    var result, ref$, x$;
    result = this$.Import[create](it.key
      ? {
        names: it.val,
        source: (ref$ = it.key) != null
          ? ref$
          : identifierFromLiteral(it.val),
        all: it.val.value === '__import-to-scope__'
      }
      : {
        names: identifierFromLiteral(it.val),
        source: it.val
      });
    x$ = result;
    copySourceLocation(it, x$);
    return x$;
  });
};
ConvertImportsObjectNamesToPatterns = clone$(MatchMap);
ConvertImportsObjectNamesToPatterns.name = 'ConvertImportsObjectNamesToPatterns';
ConvertImportsObjectNamesToPatterns.match = function(it){
  var ref$;
  if (((ref$ = it.names) != null ? ref$[type] : void 8) === 'Obj') {
    return {
      items: it.names.items,
      node: it
    };
  }
};
ConvertImportsObjectNamesToPatterns.map = function(arg$){
  var node, items, x$;
  node = arg$.node, items = arg$.items;
  debug.log(this.name);
  x$ = node.names = Pattern[create]({
    items: items
  });
  copySourceLocation(node, x$);
  return node;
};
ArrayExpander = clone$(MatchMap);
ArrayExpander.name = 'ArrayExpander';
ArrayExpander.mapItem = function(it){
  return it;
};
ArrayExpander.map = function(items){
  return items.map(bind$(this, 'mapItem'));
};
ExpandArrayImports = clone$(ArrayExpander);
ExpandArrayImports.name = 'ExpandArrayImports';
ExpandArrayImports.Import = Import;
ExpandArrayImports.match = function(it){
  if (it.source[type] === 'Arr') {
    return it.source.items;
  }
};
ExpandArrayImports.mapItem = function(it){
  var x$, id, y$;
  debug.log(this.name);
  x$ = id = Identifier[create]({
    imported: true,
    name: extractNameFromSource(it.value)
  });
  copySourceLocation(it, x$);
  y$ = this.Import[create]({
    names: id,
    source: it
  });
  copySourceLocation(it, y$);
  return y$;
};
ExpandGlobImport = clone$(MatchMap);
ExpandGlobImport.name = 'ExpandGlobImport';
ExpandGlobImport.Import = Import;
ExpandGlobImport.match = function(node){
  var literal, glob, modulePath, paths;
  if ((literal = node.source)[type] === 'Literal' && literal.value.match(/\*/) && !isExpression(node)) {
    glob = literalToString(literal);
    modulePath = path.dirname(node.filename);
    paths = globby.sync(glob, {
      cwd: modulePath
    }).map(function(it){
      var withoutExt;
      withoutExt = it.replace(path.extname(it), '');
      return './' + withoutExt;
    });
    return {
      paths: paths,
      literal: literal
    };
  }
};
ExpandGlobImport.map = function(arg$){
  var paths, literal, this$ = this;
  paths = arg$.paths, literal = arg$.literal;
  debug.log(this.name);
  return paths.map(function(it){
    var x$, source;
    x$ = source = Literal[create]({
      value: "'" + it + "'"
    });
    copySourceLocation(literal, x$);
    return this$.Import[create]({
      source: source
    });
  });
};
ExpandGlobImportAsObject = clone$(MatchMap);
ExpandGlobImportAsObject.name = 'ExpandGlobImportAsObject';
ExpandGlobImportAsObject.Import = Import;
ExpandGlobImportAsObject.match = function(node){
  var literal, glob, modulePath, paths;
  if ((literal = node.source)[type] === 'Literal' && literal.value.match(/\*/) && isExpression(node)) {
    glob = literalToString(literal);
    modulePath = path.dirname(node.filename);
    paths = globby.sync(glob, {
      cwd: modulePath
    }).map(function(it){
      var withoutExt;
      withoutExt = it.replace(path.extname(it), '');
      return './' + withoutExt;
    });
    return {
      paths: paths,
      literal: literal
    };
  }
};
ExpandGlobImportAsObject.map = function(arg$){
  var paths, literal, result, x$, this$ = this;
  paths = arg$.paths, literal = arg$.literal;
  debug.log(this.name);
  result = ObjectPattern[create]({
    items: paths.map(function(it){
      var x$, source;
      x$ = source = Literal[create]({
        value: "'" + it + "'"
      });
      copySourceLocation(literal, x$);
      return this$.Import[create]({
        source: source
      });
    })
  });
  x$ = result;
  copySourceLocation(literal, x$);
  return x$;
};
ExpandMetaImport = clone$(MatchMap);
ExpandMetaImport.name = 'ExpandMetaImport';
ExpandMetaImport.exportResolver = null;
ExpandMetaImport.match = function(node){
  if (node.all) {
    return node;
  }
};
ExpandMetaImport.map = function(node){
  var source, filename, moduleUrl, exports, items, x$, resolvedSource, y$, resolvedNames, e, m, error, ref$;
  source = node.source, filename = node.filename;
  try {
    if (!filename) {
      throw Error("Meta-import requires filename property on Import nodes");
    }
    moduleUrl = literalToString(source);
    exports = this.exportResolver.resolve(literalToString(source), filename);
    items = exports.map(function(it){
      var x$;
      x$ = Identifier[create]({
        name: it.name.value
      });
      copySourceLocation(source, x$);
      return x$;
    });
    x$ = resolvedSource = Literal[create]({
      value: "'" + moduleUrl + "'"
    });
    copySourceLocation(source, x$);
    y$ = resolvedNames = ObjectPattern[create]({
      items: items
    });
    copySourceLocation(source, y$);
    return this.Import[create]({
      names: resolvedNames,
      source: resolvedSource
    });
  } catch (e$) {
    e = e$;
    if (m = e.message.match(/ENOENT, no such file or directory '([^']+)'/)) {
      error = Error("Cannot extract exports of module " + node.source.value + " in " + node.filename + ":" + node.line + ":" + node.column + "\nNo such file " + m[1] + "\nProbably mispelled module path. " + e.message);
      error.hash = {
        loc: {
          first_line: (ref$ = node.first_line) != null
            ? ref$
            : node.line,
          first_column: (ref$ = node.first_column) != null
            ? ref$
            : node.column,
          last_line: (ref$ = node.last_line) != null
            ? ref$
            : node.line,
          last_column: (ref$ = node.last_column) != null
            ? ref$
            : node.column
        }
      };
      throw error;
    } else {
      throw e;
    }
  }
};
ExportResolver = {
  livescript: null,
  Import: Import,
  resolve: function(modulePath, currentPath){
    var cwd, resolvedPath, ext, code, astRoot, exports;
    modulePath = modulePath.replace(/^\w+\:\/{0,2}/, '');
    currentPath = currentPath.replace(/^\w+\:\/{0,2}/, '');
    cwd = path.dirname(currentPath);
    resolvedPath = path.resolve(cwd, modulePath);
    if (!(modulePath[0] === '.' || modulePath.match(/\.js$/))) {
      throw Error("Only local livescript files can be imported to scope");
    }
    ext = path.extname(path.basename(resolvedPath)).length ? '' : '.ls';
    code = fs.readFileSync(resolvedPath + ext, 'utf8');
    astRoot = this.livescript.generateAst(code, {
      filename: resolvedPath
    });
    return exports = astRoot.exports;
  }
};
removeNode = function(node){
  return node.remove();
};
x$ = RemoveNode = JsNode['new'](removeNode);
x$.name = 'RemoveNode';
FilterAst = clone$(null);
import$(FilterAst, Copiable);
FilterAst.nodesNames = ['test'];
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
  astRoot.traverseChildren(walk, true);
  return result;
};
OnlyImports = clone$(FilterAst);
OnlyImports.name = 'OnlyImports';
OnlyImports.test = function(it){
  return it[type] === Import[type];
};
ProcessArray = clone$(null);
import$(ProcessArray, Copiable);
ProcessArray.name = 'ProcessArray';
ProcessArray.nodeNames = ['each'];
ProcessArray.each = function(){};
ProcessArray.exec = function(it){
  var i$, len$, e, results$ = [];
  for (i$ = 0, len$ = it.length; i$ < len$; ++i$) {
    e = it[i$];
    results$.push(this.each.call(null, e));
  }
  return results$;
};
ReplaceImportWithTemporarVariable = (ref$ = {
  name: 'ReplaceImportWithTemporarVariable'
}, ref$[copy] = function(){
  return clone$(this);
}, ref$.exec = function(_import){
  var x$, names;
  x$ = names = TemporarVariable[create]({
    name: 'imports',
    isImport: true
  });
  copySourceLocation(_import, x$);
  _import.replaceWith(names);
  return _import.names = names;
}, ref$.call = function(arg$){
  var args, res$, i$, to$;
  res$ = [];
  for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
    res$.push(arguments[i$]);
  }
  args = res$;
  return this.exec.apply(this, args);
}, ref$.apply = function(arg$, args){
  return this.exec.apply(this, args);
}, ref$);
RemoveOrReplaceImport = IfNode[copy]();
RemoveOrReplaceImport.name = 'RemoveOrReplaceImport';
RemoveOrReplaceImport.test = isExpression;
RemoveOrReplaceImport.then = ReplaceImportWithTemporarVariable;
RemoveOrReplaceImport['else'] = RemoveNode;
y$ = RemoveOrReplaceImports = clone$(ProcessArray);
y$.name = 'RemoveOrReplaceImports';
y$.each = RemoveOrReplaceImport;
MoveImportsToTop = (ref$ = {
  name: 'MoveImportsToTop',
  copy: function(){
    return clone$(this);
  }
}, ref$[copy] = function(){
  return clone$(this);
}, ref$.call = function(thisArg){
  var args, res$, i$, to$;
  res$ = [];
  for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
    res$.push(arguments[i$]);
  }
  args = res$;
  return this.exec.apply(this, args);
}, ref$.exec = function(astRoot){
  var imports;
  imports = OnlyImports.exec(astRoot);
  astRoot.imports = imports;
  RemoveOrReplaceImports.exec(imports);
  astRoot.isModule = astRoot.isModule || astRoot.imports.length !== 0;
}, ref$);
module.exports = z$ = EnableImports = clone$(Plugin);
z$.name = 'EnableImports';
z$.config = {};
z$.enable = function(){
  var specialLex, specialLex2, EsImport, exportResolver, ref$, x$, ImportRules, y$, EnableImports, z$, z1$, simplifiedCompiler, this$ = this;
  specialLex = JsNode['new'](function(lexed){
    var result, i, buffer, last, inhibitDedent, l, rest, ref$;
    result = [];
    i = -1;
    buffer = [[], []];
    last = [[]];
    inhibitDedent = {
      line: null
    };
    while (++i < lexed.length) {
      l = lexed[i];
      if (l[0] === 'DEDENT' && l[1] === inhibitDedent.line) {
        rest = slice$.call(l, 2);
        result.push([')CALL', ''].concat(arrayFrom$(rest)));
        inhibitDedent.line = null;
      } else if (l[1] === 'import' && l[0] === 'DECL') {
        rest = slice$.call(l, 2);
        result.push(['ID', '__static-import__'].concat(arrayFrom$(rest)));
        i++;
        result.push(['CALL(', ''].concat(arrayFrom$(rest)));
        inhibitDedent.line = lexed[i][1];
      } else if (l[1] === 'importAll' && l[0] === 'DECL') {
        rest = slice$.call(l, 2);
        result.push(['ID', '__static-import-all__'].concat(arrayFrom$(rest)));
      } else if (l[0] === ":" && i + 1 < lexed.length && lexed[i + 1][0] === '...') {
        result.push(l);
        ++i;
        ref$ = l = lexed[i], rest = slice$.call(ref$, 2);
        result.push(['ID', '__import-to-scope__'].concat(arrayFrom$(rest)));
      } else {
        result.push(l);
      }
      last.pop();
      last.unshift(l);
    }
    return result;
  });
  specialLex2 = JsNode['new'](function(lexed){
    var result, i, buffer, last, l, ref$, rest;
    result = [];
    i = -1;
    buffer = [[], []];
    last = [[]];
    while (++i < lexed.length) {
      l = lexed[i];
      if (l[0] === ":" && i + 1 < lexed.length && lexed[i + 1][0] === '...') {
        result.push(l);
        ++i;
        ref$ = l = lexed[i], rest = slice$.call(ref$, 2);
        result.push(['ID', '__import-to-scope__'].concat(arrayFrom$(rest)));
      } else if (l[0] === ":" && i + 3 < lexed.length && lexed[i + 1][0] === '{' && lexed[i + 2][0] === '...' && lexed[i + 3][0] === '}') {
        result.push(l);
        ++i;
        ++i;
        ref$ = l = lexed[i], rest = slice$.call(ref$, 2);
        result.push(['ID', '__import-to-scope__'].concat(arrayFrom$(rest)));
        ++i;
      } else if (l[0] === 'ID' && l[1] === '__static-import__' && i + 3 < lexed.length && lexed[i + 1][0] === 'INDENT' && lexed[i + 2][0] === '...' && lexed[i + 3][0] === 'INDENT') {
        rest = slice$.call(l, 2);
        result.push(['NEWLINE', '\n'].concat(arrayFrom$(rest)));
        result.push(['ID', '__import-to-scope__'].concat(arrayFrom$(rest)));
        i++;
        i++;
        i++;
        result.push(lexed[i]);
        i++;
        result.push(lexed[i]);
        i++;
      } else {
        result.push(l);
      }
      last.pop();
      last.unshift(l);
    }
    return result;
  });
  this.livescript.lexer.tokenize.append(specialLex);
  this.livescript.lexer.tokenize.append(specialLex2);
  EsImport = Import[copy]();
  this.livescript.ast.EsImport = EsImport;
  exportResolver = (ref$ = clone$(ExportResolver), ref$.livescript = this.livescript, ref$.Import = EsImport, ref$);
  x$ = ImportRules = MatchMapCascadeNode[copy]();
  x$.name = 'Import';
  x$.append((ref$ = clone$(ExpandGlobImport), ref$.Import = EsImport, ref$));
  x$.append((ref$ = clone$(ExpandGlobImportAsObject), ref$.Import = EsImport, ref$));
  x$.append(ExtractNamesFromSource);
  x$.append((ref$ = clone$(ExpandObjectImports), ref$.Import = EsImport, ref$));
  x$.append(ConvertImportsObjectNamesToPatterns);
  x$.append((ref$ = clone$(ExpandArrayImports), ref$.Import = EsImport, ref$));
  x$.append((ref$ = clone$(ExpandMetaImport), ref$.Import = EsImport, ref$.exportResolver = exportResolver, ref$));
  y$ = EnableImports = ConditionalNode[copy]();
  y$.name = 'Imports';
  y$.condition = JsNode['new'](function(it){
    return it[type] === EsImport[type];
  });
  y$.next = ImportRules;
  z$ = this.livescript.expand;
  z$.append((ref$ = clone$(InsertImportNodes), ref$.ast = this.livescript.ast, ref$));
  z$.append((ref$ = clone$(InsertImportAllNodes), ref$.ast = this.livescript.ast, ref$));
  z$.append((ref$ = clone$(InsertScopeImports), ref$.ast = this.livescript.ast, ref$));
  z$.append((ref$ = clone$(ExtractImportFromAssign), ref$.ast = this.livescript.ast, ref$));
  z$.append(EnableImports);
  z1$ = simplifiedCompiler = this.livescript.copy();
  z1$.expand.rules.find(function(it){
    return it.name === 'Imports';
  }).next.remove(function(it){
    return it.name === 'ExpandMetaImport';
  });
  exportResolver.livescript = simplifiedCompiler;
  exportResolver.Import = EsImport;
  this.livescript.postprocessAst.append(MoveImportsToTop);
  if (this.config.format === 'cjs') {
    EsImport.compile[asNode].jsFunction = function(o){
      var names, required;
      names = this.names.compile(o);
      required = "require(" + this.source.compile(o) + ")";
      if (!this.names.items) {
        required = "(" + required + "['__default__'] || " + required + ")";
      }
      return this.toSourceNode({
        parts: ["var ", names, " = ", required, this.terminator]
      });
    };
  }
};
Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
function clone$(it){
  function fun(){} fun.prototype = it;
  return new fun;
}
function bind$(obj, key, target){
  return function(){ return (target || obj)[key].apply(obj, arguments) };
}
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}
//# sourceMappingURL=import-plugin.js.map
