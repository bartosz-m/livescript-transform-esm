require! <[ assert livescript-ast-transform ]>
{ parent, type } = require \./livescript/ast/symbols

require! {
    fs
    path
    \./components/core/Creatable
    \./composition : { import-properties }
    \./livescript/ast/Assign
    \./livescript/ast/Export
    \./livescript/ast/Identifier
    \./livescript/ast/Import
    \./livescript/ast/Literal
    \./livescript/ast/Node
    \./livescript/ast/ObjectPattern
    \./livescript/ast/Pattern
    \./livescript/MatchMapCascadeNode
    \./livescript/ConditionalNode
}
        
          
# Question unfold-soak, compile vs compile-node
# info scope.temporary


Prototype = Symbol \prototype
Temporary = Symbol \scope::temporary
Variables = Symbol \scope::variables

TemporarVariable = ^^Node
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
  

TemporarAssigment = ^^Node
    import-properties .., Creatable
TemporarAssigment <<<
    (type): \TemporarAssigment

    init: (@{left,right}) !->

    traverse-children: (visitor, cross-scope-boundary) ->
        visitor @left, @, \left
        visitor @right, @, \right
        @left.traverse-children ...&
        @right.traverse-children ...&

    compile: (o) ->
        @to-source-node parts: [
            @left.compile o
            ' = '
            @right.compile o
        ]

    terminator: ';'

    left:~
        -> @_left
        (v) ->
            v[parent] = @
            @_left = v
    right:~ 
        -> @_right
        (v) ->
            v[parent] = @
            @_right = v

as-array = ->
    if Array.is-array it
    then it
    else [it]

convert-literal-to-string = -> it.value.substring 1, it.value.length - 1
camelize = (.replace /-[a-z]/ig -> it.char-at 1 .to-upper-case!)


BaseNode = ^^null
BaseNode <<< 
    name: \BaseNode
    copy: -> ^^@
    remove: -> throw Error "Unimplemented method remove in #{@name}"
    call: (, ...args)-> @process ...args
    apply: (,args)-> @process ...args

CascadeRule =
    append: (rule) ->
        unless rule.copy
              throw new Error "Creating node #{rule.name ? ''} without copy method is realy bad practice"
        unless rule.name
            throw new Error "Adding rule without a name is realy bad practice"
        @rules.push rule

ExportRules = ^^CascadeRule
ExportRules <<<
    name: \Export
    rules: []
    match: ->
        if it[type] == \Export
            for rule in @rules
                if m = rule.match it
                    result =
                        rule: rule
                        matched: m
                    break
        
        result
    replace: ({rule,matched}) ->
        replacer = rule.replace matched
        as-array replacer

ImportRules = ^^null
    .. <<< BaseNode
    .. <<< CascadeRule
ImportRules <<<
    name: \Import
    rules: []
    copy: -> 
        @rules.filter -> not it.copy?
        .for-each -> console.log "#{it.name} missing copy"
        ^^@
            ..rules = ..rules.map (.copy!)
    match: ->
        if it[type] == Import[type]
            for rule in @rules
                if m = rule.match it
                    result =
                        rule: rule
                        matched: m
                    break
        
        result
    replace: ({rule,matched}) ->
        replacer = rule.replace matched
        as-array replacer
    
    process: ->
        if matched = @match it
            @replace matched
    
    remove: (rule-or-filter) ->
        idx = if \Function == typeof! rule-or-filter
              then @rules.find-index rule-or-filter
              else @rules.index-of rule-or-filter
        if idx != -1
            rule = @rules[idx]
            @rules.splice idx, 1
            rule
        else
            throw Error "Cannot remove rule - there is none matching"

ConvertImports = ^^BaseNode
ConvertImports <<<
    name: \ConvertImports
    match: ->
        if it[type] == \Import
        and it.left.value == 'this'
            source: it.right
            all: it.all
    
    replace: ({all,source}) ->
        Import.create {all,source}
        
    process: ->
        if matched = @match it
            @replace matched
    
    copy: ->
        ^^@
    

