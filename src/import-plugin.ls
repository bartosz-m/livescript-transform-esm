import
    \assert
    \path
    \fs
    \globby
    \livescript-compiler/lib/livescript/Plugin
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/livescript/ast/Pattern
    \livescript-compiler/lib/livescript/ast/ObjectPattern
    \livescript-compiler/lib/livescript/ast/Literal
    \livescript-compiler/lib/livescript/ast/Assign
    \livescript-compiler/lib/livescript/ast/Identifier
    \livescript-compiler/lib/livescript/ast/TemporarVariable
    \js-nodes : { ConditionalNode, JsNode, TrueNode, IfNode, identity, MatchMapCascadeNode }
    \js-nodes/symbols : { copy, as-node }
    \js-nodes/components/Copiable
    \livescript-compiler/lib/core/symbols : { create }
    \./livescript/ast/Import
    \./livescript/ast/Export
    \./nodes/MatchMap
    \./utils : ...

literal-to-string = -> it.value.substring 1, it.value.length - 1

debug =
  log: !-># console.log ...&

is-expression = ->
    node = it
    result = false
    while (parent-node = node[parent]) and not result
        result = 
            parent-node[type] in [ \Arr Export[type] ]
            or (parent-node.right == node)
        node = parent-node
    result


extract-name-from-source = ->
    it
    |> (.replace /'/gi,'')
    |> (.split path.sep)
    |> (.[* - 1])
    |> path.basename

# MatchMapNode = ^^null
# MatchMapNode <<<
#     name: \MatchMapNode
#     match: TrueNode.as-function
# 
#     map: identity
# 
#     exec: ->
#         if matched = @match ...&
#             @map.call @, matched
# 
#     (copy): -> ^^@


ConvertImports = ^^MatchMap
ConvertImports <<<
    name: \ConvertImports
    Import: Import
    match: ->
        if it[type] == \Import
        and it.left.value == 'this'
            source: it.right
            all: it.all
    
    map: ({all,source}) ->
        debug.log @name
        @Import[create] {all,source}
    
# InsertImportNodes = ^^MatchMap
# InsertImportNodes <<<
#     name: \InsertImportNodes
#     ast: {}
#     match: (node)->
#         if node[type] == \Call
#         and node[parent]
#         and (chain = node[parent])[type] == \Chain
#         and chain.head.value == \__static-import__
#             args: node.args
#             chain: chain
# 
#     map: ({chain,args}) ->
#         # console.log args
#         if args.length == 0
#             throw Error "Empty import at #{chain.line}:#{chain.column}"
#         args.map ~> @ast.EsImport[create] source: it


InsertImportNodes = ^^MatchMap
InsertImportNodes <<<
    name: \InsertImportNodes
    ast: {}
    match: (chain)->
        if chain[type] == \Chain
        and chain.head.value == \__static-import__
            args: chain.tails.0.args
            chain: chain

    map: ({chain,args}) -> 
        debug.log @name
        if args.length == 0
            throw Error "Empty import at #{chain.line}:#{chain.column}"
        # new-chain = ^^ Object.get-prototype-of chain
        if args.length > 0
            if args.0[type] == \Splat
                [,...items]  = args
                items.map ~>
                    @ast.EsImport[create] source: it, all: true
                        copy-source-location it, ..
            else
              args.map ~>
                  @ast.EsImport[create] source: it
                      copy-source-location it, ..
        else
            @ast.EsImport[create] source: args.0
            # ..[parent] = new-chain
        # tails = args.map ~> 
        #     @ast.EsImport[create] source: it
        #         ..[parent] = new-chain
        # 
        # new-chain <<< chain
        #     ..head = tails.shift!
        #     ..tails = tails
        
InsertImportBlock = ^^MatchMap
InsertImportBlock <<<
    name: \InsertImportBlock
    ast: {}
    match: (chain)->
        if chain[type] == \Chain
        and chain.head.value == \__static-import__
            args: chain.tails.0.args
            chain: chain

    map: ({chain,args}) -> 
        debug.log @name
        debug.log chain[parent]
        if args.length == 0
            throw Error "Empty import at #{chain.line}:#{chain.column}"
        # new-chain = ^^ Object.get-prototype-of chain
        if args.length > 0
        and args.0[type] == \Splat
            [,...items]  = args
            items.map ~>
                @ast.EsImport[create] source: it, all: true
                    copy-source-location it, ..
        else
            @ast.EsImport[create] source: args.0

ExtractImportFromAssign = ^^MatchMap
ExtractImportFromAssign <<<
    name: \ExtractImportFromAssign
    ast: {}
    match: (node)->
        if node[type] == \Cascade
        and (assign = node.input)[type] == \Assign
        and assign.right.value == \__static-import__
            lines: node.output.lines
            assign: assign
            cascade: node
    map: ({assign,lines,cascade}) ->        
        debug.log @name
        if lines.length == 0
            throw Error "Empty import at #{cascade.line}:#{cascade.column}"
        if lines.length != 1
            throw Error "Expected import specifier on the same line #{cascade.line}:#{cascade.column}"
        es-import = @ast.EsImport[create] source: lines.0
            ..[parent] = assign
            ..filename = cascade.filename
            ..line = ..first_line = assign.last_line
            ..column = ..first_column = assign.last_column + 1
            ..last_line = lines.0.last_line
            ..last_column = lines.0.last_column
            
        cascade.output = {}
        cascade.input = {}
        n-assign = Assign[create] left: assign.left, right: es-import
        # assign
        #     ..right = es-import
                # ..[parent] = assign
            

InsertImportAllNodes = ^^MatchMap
InsertImportAllNodes <<<
    name: \InsertImportAllNodes
    ast: {}
    match: (node)->
        if node[type] == \Cascade
        and node.input.value == \__static-import-all__
            node
    map: (cascade) ->
        debug.log @name
        const {lines} = cascade.output
        if lines.length == 0
            throw Error "Empty import at #{cascade.line}:#{cascade.column}"
        lines.map ~> @ast.EsImport[create] source: it, all: \all

InsertScopeImports = ^^MatchMap
InsertScopeImports <<<
    name: \InsertScopeImports
    ast: {}
    match: (node)->
        if node[type] == \Cascade
        and node.input.value == \__import-to-scope__
            node
    map: (cascade) ->
        debug.log @name
        const {lines} = cascade.output
        if lines.length == 0
            throw Error "Empty import at #{cascade.line}:#{cascade.column}"
        lines.map ~> @ast.EsImport[create] source: it, all: \all
    


source-to-name = (literal) ->
    literal.value
    |> (.replace /\'/gi, '')
    |> -> path.basename it, path.extname it

ExtractNamesFromSource = ^^MatchMap
ExtractNamesFromSource <<<
    name: \ExtractNamesFromSource
    match: ->
        # console.log it.names?,it.source.value?
        if not it.names
        and (value = it.source.value)
        # and not is-expression it
            node: it
            names: source-to-name it.source
            # names: path.basename value.replace /\'/gi, ''
    map: ({node,names}) ->
        debug.log @name
        node.names = Identifier[create] name: names
            copy-source-location node.source, ..
        node
  
identifier-from-literal = (literal) ->
    Identifier[create] name: literal-to-string literal
        copy-source-location literal, ..

ExpandObjectImports = ^^MatchMap
ExpandObjectImports <<<
    name: \ExpandObjectImports
    Import: Import
    match: ->
        if it.source?[type] == \Obj
            it.source.items
    map: (items) ->
        debug.log @name
        items.map ~>
            result = @Import[create] do
                if it.key
                    names: it.val
                    source: it.key ? identifier-from-literal it.val
                    all: it.val.value == \__import-to-scope__
                else
                    names: identifier-from-literal it.val
                    source: it.val
            result
                copy-source-location it, ..
  

ConvertImportsObjectNamesToPatterns = ^^MatchMap
ConvertImportsObjectNamesToPatterns <<<
    name: \ConvertImportsObjectNamesToPatterns
    match: ->
        if it.names?[type] == \Obj
            items: it.names.items
            node: it
    map: ({node,items}) ->
        debug.log @name
        node.names = Pattern[create] {items}
            copy-source-location node, ..
        node
  


ArrayExpander = ^^MatchMap
ArrayExpander <<<
    name: \ArrayExpander
    map-item: -> it
    map: (items) ->
        items.map @~map-item

ExpandArrayImports = ^^ArrayExpander
ExpandArrayImports <<<
    name: \ExpandArrayImports
    Import: Import
    match: ->
        if it.source[type] == \Arr
            it.source.items
    map-item: ->
        debug.log @name
        id = Identifier[create] imported: true, name: extract-name-from-source it.value
            copy-source-location it, ..
        @Import[create] names: id, source: it
            copy-source-location it, ..
        

ExpandGlobImport = ^^MatchMap
ExpandGlobImport <<<
    name: \ExpandGlobImport
    
    Import: Import
    
    match: (node) ->
        if (literal = node.source)[type] == \Literal
        and literal.value.match /\*/
        and not is-expression node
            glob = literal-to-string literal
            module-path = path.dirname node.filename
            paths = globby.sync glob, cwd: module-path
            .map ->
                without-ext = it.replace (path.extname it), ''
                './' + without-ext
            {paths, literal}
    
    map: ({paths, literal}) ->
        debug.log @name
        paths.map ~>
            source = Literal[create] value: "'#{it}'"
                copy-source-location literal, ..
            @Import[create] source: source

ExpandGlobImportAsObject = ^^MatchMap
ExpandGlobImportAsObject <<<
    name: \ExpandGlobImportAsObject
    
    Import: Import
    
    match: (node) ->
        if (literal = node.source)[type] == \Literal
        and literal.value.match /\*/
        and is-expression node
            glob = literal-to-string literal
            module-path = path.dirname node.filename
            paths = globby.sync glob, cwd: module-path
            .map ->
                without-ext = it.replace (path.extname it), ''
                './' + without-ext
            {paths, literal:literal}
    
    
    map: ({paths, literal}) ->
        debug.log @name
        result = ObjectPattern[create] items: paths.map ~>
            source = Literal[create] value: "'#{it}'"
                copy-source-location literal, ..
            @Import[create] do
                source: source
        
        result
            copy-source-location literal, ..
          

ExpandMetaImport = ^^MatchMap
ExpandMetaImport <<<
    name: \ExpandMetaImport
    
    export-resolver: null
    
    match: (node) ->
        if node.all
            node
    
    map: ({source,filename}: node) ->
        try
            unless filename
                throw Error "Meta-import requires filename property on Import nodes"
            module-url = literal-to-string source
            exports = @export-resolver.resolve (literal-to-string source), filename
            items = exports.map -> 
                Identifier[create] name: it.name.value
                    copy-source-location source, ..
            
            resolved-source = Literal[create] value: "'#{module-url}'"
                copy-source-location source, ..
            resolved-names = ObjectPattern[create] {items}
                copy-source-location source, ..
            @Import[create] do
                names: resolved-names
                source: resolved-source
        catch
            if m = e.message.match /ENOENT, no such file or directory '([^']+)'/
                error = Error "Cannot extract exports of module #{node.source.value} in #{node.filename}:#{node.line}:#{node.column}\nNo such file #{m.1}\nProbably mispelled module path. #{e.message}"
                error.hash =
                    loc:
                        first_line: node.first_line ? node.line
                        first_column: node.first_column ? node.column
                        last_line: node.last_line ? node.line
                        last_column: node.last_column ? node.column
                throw error
            else
                throw e

