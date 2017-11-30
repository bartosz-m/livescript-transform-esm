require! {
    \./symbols : {copy, js, as-node}
    \./JsNode
}

ArrayNode = module.exports = ^^null
ArrayNode <<<
    is-constant: false
    name: \Array
    (copy): ->
        result = ArrayNode with value: Array.from @value
        result[js] = result.value
        result.value[as-node] = result
        result.value[copy] = -> @[as-node][copy]![js]
        result
    value: ''
    new: ->
        result = ArrayNode[copy]!
            ..[js] = it
            ..value = it
                ..[as-node] = result
                ..[copy] = -> @[as-node][copy]![js]
      
        
    