ExtractNamesFromSource = ^^BaseNode
ExtractNamesFromSource <<<
    name: \ExtractNamesFromSource
    match: ->
        if not it.names
        and (value = it.source.value)
        and not is-expression it
            node: it
            names: path.basename value.replace /\'/gi, ''
    replace: ({node,names}) ->
        node.names = Identifier.create name: names
        node
  
ImportRules.append ExtractNamesFromSource

ExpandObjectImports = ^^BaseNode
ExpandObjectImports <<<
    name: \ExpandObjectImports
    match: ->
        if it.source?[type] == \Obj
            it.source.items
    replace: (items) ->
        items.map ->
            Import.create do
                if it.key
                    names: it.val
                    source: it.key ? Identifier.create name: convert-literal-to-string it.val
                else
                    names: Identifier.create name: convert-literal-to-string it.val
                    source: it.val
  
ImportRules.append ExpandObjectImports

ConvertImportsObjectNamesToPatterns = ^^BaseNode
ConvertImportsObjectNamesToPatterns <<<
    name: \ConvertImportsObjectNamesToPatterns
    match: ->
        if it.names?[type] == \Obj
            items: it.names.items
            node: it
    replace: ({node,items}) ->
        node.names = Pattern.create {items}
        node
  
ImportRules.append ConvertImportsObjectNamesToPatterns
  
