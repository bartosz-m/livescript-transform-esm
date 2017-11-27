require! {
    \./symbols : { copy }
}

MatchMapCascadeNode = module.exports = ^^null
MatchMapCascadeNode <<<
    name: \MatchMapCascadeNode
    rules: []
    append: (rule) !->
        unless rule[copy]
            throw Error "Creating node #{rule.name ? ''} without copy method is realy bad practice"
        unless rule.name
            throw new Error "Adding rule without a name is realy bad practice"
        @rules.push rule
    remove: (rule-or-filter) ->
        idx = if \Function == typeof! rule-or-filter
              then @rules.find-index rule-or-filter
              else @rules.index-of rule-or-filter
        if idx != -1
            rule = @rules[idx]
            @rules.splice idx, 1
            rule
        else
            throw Error "Cannot remove rule - there is none matching"
    match: ->
        for rule in @rules
            if m = rule.match it
                result =
                    rule: rule
                    matched: m
                break
        result
    
    map: ({rule,matched}) ->
        replacer = rule.map matched
        replacer
    
    exec: (value) ->
        if matched = @match value
            @map matched
    
    (copy): ->
        ^^@
            ..rules = @rules.map (.[copy]!)