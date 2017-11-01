Writable = module.exports =
    init: !->
        @buffer = []
        
    write: (x) !-> ...
    
    push: (something) !->
        @buffer.push something
        @flush! if @outputs.length > 0