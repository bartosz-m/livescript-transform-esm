require! {
    \source-map : { SourceNode }
    \../../components/core : { Creatable }
    \../../composition : { import-properties }
    
    \./symbols : { parent, type }
}

Node = module.exports = ^^null
    import-properties .., Creatable
Node <<<
    (Symbol.has-instance): -> Object.is-prototype-of ...
    (type): \Node
    is-statement: -> false
    
    terminator: '' # required by Block
    
    unfold-soak: ->
    
    unparen: -> @
    
    rip-name: !-> @name = it
      
    rewrite-shorthand: (o, assign) !->
      
    replace-child: ->
        throw Error "You need to implement method Node::replace-child youreself"
    
    replace-with: (...nodes) ->
        unless @[parent].replace-child
            console.log @[parent]
            throw Error "Node doesn't imlement replace-child method"
        @[parent].replace-child @, ...nodes
      
    compile: (options, level) ->
        o = {} <<< options
        o.level? = level
        node = @unfold-soak o or this
        # If a statement appears within an expression, wrap it in a closure.
        return node.compile-closure o if o.level and node.is-statement!
        code = (node <<< tab: o.indent).compile-node o
        if node.temps then for tmp in that then o.scope.free tmp
        code
        
    to-source-node: ({parts = []}) ->
        try
            result = new SourceNode @line, @column, null, parts
            result.display-name = @[type]
            result
        catch e
            console.dir parts
            throw e