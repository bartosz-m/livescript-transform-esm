require! {
    \../components/core/Creatable
    \../composition : { import-properties }
    \./symbols : { pipe, send-to-outputs }
    \./components : { Readable, Writable }
}

DuplexStream = ^^null
    module.exports = ..
    import-properties .., Creatable, Readable, Writable
DuplexStream <<<
    init: !->
        Readable.init ...
        Writable.init ...
        
    flush: !->
        for element in @buffer
            @[send-to-outputs] element
        @buffer = []