require! {
    \../symbols : { pipe, push, send }
    \../Output
}

Readable = module.exports = 
    init: !->
        @output = Output.create!
            
    (pipe): (output) ->
        @output[pipe] output
        @flush!
        output