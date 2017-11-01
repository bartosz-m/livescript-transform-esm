require! {
    \../components/core/Creatable
    \../composition : { import-properties }
    \./symbols : { pipe, send, send-to-outputs }
    \./components : { Bufferable, Readable, Writable }
    \./Output
}

DuplexStream = ^^null
    module.exports = ..
    import-properties .., Bufferable, Creatable, Readable, Writable
DuplexStream <<<
    init: !->
        Bufferable.init ...
        Readable.init ...
        Writable.init ...
        
    flush: !->
        for element in @buffer
            @output[send] element
        @buffer = []