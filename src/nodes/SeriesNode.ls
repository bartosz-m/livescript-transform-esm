require! {
    \./symbols : { copy }
}

SeriesNode = module.exports = ^^null
SeriesNode <<<
    name: \SeriesNode
    append: (node) ->
        unless node.copy
            throw Error "Creating node #{node.name ? ''} without copy method is realy bad practice"
        unless node.name
            throw new Error "Adding node without a name is realy bad practice"
        @nodes.push node
    nodes: []
    
    this: null    # usefull for methods soft bound this
    
    apply: (this-arg, args) ->
        current = args
        for node in @nodes
            if new-value = node.apply this-arg, current
                current = [new-value]
        current.0
    
    call: (this-arg, ...args) ->
        current = args
        for node in @nodes
            if new-value = node.apply this-arg, current
                current = [new-value]
        current.0
    
    exec: (value) ->
        current = value
        for node in @nodes
            if new-value = node.call @this, current
                current = new-value
        current
    
    copy: ->
        ^^@
            ..nodes = @nodes.map (.copy!)
    (copy): ->
        @nodes.for-each !->
            unless it[copy]
                throw Error "missing copy on  #{it.name}"
        ^^@
            ..nodes = @nodes.map (.[copy]!)