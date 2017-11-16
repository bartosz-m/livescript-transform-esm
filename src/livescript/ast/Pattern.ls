require! {
    \./Node
    \./symbols : { parent, type }
}

Pattern = module.exports = ^^Node
Pattern <<<
    (type): \Pattern
    init: (@{items}) ->
      
    traverse-children: (visitor, cross-scope-boundary) ->
        for item,i in @items
            visitor item, @, \items, i
        for item in @items
            item.traverse-children visitor, cross-scope-boundary
    
    compile: (o) ->
        items = @items.map -> 
            if it.compile-node
                it.compile-node o
            else
                if it.key
                    "#{it.key.value} : #{it.val.value}"
                else
                    "#{it.val.value}"
        items = items.join ', '
        @to-source-node parts: [ "{ ", ...items, " }"]

    terminator: ''
