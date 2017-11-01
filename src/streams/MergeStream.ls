require! {
    \./symbols : { pipe }
    \./DuplexStream
}

MergerStream = module.exports = ^^DuplexStream
MergerStream <<<
    init: (arg) !->
        DuplexStream.init ...
        if arg.streams
            for stream in arg.streams
                stream[pipe] @