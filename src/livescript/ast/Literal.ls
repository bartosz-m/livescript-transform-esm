require! {
    \./Node
    \./symbols : { type }
}

Literal = module.exports = ^^Node
Literal <<<
    (type): \Literal
    
    init: (@{value}) !->
      
    traverse-children: (visitor, cross-scope-boundary) ->
    
    compile: (o) ->
        @to-source-node parts: [ @value ]