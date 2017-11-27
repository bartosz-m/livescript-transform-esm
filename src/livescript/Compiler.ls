require! {
    \assert
    \./SourceNode
    \./Lexer
    \./ast/Node
    \./ast/symbols : {parent, type}
    \../nodes/ObjectNode
    \../nodes/JsNode
    \../nodes/SeriesNode
    \../nodes/symbols : node-symbols
    \./ExpandNode
}



copy = node-symbols.copy

js = node-symbols.js

AST = ObjectNode[copy]!properties

Prototype = Symbol \Prototype

super-compile = JsNode.copy!
    ..name = \SuperCompile
    ..js-function = ->
        @[Prototype]compile-root ...

BlockCompile = SeriesNode[copy]!
    ..name = \compile.Block
    ..append super-compile[copy]!

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

AST.Block = ObjectNode[copy]!properties
AST.Assign = ObjectNode[copy]!properties

assert AST.Block != AST.Block[copy]!
assert AST.Block != AST[copy]!Block

BlockReplaceChild = JsNode.new (child, ...nodes) ->
    idx = @lines.index-of child
    unless idx > -1
        throw Error "Trying to replace node witch is not child of current node"
    unless nodes.length
        throw Error "Replace called without nodes"
    @lines.splice idx, 1, ...nodes
    for node in nodes
        node[parent] = @
    child

BlockRemoveChild = JsNode.new (child) ->
    idx = @lines.index-of child
    unless idx > -1
        throw Error "Trying to replace node witch is not child of current node"
    @lines.splice idx, 1
    child


AST.Block
  ..Compile = BlockCompile
  ..replace-child = BlockReplaceChild[js]
  ..remove-child = BlockRemoveChild[js]

AssignReplaceChild = JsNode.new (child, ...nodes) ->
    if nodes.length != 1 
        throw new Error "Cannot replace child of assign with #{nodes.length} nodes."
    [new-node] = nodes
    if @left == child
        @left = new-node
    else if @right == child
        @right = new-node
    else
      throw new Error "Node is not child of Assign"

AssignReplaceChild
    ..name = \AssignReplaceChild

AST.Assign
    ..replace-child = AssignReplaceChild[js]

for k, NodeType of AST
    for k,v of Node{get-children, replace-with,to-source-node}
        NodeType[k] ?= JsNode.new v .[js]

Compiler = ^^ObjectNode
    module.exports = ..
Compiler <<<
    lexer: ^^null
    
    init: ({@livescript,lexer}) !->
        @livescript <<< {lexer} if lexer
        @lexer = Lexer.create {@livescript}
        @ast = AST[copy]!
        assert @ast.Block != AST.Block
        @expand = ExpandNode[copy]!
        @postprocess-ast = SeriesNode.copy!
            ..name = 'postprocessAst'
        @postprocess-generated-code = SeriesNode.copy!
            ..name = 'postprocessGeneratedCode'
    
    nodes-names: <[
        ast lexer expand postprocessAst postprocessGeneratedCode
    ]>
    
    install: (livescript = @livescript) !->
        @livescript.compile = @~compile
        
    create: ->
        ^^@
            ..init ...&
            
    copy: ->
        ^^@
            ..nodes-names = Array.from ..nodes-names
            for name in ..nodes-names
                unless ..[name][copy]
                    throw Error "Compiler.#{name} doesn't have copy method"
                ..[name] = ..[name][copy]!
    
    convert-ast: (ast-root, options) ->
        ast-root <<< @ast.Block
            ..[Prototype] = Object.get-prototype-of ..
            ..[type] = @ast.Block[type]
        walk = (node,parent-node,name,index) !~>
            node <<< NodeType
                ..[type] = node@@name
                ..[parent] = parent-node
                ..filename = options.filename
                ..[Prototype] = Object.get-prototype-of ..
                for k,v of Node{get-children, replace-with,to-source-node}
                    ..[Prototype][k] ?= v
            if NodeType = @ast[node@@name]
                node <<< NodeType
            
        ast-root.traverse-children walk, true
        ast-root
    
    generate-ast: (code, options) ->
        @convert-ast (@livescript.ast @lexer.lex.exec code), options
            .. <<< options{filename}
            @expand.exec ..
            @postprocess-ast.exec ..

    # livescript compatible signature
    compile: (code, options = {}) ->
        ast-root = @generate-ast code, options
        output = SourceNode.from-source-node ast-root.Compile.call ast-root, options
        output.set-file options.filename
        @postprocess-generated-code.exec output
        if map = options.map
            
            result = output.to-string-with-source-map!                
                ..ast = ast-root
                if map is 'embedded'
                    ..map.set-source-content options.filename, code
                    ..code += "\n//# sourceMappingURL=data:application/json;base64,#{ new Buffer ..map.to-string! .to-string 'base64' }\n"
            result
        else
            output.to-string!