require! {
    \../composition : { import-properties }
    \../components/core/Creatable
    \./symbols : { pipe, send-to-outputs }
    \./components : { Readable, Writable }
}

TransformStream = ^^null
    module.exports = ..
    import-properties .., Creatable, Writable, Readable
TransformStream <<< 
    init: (arg) !->
        Writable.init ...
        Readable.init ...
        @transform = arg.transform if arg?transform?
        
    flush: !->
        for element in @buffer
            @debug? \flushing, element
            if element.value[pipe]?
                element.value[pipe] @
            else                
                transformed = @transform element.value
                # unwrapping streams
                if transformed?[pipe]?
                    for output in @outputs
                        transformed[pipe] output
                # flattening arrays
                else if Array.is-array transformed # using length? can fail
                    for e in transformed
                        @[send-to-outputs] value: e
                else
                    @[send-to-outputs] value: transformed
        @buffer = []
              
    transform: (x) ->
        throw Error "You need to implement transform method youreself"