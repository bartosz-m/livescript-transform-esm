require! {
    \./symbols : {copy}
    \./JsNode
}

TrueNode = module.exports = ^^null
TrueNode <<<
    is-constant: true
    name: \True
    (copy): -> @
    value: true
    as-function: JsNode.new -> true

Object.freeze TrueNode
    