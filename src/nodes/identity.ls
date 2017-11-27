require! {
    \./JsNode
    \./symbols : { copy }
}

identity = JsNode.new -> it
identity
    module.exports = ..
    ..name = \identity
    ..is-constant = true
    Object.freeze ..