ExportResolver =
    livescript: null
    Import: Import
    resolve: (module-path, current-path) ->
        #remove protocol if any
        module-path = module-path.replace /^\w+\:\/{0,2}/ ''
        current-path = current-path.replace /^\w+\:\/{0,2}/ ''
        cwd = path.dirname current-path
        resolved-path = path.resolve cwd, module-path
        unless module-path.0 == '.' or module-path.match /\.js$/
            throw Error "Only local livescript files can be imported to scope"
        ext =
              if path.extname path.basename resolved-path .length
              then ''
              else '.ls'
        code = fs.read-file-sync (resolved-path + ext), \utf8
        ast-root = @livescript.generate-ast code, filename: resolved-path
        
        exports = ast-root.exports
        
remove-node = (node) -> node.remove!

RemoveNode = JsNode.new remove-node
    ..name = \RemoveNode
    
FilterAst = ^^null
FilterAst <<< Copiable
FilterAst <<<
    nodes-names: <[ test ]>
    test: -> true
    exec: (ast-root, cross-scope-boundary) ->
        result = []
        walk = (node,parent,name,index) !~>
            if @test node
                result.push node
        ast-root.traverse-children walk, true
        # for e, i in ast-root.[]exports
        #     e.traverse-children walk, true
        # for imp, i in ast-root.[]imports
        #     imp.traverse-children walk, true
        result
  
