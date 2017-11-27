require! {
    \../JsNode
    \../symbols : { copy }
}

wrap-or-copy = (maybe-copiable) ->
    if \Function == typeof! maybe-copiable
    then JsNode.new maybe-copiable
    else maybe-copiable[copy]!

maybe-wrap = (maybe-copiable) ->
    if \Function == typeof! maybe-copiable
    then JsNode.new maybe-copiable
    else maybe-copiable

Copiable = module.exports = ^^null
Copiable <<<
    nodes-names: <[]>
    
    init: (arg) ->
        @nodes-names = Array.from arg.nodes-names ? @nodes-names
        for name in @nodes-names
            @name = 
                if arg[name]
                then maybe-wrap arg[name]
                else wrap-or-copy @[name]
    
    (copy): ->
        ^^@
            ..init ..
