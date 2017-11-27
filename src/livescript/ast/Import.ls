require! {
    assert
    \./Node
    \../../nodes/JsNode
    \../../nodes/symbols : { copy, js, as-node }
    \../../nodes/ObjectNode
    \./symbols : { parent, type }
}

Import = Node[copy]!

Import[as-node]import-enumerable do
    (type): \Import.ast.livescript
    init: (@{names, source,all}) ->
    traverse-children: (visitor, cross-scope-boundary) ->
    compile: (o) ->
        names = @names.compile o
        @to-source-node parts: [ "import ", names, " from ", (@source.compile o), @terminator ]
    terminator: ';'


module.exports = Import
