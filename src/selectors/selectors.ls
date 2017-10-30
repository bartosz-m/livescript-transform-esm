require! <[ ./PropertySelector ./TypeSelector ./SeriesSelector ./AndSelector ./AnySelector ]>

flat-wrap-array = ->
    unless 'Array' == typeof! it
        [it]
    else
        it

export series-selector = (series) ->
    new SeriesSelector
        for s in series => ..append s

export property-selector = (name, inner) ->
    new PropertySelector name
        ..inner = inner if typeof inner == 'Object'

export node-selector = ({type, capture, properties, series}) ->
    options = &0
    plugins =
        type: -> new TypeSelector it
        properties: (props) ->
            for k,v of props
                property-selector k
                    ..inner = node-selector v if v?
        capture: -> []
        series: (series) -> new SeriesSelector
            for s in series => ..append node-selector s
    selectors = []


    for own k,v of options
        unless (plugin = plugins[k])?
            throw Error "missing plugin for #{k}"
        new-selectors = flat-wrap-array plugin v
        selectors.push ...new-selectors
    result =
        | selectors.length == 0 => new AnySelector
        | selectors.length == 1 => selectors.0
        | otherwise =>
            new AndSelector
                for s in selectors => ..append s
    result.captures <<< capture if capture
    result
