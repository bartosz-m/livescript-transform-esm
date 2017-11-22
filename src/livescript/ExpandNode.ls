as-array = ->
    if Array.is-array it
    then it
    else [it]

flatten = (arr) ->
    result = []
    arr.for-each ->
        if Array.is-array it
            result.push ...it
        else
            result.push it
    result

copy-source-location = (source, target) !->
    {line,column,filename} = source
    unless line?
        line = 10000000000
        column = 10000000000
        children = source.get-children!
        for child in children
            line = Math.min line, child.line if child.line
            column = Math.min column, child.column if child.column
    target <<< {line,column,filename}

ExpandNode = module.exports =  ^^null
ExpandNode <<<
    append: (rule) !->
        unless rule.copy
            throw Error "Creating node #{rule.name ? ''} without copy method is realy bad practice"
        unless rule.name
            throw new Error "Adding rule without a name is realy bad practice"
        @rules.push rule
        
    remove: (rule-or-filter) ->
        console.log @rules
        idx = if \Function == typeof! rule-or-filter
              then @rules.find-index rule-or-filter
              else @rules.index-of rule-or-filter
        if idx != -1
            rule = @rules[idx]
            @rules.splice idx, 1
            rule
        else
            throw Error "Cannot remove rule - there is none matching"
      
    rules: [
    ]
    process: (ast-root) !->
        changed = false
        to-process = [ast-root]
        while to-process.length
            changed = false
            processing = to-process
            to-process = []
            for node in processing
                for rule in @rules when mapped = rule.process node
                    try
                        new-nodes = as-array mapped
                        unless new-nodes.0
                            console.log rule
                        unless new-nodes.length == 1
                        and new-nodes.0 == node
                            for n in new-nodes
                                copy-source-location node, n
                            node.replace-with ...new-nodes
                        changed = true
                        break
                    catch
                        e.message = "During #{rule.name} #{e.message}"
                        throw e
            if changed
                to-process.push ast-root
            else
                to-process.push ...flatten processing.map ->
                    it.get-children!
    copy: ->
        ^^@
            ..rules = @rules.map (.copy!)