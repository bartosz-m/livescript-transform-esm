require! {
    \../composition : { import-properties }
    \../components/core/Creatable
    \./symbols : { pipe, send }
    \./components : { Bufferable, Readable, Writable }
}

TransformStream = ^^null
    module.exports = ..
    import-properties .., Bufferable, Creatable, Writable, Readable
TransformStream <<< 
    init: (arg) !->
        Bufferable.init ...
        Writable.init ...
        Readable.init ...
        @transform = arg.transform if arg?transform?
    
    # because we implemented Bufferable we are ready on the start
    ready: true
    
    (send): (element) !->
        if element.value[pipe]?
            element.value[pipe] @
        else                
            transformed = @transform element.value
            # unwrapping streams
            if transformed?[pipe]?
                transformed[pipe] @output
            # flattening arrays
            else if Array.is-array transformed # using length? can fail
                for e in transformed
                    Writable[send].call @, value: e
            else
                Writable[send].call @, value: transformed
              
    transform: (x) ->
        throw Error "You need to implement transform method youreself"