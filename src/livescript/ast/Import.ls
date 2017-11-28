import
    \assert
    \livescript-compiler/lib/livescript/ast/Node
    \livescript-compiler/lib/nodes/JsNode
    \livescript-compiler/lib/nodes/symbols : { copy, js, as-node }
    \livescript-compiler/lib/nodes/ObjectNode
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/core/symbols : { init }

export default Import = Node[copy]!

Import[as-node]import-enumerable do
    (type): \Import.ast.livescript
    (init): (@{names, source,all}) ->
    traverse-children: (visitor, cross-scope-boundary) ->
    compile: (o) ->
        names = @names.compile o
        @to-source-node parts: [ "import ", names, " from ", (@source.compile o), @terminator ]
    terminator: ';'
