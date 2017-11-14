require! {
    \./Node
    \./symbols : { parent, type }
}

Import = module.exports = ^^Node
Import <<<
    (type): \Import
    init: (@{names, source}) ->
      
    traverse-children: (visitor, cross-scope-boundary) ->
        
    
    compile: (o) ->
        names = @names.compile o
        @to-source-node parts: [ "import ", names, " from ", @source.compile o ]

    terminator: ';'
    
    local:~
        -> @_local
        (v) ->
            v[parent] = @
            @_local = v