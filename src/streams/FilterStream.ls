require! {
    \../composition : { import-properties }
    \./symbols : { push }
    \./DuplexStream
}

FilterStream = module.exports = ^^DuplexStream
FilterStream <<<
    init: (arg) !->
        DuplexStream.init ...
        @filter = arg.filter if arg?filter?
        
    filter: ->  throw Error "You need to implement filter method youreself"
    
    (push): !->
        DuplexStream[push] ... if @filter it.value