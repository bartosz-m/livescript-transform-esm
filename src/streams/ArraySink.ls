require! {
    \./Sink
}

ArraySink = ^^Sink
    module.exports = ..
ArraySink <<<
    init: !->
        Sink.init ...
        @value = []
        
    on-data: (x) !->
        @value.push x