require! {
    \../components/core/Creatable
    \../composition : { import-properties }
    \./symbols : { pipe, push }
}


Sink = ^^null
    module.exports = ..
    import-properties .., Creatable
Sink <<<
    init: ({on-data} = {}) !->
        @on-data = on-data if on-data?
        
    (push): ({value}) !->
        @on-data value
        
    on-data: !-> throw Error "You need to implement on-data method youreself"
    
    (pipe): !-> throw Error "Cannot read from Sink. Sink is meant only for writing to."