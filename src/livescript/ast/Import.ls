import
    \assert
    \livescript-compiler/lib/livescript/ast/Node
    \js-nodes/JsNode
    \js-nodes/symbols : { copy, js, as-node }
    \js-nodes/ObjectNode
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/core/symbols : { init }

export default Import = Node[copy]!

Import[as-node]import-enumerable do
    (type): \Import.ast.livescript
    
    (init): (@{names, source,all,inject-to-scope}) ->
      
    names:~
        -> @_names
        (v) ->
            v?[parent] = @
            @_names = v
    source:~
        -> @_source
        (v) ->
            v?[parent] = @
            @_source = v
    
    traverse-children: (visitor, cross-scope-boundary) !->
        visitor @names, @, \names  if @names
        visitor @source, @, \source if @source
        @names.traverse-children ...& if @names
        @source.traverse-children ...& if @source
    
    compile: (o) ->
        names = @names.compile o
        if @all
            @to-source-node parts: [ "import * as ", names, " from ", (@source.compile o), @terminator ]
        else
            @to-source-node parts: [ "import ", names, " from ", (@source.compile o), @terminator ]
            
    
    terminator: ';'
