require! {
    \./symbols : { copy, js, as-node }
    \./wrap
    \./AbstractNode
    \./JsNode
    \./StringNode
    \./ArrayNode
}

{ define-property, define-properties, get-own-property-descriptor, get-own-property-descriptors } = Object

    
wrap = ->
    if \Function == type = typeof! it.value
        it.value = JsNode.new it.value .[js]
        it
    else if \String == type
        # it.value = StringNode.new it.value .[js]
        it
    else if \Array == type
        it.value = ArrayNode.new it.value .[js]
        it
    else if it.get
        it
    else
        console.log it
        throw Error "Cannot convert #{type} to Node type"


all-keys = (object) -> (Object.keys object) ++ Object.get-own-property-symbols object

get-enumerables-descriptor = (object) ->
    descriptor = get-own-property-descriptors object
    keys = all-keys descriptor
    { [k, v] for k in keys when (v = descriptor[k]).enumerable }

map-object = (fn, object) ->
    keys = all-keys object
    { [k, fn object[k]] for k in keys}

copy-property = (source, target, property) ->
    descriptor = get-own-property-descriptor source, property
    if descriptor.value?[copy]
        descriptor.value = descriptor.value[copy]!
    # else
    #     console.log \skipping property
    define-property target, property, descriptor

ObjectNode = module.exports = ^^AbstractNode
ObjectNode <<<
    properties: ^^null
    import-enumerable: (...sources) ->
        target = @properties
        for source in sources
            only-enumerable = map-object wrap, get-enumerables-descriptor source
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
                copy-property @properties, ..properties, k
            ..properties[as-node] = ..
            Object.define-property ..properties, copy, 
                enumerable: false
                value: ->
                    @[as-node][copy]!properties
