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