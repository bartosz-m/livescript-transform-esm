require! {
    './check'
}
# Klasa ta wyszukuje serie spełniającą wszystkie pod selektory
class SeriesSelector
    module.exports = @
    ->
        @selectors = []
        @captures = {}

    append: (selector) ->
        @selectors.push selector
        selector

    capture: (node, matched = {}) ->
        for own c, fn of @captures
            matched[c] = fn node
        matched

    # TODO inner selectors mogą dotyczyć
    _match: (node, matched) ->
        check
            ..is-defined node, \node
            ..has-iterator node

        node-iterator = node[Symbol.iterator]!
        for selector in @selectors
            {value:next-node, done} = node-iterator.next!
            if done => return null  # reached end of data but not of the selectors
            check.is-defined next-node, \next-node
            unless result = selector._match next-node, matched
                return null
        @capture node, matched

        matched

    match: (node) ->
        check.is-defined node, \node
        @_match node, {}
