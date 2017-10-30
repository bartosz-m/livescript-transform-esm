require! {
    './check'
    './AbstractSelector'
}
class AnySelector extends AbstractSelector
    module.exports = @
    !->
        super!

    _match: (node, matched) ->
        check.is-defined node, 'Node'
        @capture node, matched
        matched
