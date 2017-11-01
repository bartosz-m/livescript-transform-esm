require! {
    \../symbols : { push, send }
}

Bufferable = module.exports =
    init: !->
        @buffer = []
    
    (push): !->
        @buffer.push it
        @flush! if @output.ready
        
    flush: !->
        for element in @buffer
            @debug? \flushing, element
            @[send] element
        @buffer = []