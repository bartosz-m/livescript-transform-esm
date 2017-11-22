MatchMapCascadeNode = module.exports = ^^null
MatchMapCascadeNode <<<
    name: \MatchMapCascadeNode
    append: (rule) !->
        unless rule.copy
            throw Error "Creating node #{rule.name ? ''} without copy method is realy bad practice"
        unless rule.name
            throw new Error "Adding rule without a name is realy bad practice"
        @rules.push rule
    rules: []
    match: ->
        for rule in @rules
            if m = rule.match it
                result =
                    rule: rule
                    matched: m
                break
        result
    
    map: ({rule,matched}) ->
        replacer = rule.replace matched
        replacer
    
    process: (value) ->
        if matched = @match value
            @map matched
    
    copy: ->
        ^^@
            ..rules = @rules.map (.copy!)