require! {
    \./Node
    \./symbols : { parent, type }
}

Import = module.exports = ^^Node
Import <<<
    (type): \MyImport
    init: (@{names, source,all}) ->
      
    traverse-children: (visitor, cross-scope-boundary) ->
        
    
    compile: (o) ->
        names = @names.compile o
        @to-source-node parts: [ "import ", names, " from ", (@source.compile o), @terminator ]

    terminator: ';'
