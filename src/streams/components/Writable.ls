require! {
    \../symbols : { push, send }
}

Writable = module.exports =
    init: !->
        
    (send): !->
        @output[send] it
      
    push: (value) !->
        @[push] {value}