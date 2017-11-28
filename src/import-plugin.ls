require! {
    assert
    path
    fs
    \livescript-compiler/lib/livescript/Plugin
    \livescript-compiler/lib/livescript/ast/symbols : { parent, type }
    \livescript-compiler/lib/livescript/ast/Pattern
    \livescript-compiler/lib/livescript/ast/ObjectPattern
    \livescript-compiler/lib/livescript/ast/Literal
    \livescript-compiler/lib/livescript/ast/Identifier
    \livescript-compiler/lib/livescript/ast/TemporarVariable
    \livescript-compiler/lib/nodes/ConditionalNode
    \livescript-compiler/lib/nodes/symbols : {copy,as-node}
    \livescript-compiler/lib/nodes/JsNode
    \livescript-compiler/lib/nodes/TrueNode
    \livescript-compiler/lib/nodes/IfNode
    \livescript-compiler/lib/nodes/identity
    \livescript-compiler/lib/nodes/components/Copiable
    \livescript-compiler/lib/nodes/MatchMapCascadeNode
    \livescript-compiler/lib/core/symbols : {create}
    \./livescript/ast/Import
}

convert-literal-to-string = -> it.value.substring 1, it.value.length - 1

is-expression = ->
    node = it
    result = false
    while (parent-node = node[parent]) and not result
        result = 
            parent-node[type] in <[ Arr ]>
            or (parent-node[type] == \Assign and parent-node.right == node)
        node = parent-node
    result

MatchMapNode = ^^null
MatchMapNode <<<
    name: \MatchMapNode
    match: TrueNode.as-function

    map: identity
        
    exec: ->
        if matched = @match ...&
            @map.call @, matched

    (copy): -> ^^@


ConvertImports = ^^MatchMapNode
ConvertImports <<<
    name: \ConvertImports
    Import: Import
    match: ->
        if it[type] == \Import
        and it.left.value == 'this'
            source: it.right
            all: it.all
    
    map: ({all,source}) ->
        @Import[create] {all,source}
    



ExtractNamesFromSource = ^^MatchMapNode
ExtractNamesFromSource <<<
    name: \ExtractNamesFromSource
    match: ->
        if not it.names
        and (value = it.source.value)
        and not is-expression it
            node: it
            names: path.basename value.replace /\'/gi, ''
    map: ({node,names}) ->
        node.names = Identifier[create] name: names
        node
  


ExpandObjectImports = ^^MatchMapNode
ExpandObjectImports <<<
    name: \ExpandObjectImports
    Import: Import
    match: ->
        if it.source?[type] == \Obj
            it.source.items
    map: (items) ->
        items.map ~>
            @Import[create] do
                if it.key
                    names: it.val
                    source: it.key ? Identifier[create] name: convert-literal-to-string it.val
                    all: it.val.value == \__import-to-scope__
                else
                    names: Identifier[create] name: convert-literal-to-string it.val
                    source: it.val
  

ConvertImportsObjectNamesToPatterns = ^^MatchMapNode
ConvertImportsObjectNamesToPatterns <<<
    name: \ConvertImportsObjectNamesToPatterns
    match: ->
        if it.names?[type] == \Obj
            items: it.names.items
            node: it
    map: ({node,items}) ->
        node.names = Pattern[create] {items}
        node
  
extract-name-from-source = ->
    it
    |> (.replace /'/gi,'')
    |> (.split path.sep)
    |> (.[* - 1])
    |> path.basename

ArrayExpander = ^^MatchMapNode
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
        @Import[create] do
            names: Identifier[create] imported: true, name: extract-name-from-source it.value
            source: it

ExpandMetaImport = ^^MatchMapNode
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
            @export-resolver.resolve (convert-literal-to-string source), filename 
        catch
            if e.message.match /no such file/
                throw Error "Cannot meta-import module #{node.source.value} at #{node.line}:#{node.column} in #{node.filename}\nProbably mispelled module path"
            else
                throw e

ExportResolver =
    livescript: null
    Import: Import
    resolve: (module-path, current-path) ->
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
        items = exports.map -> Identifier[create] name: it.name.value
        @Import[create] do
            names: ObjectPattern[create] {items}
            source: Literal[create] value: "'#{module-path}'"
RemoveNode = JsNode.new (node) -> node.remove!
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
        ast-root.traverse-children walk
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
        names = TemporarVariable[create] name: \import, is-import: true
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

export default EnableImports = ^^Plugin
    ..name = \EnableImports
    ..config = {}
    ..enable = !->
        EsImport = Import[copy]!
        @livescript.ast <<< {EsImport}
        
        export-resolver = ExportResolver with {@livescript, Import: EsImport}
        
        ImportRules = MatchMapCascadeNode[copy]!
            ..name = \Import
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
            ..append ConvertImports with Import: EsImport
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