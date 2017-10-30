const empty-object = {}

NodePointer = Object.create null
    module.exports = ..
    ..init = (arg = empty-object) ->
        @parent = arg.parent ? null
        @node = arg.node ? null
        @name = arg.node ? null
        @index = arg.node ? null
        
    ..filter = (fn-filter) ->
        results = []
        pointer = NodePointer.create!
        walk-ast = (pointer.node, pointer.parent, pointer.name, pointer.index) !->
            if fn-filter pointer
                results.push pointer
                pointer := NodePointer.create!
        
        @node.traverse-children walk-ast, true
        results
    
    ..detach = !->
        unless @parent
            throw Error "Trying detach node without parent"
        if @index
          @parent[@name][@index]
        
    ..create = (arg) ->
        Object.create @
            ..init arg

    ..replace = (...nodes) ->
          new-pointer = NodePointer.create @
          if nodes.length == 0
              throw Error "Replacing without nodes"
          if nodes.length > 1 and @name != \lines
              throw Error "Don't know how to replace multiple #{@name}"
          # nodes can be added or remove so posiotion in parent can change any time
          index = @parent[@name].index-of @node
          @parent[@name].splice index, 1, ...nodes