extract-name-from-source = ->
    it
    |> (.replace /'/gi,'')
    |> (.split path.sep)
    |> (.[* - 1])
    |> path.basename

ExpandArrayImports = ^^BaseNode
ExpandArrayImports <<<
    name: \ExpandArrayImports
    match: ->
        if it.source[type] == \Arr
            it.source.items
    replace: (items) ->
        items.map ->
            Import.create do
                names: Identifier.create imported: true, name: extract-name-from-source it.value
                source: it

ImportRules.append ExpandArrayImports

ExpandArrayExports = ^^BaseNode
ExpandArrayExports <<<
    name: \ExpandArrayExports
    match: ->
        if it.local[type] == \Arr
            it.local.items
    replace: (items) ->
        items.map -> Export.create local: it

ExportRules.append ExpandArrayExports

EnableDefaultExports = ^^BaseNode
EnableDefaultExports <<<
    name: \EnableDefaultExports
    match: ->
        if (cascade = it.local)[type] == \Cascade
        and cascade.input[type] == \Var
        and cascade.input.value == \__es-export-default__
            cascade.output.lines.0
    replace: (line) ->
        Export.create local: line, alias: Identifier.create name: \default

ExportRules.append EnableDefaultExports

WrapLiteralExports = ^^BaseNode
WrapLiteralExports <<<
    name: \WrapLiteralExports
    match: ->
        {local} = it
        Type = local[type]
        if Type == \Literal
        or (Type == \Fun and not local.name?)
        or (Type == \Class and not local.name?)
            it
    
    replace: (node) ->
        tmp = TemporarVariable.create name: \export, is-export: true
        assign = TemporarAssigment.create left: tmp, right: node.local
        [assign, Export.create local: assign.left, alias: node.alias]

ExportRules.append WrapLiteralExports

WrapAnonymousFunctionExports = ^^BaseNode
WrapAnonymousFunctionExports <<<
    name: \WrapAnonymousFunctionExports
    match: ->
        if (fn = it.local)[type] == \Fun
        and fn.name?
            fn
    
    replace: (fn) ->
        [fn, Export.create local: Identifier.create fn{name}, exported: true]

ExportRules.append WrapAnonymousFunctionExports


ExpandObjectExports = ^^BaseNode
ExpandObjectExports <<<
    name: \ExpandObjectExports
    match: ->
        if (object = it.local)[type] == \Obj
            object.items
    replace: (items) ->
        items.map ({key,val}) -> Export.create local: val, alias: key
            
ExportRules.append ExpandObjectExports


SplitAssignExports = ^^BaseNode
SplitAssignExports <<<
    name: \SplitAssignExports
    copy: -> ^^@
    match: ->
        if(assign = it.local)[type] == \Assign
            {alias:it.alias,assign}
    replace: ({alias, assign}) ->
        identifier = Identifier.create name: assign.left.value, exported: true
        assign.left = identifier
        [assign, Export.create {local: assign.left, alias}]
    
    process: ->
        if matched = @match it
            @replace matched

ExportRules.append SplitAssignExports

InsertExportNodes =
    name: \InsertExportNodes
    match: (node)->
        if node[type] == \Cascade
        and node.input.value == \__es-export__
            node
    replace: (cascade) ->
        const {lines} = cascade.output
        if lines.length == 0
            throw Error "Empty export at #{cascade.line}:#{cascade.column}"
        lines.map -> Export.create local: it
    
    process: (value) ->
        if matched = @match value
            @replace matched
            
    copy: -> ^^@

AssignParent =
    name: \AssignParent
    match: (node) ->
        children-without-parent = node.get-children!filter -> not (it[parent]?)
        if children-without-parent.length
            node: node
            children: children-without-parent
    
    replace: ({node,children}) ->
        for child in children
            child[parent] = node
        node

AssignFilename =
    name: \AssignFilename
    match: (node) ->
        unless node.filename
            node
    
    replace: (node) ->
      node{filename} = node[parent]
      node

ExpandMetaImport = ^^BaseNode
ExpandMetaImport <<<
    name: \ExpandMetaImport
    match: (node) ->
        if node.all
            node
    
    replace: ({source,filename}: node) ->
        try
            unless filename
                throw Error "Meta-import requires filename property on Import nodes"
            export-resolver.resolve (convert-literal-to-string source), filename 
        catch
            if e.message.match /no such file/
                throw Error "Cannot meta-import module #{node.source.value} at #{node.line}:#{node.column} in #{node.filename}\nProbably mispelled module path"
            else
                throw e

ImportRules.append ExpandMetaImport

copy-source-location = (source, target) !->
    {line,column} = source
    unless line?
        line = 10000000000
        column = 10000000000
        children = source.get-children!
        for child in children
            line = Math.min line, child.line if child.line
            column = Math.min column, child.column if child.column
    target <<< {line,column}

ConditionalMutate = ^^BaseNode
ConditionalMutate <<<
    name: \ConditionalMutate
    test: -> true
    mutate: ->
    apply: (this-arg, args) !->
      if @test.apply this-arg, args
          @mutate.apply this-arg, args
          
    process: !->
        if @test ...&
            @mutate ...&

FilterAst = ^^BaseNode
FilterAst <<<
    test: -> true
    process: (ast-root, cross-scope-boundary) ->
        result = []
        walk = (node,parent,name,index) !~>
            if @test node
                result.push node
        ast-root.traverse-children walk
        result

ProcessArray = ^^BaseNode
ProcessArray <<<
    name: \ProcessArray
    each: ->
    process: ->
        for e in it
            @each.call null, e

RemoveNode = ^^BaseNode
RemoveNode <<<
    name: \RemoveNode
    process: (node) -> node.remove!
    process-array: (array) ->
        for e in array
            @process e

OnlyExports = ^^FilterAst
OnlyExports <<<
    name: \OnlyExports
    test: (.[type] == \Export)

OnlyImports = ^^FilterAst
OnlyImports <<<
    name: \OnlyImports
    test: (.[type] == Import[type])

RemoveNodes = ProcessArray.copy!
RemoveNodes <<<
    name: \RemoveNodes
    each: RemoveNode

MoveExportsToTop = ^^BaseNode
MoveExportsToTop <<<
    name: \MoveExportsToTop
    process: (ast-root) !->
        exports = OnlyExports.process ast-root
        RemoveNodes.process exports
        ast-root.exports = exports

is-expression = ->
    node = it
    result = false
    while (parent-node = node[parent]) and not result
        result = 
            parent-node[type] in <[ Arr ]>
            or (parent-node[type] == \Assign and parent-node.right == node)
        node = parent-node
    result

ReplaceImportWithTemporarVariable = BaseNode with
    name: \ReplaceImportWithTemporarVariable
    process: (_import) ->
        names = TemporarVariable.create name: \export, is-import: true
        _import.replace-with names
        _import.names = names

IfNode = ^^BaseNode
IfNode <<<
    name: \IfNode
    test: ->
    then: ->
    else: ->
    process: ->
        if @test ...&
        then @then ...&
        else @else ...&

RemoveOrReplaceImport = IfNode.copy!
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
    process: (ast-root) !->
        imports = OnlyImports.process ast-root
        RemoveOrReplaceImports.process imports
        ast-root.imports = imports

identifier-from-var = (some-var) ->
    Identifier.create name: some-var.value
        copy-source-location some-var, ..



ReplaceVariableWithIdentifier = ConditionalMutate.copy!
ReplaceVariableWithIdentifier <<<
    name: \ReplaceVariableWithIdentifier
    
    test: (context, node, parent, name, index) ->
        node[type] == \Assign
        and node.left[type] == \Var
        and context.exports-names.has node.left.value
    
    mutate: (context, node,parent,name,index) !->
        identifier = identifier-from-var node.left
        node.left.replace-with identifier


DisableImplicitExportVariableDeclaration =
    name: \DisableImplicitExportVariableDeclaration
    copy: -> ^^@
    replacer: ReplaceVariableWithIdentifier
    process: (ast-root) !->
        context = {}
        context.exports-names = exports-names = new Set
        for e in ast-root.exports when e.local.value
            exports-names.add e.local.value
        
        walk = (node,parent,name,index) !~>
            @replacer.process context, node,parent,name,index
        const cross-scope-boundary = false
        ast-root.traverse-children walk, cross-scope-boundary

export-resolver =
    livescript: null
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
        items = exports.map -> Identifier.create name: it.name.value
        Import.create do
            names: ObjectPattern.create {items}
            source: Literal.create value: "'#{module-path}'"



# livescript-ast-transform gives us install and uninstall methods
# also throws error with more meaningfull message if we forget implement
# 'enable' and 'disable' methods
Plugin = ^^livescript-ast-transform
    module.exports = ..

    ..name = 'transform-es-modules'
    
    ..install = (@livescript) !-> @enable!

    ..enable = !->
        original-tokenize = @livescript.lexer.tokenize
        original-lex = @livescript.lexer.lex
        export-resolver{livescript} = @
        @livescript.lexer.lex = ->
            result = []
            lexed = original-lex ...
            i = -1
            buffer = [lexed.0, lexed.1]
            
            while ++i < lexed.length     
                l = lexed[i]
                [,, ...rest] = l
                
                if l.0 == \DECL and l.1 == \export
                    result.push [\ID \__es-export__ ...rest]
                    if i + 2 < lexed.length
                    and lexed[i + 2].0 == \DEFAULT
                        result.push lexed[++i]
                        ++i # skip default
                        [,, ...rest] = l = lexed[i]
                        result.push [\ID \__es-export-default__ ...rest]
                else
                    result.push l
            result
        Nodelivescript = @livescript
        
        EnableExports = ConditionalNode.copy!
            ..condition.process = ->
                  it[type] == \Export
            ..next = ExportNodes = MatchMapCascadeNode.copy!
        
        EnableImports = ConditionalNode.copy!
            ..name = \Imports
            ..condition.process = ->
                  it[type] == Import[type]
            ..next = ImportRules
        ExportNodes
            ..append SplitAssignExports
            ..append ExpandArrayExports
            ..append EnableDefaultExports
            ..append WrapLiteralExports
            ..append WrapAnonymousFunctionExports
            ..append ExpandObjectExports
        @livescript.expand
            ..append InsertExportNodes
            ..append ConvertImports
            ..append EnableExports
            ..append EnableImports
        @livescript.postprocess-ast.append MoveExportsToTop
        @livescript.postprocess-ast.append MoveImportsToTop
        @livescript.postprocess-ast.append DisableImplicitExportVariableDeclaration
        simplified-compiler = @livescript.copy!
            ..expand.rules.find (.name == \Imports) .next.remove (.name == \ExpandMetaImport)
        export-resolver.livescript = simplified-compiler
        scope-patched = false

    ..disable = !->
        @livescript.ast.Fun::compile = @original-compile
