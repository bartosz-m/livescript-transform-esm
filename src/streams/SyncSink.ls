require! {
    \./symbols : { pipe }
    \./Sink
    \./ArraySink
}

SyncSink = module.exports = ^^Sink
SyncSink <<<
    on-data: !->
    push: (element) ->
        if Array.is-array element
            for k,v in element
                if v?[pipe]?
                    array-sink = ArraySink.create!
                        v[pipe] ..
                        element[k] = ..value
        else if \Object == typeof! element 
            for own k,v of element
                if v?[pipe]?
                    array-sink = ArraySink.create!
                        v[pipe] ..
                        element[k] = ..value
        Sink.push.call @, element