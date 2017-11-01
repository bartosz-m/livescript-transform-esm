require! {
    \../symbols : { pipe, send-to-outputs }
}

Readable = module.exports = 
    init: !->
        @outputs = []
        
    (send-to-outputs): (something, meta-data) ->
        for output in @outputs
            output.push something, meta-data
            
    (pipe): (output) ->
        @outputs.push output
        @flush!
        output