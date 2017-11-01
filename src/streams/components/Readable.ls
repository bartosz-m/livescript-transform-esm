require! {
    \../symbols : { pipe, push, send-to-outputs }
}

Readable = module.exports = 
    init: !->
        @outputs = []
        
    (send-to-outputs): (something) ->
        for output in @outputs
            output[push] something
            
    (pipe): (output) ->
        @outputs.push output
        @flush!
        output