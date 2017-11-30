import
    \assert
    \livescript-compiler/lib/livescript/ast/Node
    \livescript-compiler/lib/nodes/JsNode
    \livescript-compiler/lib/nodes/symbols : { copy, js, as-node }
    \livescript-compiler/lib/nodes/ObjectNode
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/core/symbols : { init }

export default DynamicImport = Node[copy]!

DynamicImport[as-node]import-enumerable do
    (type): \DynamicImport.ast.livescript
    
    (init): (@{sources}) ->
      
    children-names: <[ source ]>
    
    traverse-children: (visitor, cross-scope-boundary)->
        for child-name in @children-names when child = @[child-name]
            visitor child, @, child-name
        for child-name in @children-names when child = @[child-name]
            child.traverse-children ...
            
    compile: (o) ->
        sources = @sources.map (.compile o)
        @to-source-node parts: [ "import(", sources, ")" ]
    
    terminator: ';'
