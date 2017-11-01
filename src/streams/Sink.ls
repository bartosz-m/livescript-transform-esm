require! {
    \../components/core/Creatable
    \../composition : { import-properties }
    \./symbols : { pipe }
}


Sink = ^^null
    module.exports = ..
    import-properties .., Creatable
Sink <<<
    init: ({on-data} = {}) !->
        @on-data = on-data if on-data?
        
    push: (x) !->
        @on-data x
    
    on-data: !-> throw Error "You need to implement on-data method youreself"
    
    (pipe): !-> throw Error "Cannot read from Sink. Sink is meant only for writing to."