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
    \./livescript/ast/TemporarVariable
    \./livescript/Plugin
    \./nodes/MatchMapCascadeNode
    \./nodes/ConditionalNode
    \./nodes/IfNode
    \./nodes/identity
    \./nodes/TrueNode
    \./nodes/JsNode
    \./nodes/symbols : { copy, as-node }
    \./livescript/SourceNode
    \./import-plugin
}
          
# Question unfold-soak, compile vs compile-node
# info scope.temporary

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


BaseNode = ^^null
BaseNode <<< 
    name: \BaseNode
    copy: -> ^^@
    (copy): -> ^^@
    remove: -> throw Error "Unimplemented method remove in #{@name}"
    call: (, ...args)-> @exec ...args
    apply: (,args)-> @exec ...args

CascadeRule =
    append: (rule) ->
        unless rule.copy
              throw new Error "Creating node #{rule.name ? ''} without copy method is realy bad practice"
        unless rule.name
            throw new Error "Adding rule without a name is realy bad practice"
        @rules.push rule
    
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
    map: ({rule,matched}) ->
        replacer = rule.replace matched
        as-array replacer

ConvertImports = ^^BaseNode
ConvertImports <<<
    name: \ConvertImports
    match: ->
        if it[type] == \Import
        and it.left.value == 'this'
            source: it.right
            all: it.all
    
    map: ({all,source}) ->
        Import.create {all,source}
        
    exec: ->
        if matched = @match it
            @replace matched
    
    copy: ->
        ^^@
  
