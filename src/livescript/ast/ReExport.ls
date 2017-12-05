import
    \livescript-compiler/lib/livescript/ast/Node
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \js-nodes/symbols : { copy, js, as-node }
    \js-nodes/ObjectNode
    \livescript-compiler/lib/core/symbols : {init}

export default ReExport = Node[copy]!
ReExport[as-node]name = \ReExport
ReExport[as-node]import-enumerable do
    (type): \ReExport.ast.livescript
    
    (init): (@{names, source}) ->
    
    children-names: <[ names source ]>
    
    traverse-children: (visitor, cross-scope-boundary) !->
        for child-name in @children-names when child = @[child-name]
            visitor child, @, child-name
        for child-name in @children-names when child = @[child-name]
            child.traverse-children ...&
    
    name:~
        -> @alias ? @local
        
    default:~
        -> @alias?name == \default
        
    compile: (o) ->
        
        @to-source-node parts: [ "export ",(@names.compile o), " from ", (@source.compile o) ]
        
    terminator: ';'
    
    names:~
        -> @_names
        (v) ->
            v[parent] = @
            @_names = v
    source:~
        -> @_source
        (v) ->
            v[parent] = @
            @_source = v
            
    replace-child: (child, node) ->
        for child-name in @children-names when @[child-name] == child
            @[child-name] = node
            node[parent] = @
            child[parent] = null
            return child
        throw Error "Node is not a child of ReExport"
    