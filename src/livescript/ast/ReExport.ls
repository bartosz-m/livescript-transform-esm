require! {
    \./Export
    \./symbols : { parent, type }
}


ReExport = module.exports = ^^Export
ReExport <<<
    (type): \ReExport
    
    init: (@{names, source-specifier}) !->
      
    traverse-children: (visitor, cross-scope-boundary) ->
    
    compile: (o) ->
        names = 
            if @names.length > 1
                " { #{@names.join ','}} "
            else if @names.length == 1
                " #{@names.0} "
            else 
                " "
        @to-source-node parts: ["export#{names}from ", @source-specifier.compile o]
    
    terminator: ';'