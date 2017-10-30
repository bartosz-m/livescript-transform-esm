require! {
    './check'
}

class AbstractSelector
    module.exports = @

    !->
        @captures = {}

    capture: (node, matched = {})->
        if @captures?
            for own c, fn of @captures
                matched[c] = fn node
        matched

    _match: (node, matched) ->
        throw Error "#{@@name} nie ma metody _match"

    match: (node) ->
        check.is-defined node, 'Node'
        result = @_match node, {}
        @capture node, result if result?
        result
