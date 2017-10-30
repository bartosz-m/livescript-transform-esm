require! {
    './check'
    './AbstractSelector'
}

# Klasa ta wyszukuje serie spełniającą wszystkie pod selektory
class AndSelector extends AbstractSelector
    module.exports = @

    !->
        super!
        @selectors = []

    append: (selector) ->
        @selectors.push selector
        selector

    _match: (node, matched) ->
        check.is-defined node, 'Node'

        for selector in @selectors
            unless result = selector._match node, matched
                return null
        @capture node, matched

        matched
