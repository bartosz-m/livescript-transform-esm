{ parent, type } = import \livescript-compiler/lib/livescript/ast/symbols

import
    \assert
    \livescript-compiler/lib/livescript/Plugin

    \livescript-compiler/lib/nodes/JsNode
    \livescript-compiler/lib/nodes/symbols : { copy, as-node }
    \livescript-compiler/lib/core/symbols : {create, init}
    \./livescript/ast/Export
    \./livescript/ast/ReExport
    \./livescript/ast/DynamicImport
    \./livescript/ast/Import
    \./nodes/MatchMap

InsertDynamicImport = MatchMap[copy]!
InsertDynamicImport <<<
    name: \InsertDynamicImport
    ast: {}
    match: (node)->
        if node[type] == \Chain
        and (head = node.head)[type] == \Var
        and head.value == '__dynamic-import__'
        and (call = node.tails.0)[type] == \Call
            call.args
    map: (sources) ->
        @ast.DynamicImport[create] {sources}
    
    
    
export default DynamicImportTransform = ^^Plugin
    module.exports = ..

    ..name = 'dynamic-import'
    
    ..config = {}

    ..enable = !->
        special-lex = JsNode[copy]!
            ..js-function = (lexed) ->
                result = []
                i = -1
                buffer = [lexed.0, lexed.1]
                while ++i < lexed.length     
                    l = lexed[i]
                    [,, ...rest] = l
                        
                    if l.0 == \ID and l.1 == \async
                    and i + 2 < lexed.length
                    and lexed[i + 1].0 == \IMPORT
                        source = lexed[i + 2]                        
                        [,, ...rest] = l
                        fn-name = [ \ID '__dynamic-import__' ...rest] 
                            ..spaced = true
                            result.push ..
                        [,, ...rest] = source
                        result.push [ 'CALL(' '' ...rest]
                        i++ #skip async
                        i++ #skip IMPORT
                        result.push source
                        result.push [ ')CALL' '' ...rest]

                        
                    else
                        result.push l
                result
            
        @livescript.lexer.tokenize.append special-lex
        @livescript.ast.DynamicImport = DynamicImport[copy]!


        @livescript.expand
            ..append InsertDynamicImport with @livescript{ast}
        
        if @config.format == \cjs
             @livescript.ast.DynamicImport.compile[as-node]js-function = (o) ->
                   sources = @sources.map (.compile o)
                   @to-source-node parts: [ "Promise.resolve( require(", sources, ") )" ]
      