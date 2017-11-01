require! {
    \./Sink
}

ArraySink = ^^Sink
    module.exports = ..
ArraySink <<<
    init: !->
        Sink.init.call @, on-data: @push-value
        @value = []
        
    push-value: (x) !->
        @value.push x