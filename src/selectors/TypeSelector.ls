require! {
    './check'
    './SeriesSelector'
    './AbstractSelector'
}

is-a = (constructor-name, object) ->
    check.is-defined object
    object@@name == constructor-name


class TypeSelector extends AbstractSelector
    module.exports = @

    (@type) !->
        super!
        @inner = []

    _match: (node, matched) ->
        check.is-defined node, 'Node'

        if is-a @type, node
            @capture node, matched
            matched
        else
            null
