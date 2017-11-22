require! {
    \source-map : { SourceNode }
    \./Lexer
    \./ast/Node
    \./ast/symbols : {parent, type}
    \./JsNode
    \./ExpandNode
    \./SeriesNode
}

sn = (node = {}, ...parts) ->
    try
        result = new SourceNode node.line, node.column, null, parts
        result.display-name = node[type]
        result
    catch e
        console.dir parts
        throw e

AST = ^^null

original = Symbol \original

for type-name in <[ Arr Assign Binary Block Call Cascade Chain Class Fun Import Index Key Literal Obj Prop Util Var ]>
    AST[type-name] = 
        (type): type-name
        constructor:
            name: type-name
            display-name: type-name
        from-livescript-node: ->
            result = ^^it
                ..[original] = it
            for own k,v of @
                result[k] = v
            result[type] = @[type]
            result

super-compile = JsNode.copy!
    ..name = \SuperCompile
    ..js-function = ->
        @[original]compile-root ...

BlockCompile = SeriesNode.copy!
    ..name = \compile.Block
    ..append super-compile.copy!

AddExportsDeclarations = JsNode.copy!
    ..name = \AddExportsDeclarations
    ..js-function = (result) ->
        exports = @exports.map -> sn it, (it.compile {}), '\n'
        imports = @imports.map -> sn it, (it.compile {}), '\n'
        get-variable-name = -> it.local.compile {}
        exports-declaration = if exports.length
        then "var #{@exports.map get-variable-name .join ','};\n"
        else ""
        sn @, ...imports, exports-declaration, ...exports, result

BlockCompile.append AddExportsDeclarations

wrap-node = (mapper) ->
    wrapped = -> mapper ...
    wrapped.node = mapper
    for let own k,v of mapper
        unless wrapped[k]
            Object.define-property wrapped, k, 
                enumerable: true
                configurable: false
                get: -> @node[k]
                set: -> @node[k] = it
    wrapped


AST.Block
  ..xcompile = wrap-node BlockCompile
  ..compile-root = (o) ->
      
      result = @[original]compile-root ...
      exports = @exports.map -> sn it, (it.compile o), '\n'
      # imports = ast-root.imports.map -> sn it, (it.compile o), '\n'
      result
      # third-stage can access scope
      # 
      non-default-exports = @exports
      get-variable-name = -> it.local.compile {}
      exports-declaration = if exports.length
      then "var #{@exports.map get-variable-name .join ','};\n"
      else ""
      sn @, exports-declaration, ...exports, result
      # result
    
  ..replace-child = (child, ...nodes) ->
      idx = @lines.index-of child
      unless idx > -1
          throw Error "Trying to replace node witch is not child of current node"
      unless nodes.length
          throw Error "Replace called without nodes"
      @lines.splice idx, 1, ...nodes
      for node in nodes
          node[parent] = @
      child
  ..remove-child = (child) ->
      idx = @lines.index-of child
      unless idx > -1
          throw Error "Trying to replace node witch is not child of current node"
      @lines.splice idx, 1
      child

AST.Assign
    ..replace-child = (child, ...nodes) ->
        if nodes.length != 1 
            throw new Error "Cannot replace child of assign with #{nodes.length} nodes."
        [new-node] = nodes
        if @left == child
            @left = new-node
        else if @right == child
            @right = new-node
        else
          throw new Error "Node is not child of Assign"

for k, NodeType of AST
    for k,v of Node{get-children, replace-with}
        NodeType[k] ?= v

Compiler = ^^null
    module.exports = ..
Compiler <<<
    lexer: ^^null
    
    init: ({@livescript}) !->
        @lexer = Lexer.create {@livescript}
        @ast = AST
        @expand = ExpandNode.copy!
        @postprocess-ast = SeriesNode.copy!
            ..name = 'PostprocessAst'
        @postprocess-generated-code = SeriesNode.copy!
            ..name = 'PostprocessGeneratedCode'
    
    nodes-names: <[
        lexer expand postprocessAst postprocessGeneratedCode
    ]>
        
    create: ->
        ^^@
            ..init ...&
            
    copy: ->
        ^^@
            ..nodes-names = Array.from ..nodes-names
            for name in ..nodes-names
                ..[name] = ..[name].copy!
    
    convert-ast: (ast-root, options) ->
        map = new Map
        new-root = @ast.Block.from-livescript-node ast-root
        map.set ast-root, new-root
        walk = (node,parent-node,name,index) !~>
            if NodeType = @ast[node@@name]
                unless NodeType.from-livescript-node?
                    throw Error "#{NodeType[type]} doesn't have method from-livescript-node"
                new-node = NodeType.from-livescript-node node
                    ..filename = options.filename
                map.set node, new-node
                converted-parent = map.get parent-node
                unless converted-parent[name]
                    throw Error "Node doesn't have child #{name}"
                new-node[parent] = converted-parent
                if index?
                    converted-parent[name][index] = new-node
                else
                    converted-parent[name] = new-node
            else
                throw Error "Unimplemented #{node@@name}"
            
        ast-root.traverse-children walk, true
        new-root
    
    generate-ast: (code, options) ->
        @convert-ast (@livescript.ast @lexer.lex code), options
            .. <<< options{filename}
            @expand.process ..
            @postprocess-ast.process ..

    # livescript compatible signature
    compile: (code, options = {}) ->
        ast-root = @generate-ast code, options
        output = ast-root.xcompile options
        output.set-file options.filename
        @postprocess-generated-code.process output
        if options.map
            result = output.to-string-with-source-map!
                ..ast = ast-root
        else
            output.to-string!