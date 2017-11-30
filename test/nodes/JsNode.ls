require! {
    \./symbols : { copy, js, as-node }
    \./wrap
    \./AbstractNode
}

id = -> it

JsNode = module.exports = ^^AbstractNode
JsNode <<<
    name: \JsNode
    
    js-function: id
    
    to-js: -> wrap @
        
    this: null
    
    call: (this-arg, ...args) -> @js-function.apply this-arg, args
    
    apply: (this-arg, args) -> @js-function.apply this-arg, args
    
    exec: -> @js-function.apply @this, &
    
    (copy): ->
        ^^@
            ..[js] = wrap ..
    
    copy: ->
        ^^@
            ..[js] = ..[js][copy]!
    
    new: (js-function) ->
        @[copy]! <<< {js-function}
            ..js-function[as-node] = ..
    
JsNode[js] = wrap JsNode