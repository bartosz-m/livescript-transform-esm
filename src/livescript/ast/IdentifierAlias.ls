import
    \assert
    \livescript-compiler/lib/livescript/ast/Node
    \js-nodes/JsNode
    \js-nodes/symbols : { copy, js, as-node }
    \js-nodes/ObjectNode
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/core/symbols : { init }

export default IdentifierAlias = Node[copy]!

IdentifierAlias[as-node]import-enumerable do
    (type): \IdentifierAlias.ast.livescript
    
    (init): (@{original,alias}) !->
      
    children-names: <[ original alias ]>
      
    alias:~
        -> @_alias
        (v) ->
            v?[parent] = @
            @_alias = v
    original:~
        -> @_original
        (v) ->
            v?[parent] = @
            @_original = v
    
    traverse-children: (visitor, cross-scope-boundary) !->
        for child-name in @children-names when child = @[child-name]
            visitor child, @, child-name
        for child-name in @children-names when (child = @[child-name])
            child.traverse-children ...&
    
    compile: (o) ->
        @to-source-node parts: [ (@original.compile o), ' as ', (@alias.compile o)]
            
    
    terminator: ''
