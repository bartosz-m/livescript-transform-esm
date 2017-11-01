require! {
    \../components/core/Creatable
    \../composition : { import-properties }
    \./symbols : { pipe }
}

ComposedStream = module.exports = ^^null
    import-properties .., Creatable
ComposedStream <<<
    init: (arg) !->
        @input = arg.input
        @output = arg.output
        unless @input? or @output
            throw Error "ComposedStream requires both input and output"
    
    push: !-> @input.push it
    
    (pipe): -> @output[pipe] it