require! {
    \./Node
    \./symbols : { parent, type }
}

ObjectPattern = module.exports = ^^Node
ObjectPattern <<<
    (type): \ObjectPattern
    init: (@{items}) ->
      
    traverse-children: (visitor, cross-scope-boundary) ->
        for item,i in @items
            visitor item, @, \items, i
        for item in @items
            item.traverse-children visitor, cross-scope-boundary
    
    compile: (o) ->
        items = []
        for i in @items
            items.push i.compile o
            items.push ', '
        items.pop!
        @to-source-node parts: [ "{ ", ...items, " }"]

    terminator: ''
