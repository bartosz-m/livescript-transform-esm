JsNode = module.exports = ^^null
JsNode <<<
    name: \JsNode
    
    js-function: -> it
    
    apply: (this-arg, args) -> @js-function.apply this-arg, args
    
    process: (value) -> @js-function value
    
    copy: -> ^^@