OnlyImports = ^^FilterAst
OnlyImports <<<
    name: \OnlyImports
    test: (.[type] == Import[type])

    
ProcessArray = ^^null
ProcessArray <<< Copiable
ProcessArray <<<
    name: \ProcessArray
    node-names: <[ each ]>
    each: ->
    exec: ->
        for e in it
            @each.call null, e
            
ReplaceImportWithTemporarVariable =
    name: \ReplaceImportWithTemporarVariable
    (copy): -> ^^@
    exec: (_import) ->
        names = TemporarVariable[create] name: \imports, is-import: true
            copy-source-location _import, ..
        _import.replace-with names
        _import.names = names
    call: (,...args) -> @exec ...args
    apply: (,args) -> @exec ...args

RemoveOrReplaceImport = IfNode[copy]!
RemoveOrReplaceImport <<<
    name: \RemoveOrReplaceImport
    test: is-expression
    then: ReplaceImportWithTemporarVariable
    else: RemoveNode

RemoveOrReplaceImports = ^^ProcessArray
    ..name = \RemoveOrReplaceImports
    ..each = RemoveOrReplaceImport

MoveImportsToTop =
    name: \MoveImportsToTop
    copy: -> ^^@
    (copy): -> ^^@
    call: (this-arg, ...args)-> @exec ...args
    exec: (ast-root) !->
        imports = OnlyImports.exec ast-root
        ast-root.imports = imports
        RemoveOrReplaceImports.exec imports
        ast-root.is-module = ast-root.is-module or ast-root.imports.length != 0