extract-name-from-source = ->
    it
    |> (.replace /'/gi,'')
    |> (.split path.sep)
    |> (.[* - 1])
    |> path.basename

ExpandArrayExports = ^^BaseNode
ExpandArrayExports <<<
    name: \ExpandArrayExports
    Export: Export
    match: ->
        if it.local[type] == \Arr
            it.local.items
    map: (items) ->
        items.map ~> @Export.create local: it

ExportRules.append ExpandArrayExports

EnableDefaultExports = ^^BaseNode
EnableDefaultExports <<<
    name: \EnableDefaultExports
    Export: Export
    match: ->
        if (cascade = it.local)[type] == \Cascade
        and cascade.input[type] == \Var
        and cascade.input.value == \__es-export-default__
            cascade.output.lines.0
    map: (line) ->
        @Export.create local: line, alias: Identifier.create name: \default

ExportRules.append EnableDefaultExports

WrapLiteralExports = ^^BaseNode
WrapLiteralExports <<<
    name: \WrapLiteralExports
    Export: Export
    match: ->
        {local} = it
        Type = local[type]
        if Type == \Literal
        or (Type == \Fun and not local.name?)
        or (Type == \Class and not local.name?)
            it
    
    map: (node) ->
        tmp = TemporarVariable.create name: \export, is-export: true
        assign = TemporarAssigment.create left: tmp, right: node.local
        [assign, @Export.create local: assign.left, alias: node.alias]

ExportRules.append WrapLiteralExports

WrapAnonymousFunctionExports = ^^BaseNode
WrapAnonymousFunctionExports <<<
    name: \WrapAnonymousFunctionExports
    Export: Export
    match: ->
        if (fn = it.local)[type] == \Fun
        and fn.name?
            fn
    
    map: (fn) ->
        [fn, @Export.create local: Identifier.create fn{name}, exported: true]

ExportRules.append WrapAnonymousFunctionExports


ExpandObjectExports = ^^BaseNode
ExpandObjectExports <<<
    name: \ExpandObjectExports
    Export: Export
    match: ->
        if (object = it.local)[type] == \Obj
            object.items
    map: (items) ->
        items.map ({key,val}) ~> @Export.create local: val, alias: key
            
ExportRules.append ExpandObjectExports


SplitAssignExports = ^^BaseNode
SplitAssignExports <<<
    name: \SplitAssignExports
    Export: Export
    (copy): -> ^^@
    match: ->
        if(assign = it.local)[type] == \Assign
            {alias:it.alias,assign}
    map: ({alias, assign}) ->
        identifier = Identifier.create name: assign.left.value, exported: true
        assign.left = identifier
        [assign, @Export.create {local: assign.left, alias}]
    
    exec: ->
        if matched = @match it
            @replace matched

ExportRules.append SplitAssignExports

InsertExportNodes =
    name: \InsertExportNodes
    Export: Export
    match: (node)->
        if node[type] == \Cascade
        and node.input.value == \__es-export__
            node
    map: (cascade) ->
        const {lines} = cascade.output
        if lines.length == 0
            throw Error "Empty export at #{cascade.line}:#{cascade.column}"
        lines.map ~> @Export.create local: it
    
    exec: (value) ->
        if matched = @match value
            @map matched
            
    (copy): -> ^^@

AssignParent =
    name: \AssignParent
    match: (node) ->
        children-without-parent = node.get-children!filter -> not (it[parent]?)
        if children-without-parent.length
            node: node
            children: children-without-parent
    
    map: ({node,children}) ->
        for child in children
            child[parent] = node
        node

AssignFilename =
    name: \AssignFilename
    match: (node) ->
        unless node.filename
            node
    
    map: (node) ->
      node{filename} = node[parent]
      node

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
    test: TrueNode
    mutate: identity
    apply: (this-arg, args) !->
      if @test.apply this-arg, args
          @mutate.apply this-arg, args
          
    exec: !->
        if @test ...&
            @mutate ...&

FilterAst = ^^BaseNode
FilterAst <<<
    test: -> true
    exec: (ast-root, cross-scope-boundary) ->
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
    exec: ->
        for e in it
            @each.call null, e

RemoveNode = ^^BaseNode
RemoveNode <<<
    name: \RemoveNode
    exec: (node) -> node.remove!
    exec-array: (array) ->
        for e in array
            @exec e

OnlyExports = ^^FilterAst
OnlyExports <<<
    name: \OnlyExports
    test: (.[type] == \Export)

RemoveNodes = ProcessArray.copy!
RemoveNodes <<<
    name: \RemoveNodes
    each: RemoveNode

RegisterExportsOnRoot = ^^BaseNode
RegisterExportsOnRoot <<<
    name: \RegisterExportsOnRoot
    exec: (ast-root) !->
        exports = OnlyExports.exec ast-root
        ast-root.exports = exports

MoveExportsToTop = ^^BaseNode
MoveExportsToTop <<<
    name: \MoveExportsToTop
    exec: (ast-root) !->
        exports = OnlyExports.exec ast-root
        RemoveNodes.exec exports
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
    exec: (_import) ->
        names = TemporarVariable.create name: \import, is-import: true
        _import.replace-with names
        _import.names = names

RemoveOrReplaceImport = IfNode[copy]!
RemoveOrReplaceImport <<<
    name: \RemoveOrReplaceImport
    test: is-expression
    then: ReplaceImportWithTemporarVariable
    else: RemoveNode

RemoveOrReplaceImports = ^^ProcessArray
    ..name = \RemoveOrReplaceImports
    ..each = RemoveOrReplaceImport


identifier-from-var = JsNode.new (some-var) ->
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
        identifier = identifier-from-var.exec node.left
        node.left.replace-with identifier


DisableImplicitExportVariableDeclaration =
    name: \DisableImplicitExportVariableDeclaration
    copy: -> ^^@
    (copy): -> ^^@
    replacer: ReplaceVariableWithIdentifier
    call: (this-arg, ...args)-> @exec ...args
    exec: (ast-root) !->
        context = {}
        context.exports-names = exports-names = new Set
        for e in ast-root.exports when e.local.value
            exports-names.add e.local.value
        
        walk = (node,parent,name,index) !~>
            @replacer.exec context, node,parent,name,index
        const cross-scope-boundary = false
        ast-root.traverse-children walk, cross-scope-boundary
            
sn = (node = {}, ...parts) ->
    try
        result = new SourceNode node.line, node.column, null, parts
        result.display-name = node[type]
        result
    catch e
        console.dir parts
        throw e

AddExportsDeclarations = JsNode.copy!
    ..name = \AddExportsDeclarations
    ..js-function = (result) ->
        exports = @exports.map -> sn it, (it.compile {}), '\n'
        get-variable-name = -> it.local.compile {}
        exports-declaration = if exports.length
        then "var #{@exports.map get-variable-name .join ','};\n"
        else ""
        sn @, exports-declaration, ...exports, result

AddImportsDeclarations = JsNode.copy!
    ..name = \AddImportsDeclarations
    ..js-function = (result) ->
        imports = @imports.map -> sn it, (it.compile {}), '\n'
        sn @, ...imports, result

TransformESM = ^^Plugin
    module.exports = ..

    ..name = 'transform-esm'
    
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
            
        @livescript.lexer.tokenize.append special-lex
        Nodelivescript = @livescript
        
        # MyExport = Export[copy]!
        
        EnableExports = ConditionalNode[copy]!
            ..condition = JsNode.new -> it[type] == \Export
            ..next = ExportNodes = MatchMapCascadeNode[copy]!
        
        ExportNodes
            ..append SplitAssignExports
            ..append ExpandArrayExports
            ..append EnableDefaultExports
            ..append WrapLiteralExports
            ..append WrapAnonymousFunctionExports
            ..append ExpandObjectExports
        @livescript.expand
            ..append InsertExportNodes
            ..append EnableExports
        @livescript.postprocess-ast.append RegisterExportsOnRoot
        unless @config.format == \cjs
            @livescript.postprocess-ast.append MoveExportsToTop
            @livescript.postprocess-ast.append DisableImplicitExportVariableDeclaration
            @livescript.ast.Block.Compile.append AddExportsDeclarations
        # else
        #     Export.compile[as-node].js-function = (o) ->
        #         name = @name.compile o
        #         inner = (@local.compile o)
        #         @to-source-node parts: [ "exports.#{name} = " , inner, ]
                
        
        @livescript.ast.Block.Compile.append AddImportsDeclarations
        import-plugin.install @livescript, @config
        
            