require! {
    \./Node
    \./symbols : { parent, type }
}

Export = module.exports = ^^Node
Export <<<
    (type): \Export
    init: (@{local, alias}) ->
      
    traverse-children: (visitor, cross-scope-boundary)->
        visitor @local, @, \local
        visitor @alias, @, \alias if @alias
        @local.traverse-children ...&
        @alias.traverse-children ...& if @alias
        
    
    compile: (o) ->
        alias =
            if @alias
                if  @alias.name != \default
                then [" as ", (@alias.compile o )]
                else [" as default" ]
            else []
        inner = (@local.compile o)
        @to-source-node parts: [ "export { ", inner, ...alias, " }" ]

    terminator: ';'
    
    local:~
        -> @_local
        (v) ->
            v[parent] = @
            @_local = v