export default EnableImports = ^^Plugin
    ..name = \EnableImports
    ..config = {}
    ..enable = !->
        special-lex = JsNode.new (lexed) ->
            result = []
            
            i = -1
            buffer = [[], []]
            last = [[]]
            inhibit-dedent =
                line: null
            while ++i < lexed.length
                l = lexed[i]
                if l.0 == \DEDENT and l.1 == inhibit-dedent.line
                    [,, ...rest] = l
                    result.push [ \)CALL '' ...rest ]
                    inhibit-dedent.line = null
                    
                else if l.1 == \import and l.0 == \DECL
                    [,, ...rest] = l
                    result.push [ \ID '__static-import__' ...rest]
                    i++ # skip indend
                    result.push [ \CALL( '' ...rest ]

                    inhibit-dedent.line = lexed[i].1
                else if l.1 == \importAll and l.0 == \DECL
                    [,, ...rest] = l
                    result.push [ \ID '__static-import-all__' ...rest]
                else if l.0 == ":"
                and i + 1 < lexed.length
                and lexed[i + 1].0 == '...'
                    result.push l
                    ++i
                    [,, ...rest] = l = lexed[i]
                    result.push [ \ID \__import-to-scope__ ...rest ]
                else
                    result.push l
                last.pop!
                last.unshift l
            
            # 
            # console.log lexed
            # console.log \0-0000
            # console.log result

            result
        special-lex2 = JsNode.new (lexed) ->
            result = []
            
            i = -1
            buffer = [[], []]
            last = [[]]
            while ++i < lexed.length
                l = lexed[i]
                if l.0 == ":"
                and i + 1 < lexed.length
                and lexed[i + 1].0 == '...'
                    result.push l
                    ++i
                    [,, ...rest] = l = lexed[i]
                    result.push [ \ID \__import-to-scope__ ...rest ]
                else if l.0 == ":"
                and i + 3 < lexed.length
                and lexed[i + 1].0 == '{'
                and lexed[i + 2].0 == '...'
                and lexed[i + 3].0 == '}'
                    result.push l
                    ++i
                    ++i #skip {
                    [,, ...rest] = l = lexed[i]
                    result.push [ \ID \__import-to-scope__ ...rest ]
                    ++i #skip }
                else if l.0 == \ID and l.1 == '__static-import__'
                and i + 3 < lexed.length
                and lexed[i + 1].0 == \INDENT
                and lexed[i + 2].0 == \...
                and lexed[i + 3].0 == \INDENT
                    [,, ...rest] = l
                    result.push [ 'NEWLINE', '\n', ...rest ]
                    result.push [ \ID \__import-to-scope__ ...rest ]
                    i++
                    i++
                    # i++
                    # i++
                    i++ # INDENT
                    result.push lexed[i]
                    i++ # INDENT
                    result.push lexed[i]
                    i++ # INDENT
                else
                    result.push l
                last.pop!
                last.unshift l
            
                
            # console.log lexed
            # console.log \0-0000
            # console.log result

            result
          
        @livescript.lexer.tokenize.append special-lex
        @livescript.lexer.tokenize.append special-lex2
        
      
        EsImport = Import[copy]!
        @livescript.ast <<< {EsImport}
        
        export-resolver = ExportResolver with {@livescript, Import: EsImport}
        
        ImportRules = MatchMapCascadeNode[copy]!
            ..name = \Import
            ..append ExpandGlobImport with {Import: EsImport}
            ..append ExpandGlobImportAsObject with {Import: EsImport}
            ..append ExtractNamesFromSource
            ..append ExpandObjectImports with Import: EsImport
            ..append ConvertImportsObjectNamesToPatterns
            ..append ExpandArrayImports with Import: EsImport
            ..append ExpandMetaImport with {Import: EsImport, export-resolver}
            
                
        EnableImports = ConditionalNode[copy]!
            ..name = \Imports
            ..condition = JsNode.new -> it[type] == EsImport[type]
            ..next = ImportRules
                    
        @livescript.expand
            # ..append ConvertImports with Import: EsImport
            ..append InsertImportNodes with @livescript{ast}
            ..append InsertImportAllNodes with @livescript{ast}
            ..append InsertScopeImports with @livescript{ast}
            ..append ExtractImportFromAssign with @livescript{ast}
            ..append EnableImports
        
        simplified-compiler = @livescript.copy!
            ..expand.rules.find (.name == \Imports) .next.remove (.name == \ExpandMetaImport)
            
        export-resolver.livescript = simplified-compiler
        export-resolver.Import = EsImport
        
        @livescript.postprocess-ast.append MoveImportsToTop
        
        if @config.format == \cjs
            EsImport.compile[as-node]js-function = (o) ->
                names = @names.compile o
                required = "require(#{@source.compile o})"
                unless @names.items
                    required = "(#{required}['__default__'] || #{required})"
                @to-source-node parts: [ "var ", names, " = ", required, @terminator ]