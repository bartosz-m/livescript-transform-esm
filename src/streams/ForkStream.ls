require! {
    \../components/core : { Creatable }
    \../composition : { import-properties }
    \./DuplexStream
}

ForkStream = ^^null
    module.exports = ..
    import-properties .., Creatable
ForkStream <<<
    init: (arg) !->
        @route = arg.route if arg?route?
        @outputs = {}
        @routes = arg.routes if arg?routes?
        for route in @routes
            @outputs[route] = DuplexStream.create!
                .. <<< {route}
    
    route: ->  throw Error "You need to implement route method youreself"
    
    push: ->
        @outputs[@route it].push it