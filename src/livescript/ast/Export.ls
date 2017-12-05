import
    \assert
    \livescript-compiler/lib/livescript/ast/Node
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \js-nodes/symbols : { copy, js, as-node }
    \js-nodes/ObjectNode
    \livescript-compiler/lib/core/symbols : {init}

export default Export = Node[copy]!
Export[as-node]name = \Export
Export[as-node]import-enumerable do
    (type): \Export.ast.livescript
    
    (init): (@{local, alias}) ->
    
    children-names: <[ local alias ]>
    
    traverse-children: (visitor, cross-scope-boundary) !->
        for child-name in @children-names when child = @[child-name]
            visitor child, @, child-name
        for child-name in @children-names when (child = @[child-name])
            child.traverse-children ...&
    
    name:~
        -> @alias ? @local
        
    default:~
        -> @alias?name == \default
        
    compile: (o) ->
        alias =
            if @alias
                if  @alias.name != \default
                then [" as ", (@alias.compile o )]
                else [" as default" ]
            else []
        inner = (@local.compile o)
        
        @to-source-node parts: [ "export { ", inner, ...alias, " }" ]
        
    terminator: ';'
    
    local:~
        -> @_local
        (v) ->
            v[parent] = @
            @_local = v
    
    alias:~
        -> @_alias
        (v) ->
            v?[parent] = @
            @_alias = v
            
    replace-child: (child, node) ->
        for child-name in @children-names when @[child-name] == child
            @[child-name] = node
            node[parent] = @
            child[parent] = null
            return child
        throw Error "Node is not a child of Export"
    