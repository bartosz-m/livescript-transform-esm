require! {
    \./symbols : {copy, as-node, js}
    \./JsNode
}

StringNode = module.exports = ^^null
StringNode <<<
    is-constant: false
    name: \String
    (copy): ->
        result = StringNode with value: new String @value
        result[js] = result.value
        result.value[as-node] = result
        result.value[copy] = -> @[as-node][copy]![js]
        result
    value: ''
    new: ->
        result = StringNode[copy]!
            ..value = new String it
                result[js] = ..
                ..[copy] = -> @[as-node][copy]![js]
                ..[as-node] = result
