require! {
    \./symbols : { copy, js, as-node }
    \./wrap
    \./AbstractNode
    \./JsNode
    \./StringNode
    \./ArrayNode
}

{ define-property, define-properties, get-own-property-descriptors } = Object

    
wrap = ->
    if \Function == type = typeof! it.value
        it.value = JsNode.new it.value .[js]
        it
    else if \String == type
        it.value = StringNode.new it.value .[js]
        it
    else if \Array == type
        it.value = ArrayNode.new it.value .[js]
        it
    else if it.get
        it
    else
        console.log it
        throw Error "Cannot convert #{type} to Node type"
    

ObjectNode = module.exports = ^^AbstractNode
ObjectNode <<<
    properties: ^^null
    import-enumerable: (...sources) ->
        target = @properties
        for source in sources
            descriptor = get-own-property-descriptors source
            keys = (Object.keys descriptor) ++ Object.get-own-property-symbols descriptor
            only-enumerable = { [k, wrap v] for k in keys when (v = descriptor[k]).enumerable }
            define-properties target, only-enumerable
        target
    
    set-properties: (properties) !->
        @properties = properties
            ..[as-node] = @
        Object.define-property @properties, copy, 
            enumerable: false
            value: -> @[as-node][copy]!properties
    (copy): ->
        result = ^^null
        keys = Object.keys @properties
        ^^@
            ..properties = ^^@properties
            for k in keys
                # console.log @name,k
                ..properties[k] = if \String == typeof! @properties[k]
                    then @properties[k]
                    else @properties[k][copy]!
            ..properties[as-node] = ..
            Object.define-property ..properties, copy, 
                enumerable: false
                value: ->
                    @[as-node][copy]!properties
