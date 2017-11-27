require! {
    \./JsNode
    \./symbols : { copy }
}

nop = JsNode.new !->
nop
    module.exports = ..
    ..name = \nop
    ..is-constant = true
    Object.freeze ..
