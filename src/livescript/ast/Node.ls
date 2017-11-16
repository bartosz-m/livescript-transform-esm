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
    
    children-names: []
    
    unfold-soak: ->
    
    unparen: -> @
    
    remove: ->
        unless @[parent]remove-child
            Type = @[parent][type]
            throw Error "You need to implement method #{Type}::remove-child youreself"
        @[parent]remove-child @
    
    rip-name: !-> @name = it
      
    rewrite-shorthand: (o, assign) !->
      
    each-child: (fn) !->
        for name in @children-names when child = @[name]
            fn child
      
    get-children: ->
        children = [] 
        @each-child !->
            children.push it
        children
      
    replace-child: ->
        if type = @[type]
            throw Error "You need to implement method #{type}::replace-child youreself"
        else
            throw Error "You need to implement method ::replace-child youreself"
    
    replace-with: (...nodes) ->
        unless @[parent]
            throw Error "#{@[type]} doesn't have parent"
        unless @[parent].replace-child
            throw Error "#{@[parent][type]} doesn't imlement replace-child method"
        for node in nodes
            node[parent] = @[parent]
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