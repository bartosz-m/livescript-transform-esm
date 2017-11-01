require! {
    \../composition : { import-properties }
    \../components/core/Creatable
    \./symbols : { pipe, push, send }
}

Output = module.exports = ^^null
    import-properties .., Creatable
Output <<<
    init: !->
        @streams = []
    
    ready:~
        -> @streams.length != 0
        
    (push): (packet) !->
        for stream in @streams
            stream[push] packet
    
    (pipe): (stream) !->
        @streams.push stream
    
    (send): (packet) !->
        for stream in @streams
            stream[push] packet