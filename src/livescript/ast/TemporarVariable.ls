require! {
    \../../components/core/Creatable
    \../../composition : { import-properties }
    \./symbols : {type}
    \./Node
  
}
TemporarVariable = module.exports = ^^Node
    import-properties .., Creatable
TemporarVariable <<<    
    (type): \TemporarVariable
    
    init: (@{name,is-export,is-import}) !->
      
    traverse-children: (visitor, cross-scope-boundary) ->
    
    compile: (o) ->
        @temporary-name ?= o.scope.temporary @name
        if @is-export or @is-import
            o.scope?variables["#{@temporary-name}."] = 'DONT TOUTCH'
        @to-source-node parts: [@temporary-name]