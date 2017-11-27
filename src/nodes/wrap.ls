require! {
    \./symbols : {copy, js, as-node}
}
module.exports = wrap-node = (node) ->
    unless node.apply
        node
        throw Error "apply"
    wrapped = -> node ...
    wrapped[copy] = -> wrap-node @[as-node][copy]!
    wrapped[as-node] = node
    for let own k,v of node
        unless wrapped[k]
            Object.define-property wrapped, k, 
                enumerable: true
                configurable: false
                get: -> @node[k]
                set: -> @node[k] = it
    wrapped