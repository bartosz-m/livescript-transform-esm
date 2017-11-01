require! {
    \../composition : { import-properties }
    \../components/core/Creatable
    \./symbols : { pipe }
}

CascadeStream = module.exports = ^^null
    import-properties .., Creatable
CascadeStream <<<
    init: (arg) !->
        @streams = arg.streams
        @input = @streams.0
        @output = @streams[* - 1]
        
        for stream in @streams
            previous-stream[pipe] stream if previous-stream
            previous-stream = stream
        unless @input? or @output
            throw Error "ComposedStream requires both input and output"
    
    push: !-> @input.push it
    
    (pipe): -> @output[pipe] it