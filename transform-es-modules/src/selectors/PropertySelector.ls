require! {
    './check'
    './AnySelector'
    './AbstractSelector'
}

is-ok = -> true

class PropertySelector extends AbstractSelector
    module.exports = @

    (@property, @property-tester = is-ok) ->
        super!
        @inner = new AnySelector
        unless 'Function' == typeof! @property-tester
            @property-tester = let expected-value = @property-tester
                -> it == expected-value

    _match: (node, matched) ->
        check.is-defined node, 'node'

        if (property = node[@property])?
            and @property-tester property
            and @inner._match node[@property], matched
        then
            @capture node, matched
            matched
        else
            null
