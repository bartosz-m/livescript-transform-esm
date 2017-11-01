require! {
    \../symbols : { push }
}

Writable = module.exports =
    init: !->
        @buffer = []
    
    (push): !->
        @buffer.push it
        @flush! if @outputs.length > 0
      
    push: (value) !->
        @[push] {value}