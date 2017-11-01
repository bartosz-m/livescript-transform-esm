require! {
    \../symbols : { push, send }
}

Writable = module.exports =
    init: !->
        
    (send): !->
        @output[push] it
      
    push: (value) !->
        @[push] {value}