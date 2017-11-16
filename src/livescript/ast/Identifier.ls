require! {
    \./Node
    \./symbols : { type }
}

Identifier = module.exports = ^^Node
Identifier <<<    
    (type): \Identifier
    
    init: (@{name}) !->
      
    traverse-children: (visitor, cross-scope-boundary) ->
    
    compile: (o) ->
        @to-source-node parts: [ @name ]
        
    value:~
        -> @name
        
    is-empty: -> false # assign is using this
    
    get-default: -> void # assign is using this
    
    is-assignable: -> true  # assign is using this
    
    var-name: -> @name  # assign is using this
    
    unwrap: -> @
    compile-node: ->
        @compile!