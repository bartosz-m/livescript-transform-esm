{ parent, type } = import \livescript-compiler/lib/livescript/ast/symbols

import
    \assert
    \fs
    \path
    \livescript-compiler/lib/core/components/Creatable
    \livescript-compiler/lib/composition : { import-properties }
    \livescript-compiler/lib/livescript/ast/Assign
    
    \livescript-compiler/lib/livescript/ast/Identifier
    
    \livescript-compiler/lib/livescript/ast/Literal
    \livescript-compiler/lib/livescript/ast/Node
    \livescript-compiler/lib/livescript/ast/ObjectPattern
    \livescript-compiler/lib/livescript/ast/Pattern
    \livescript-compiler/lib/livescript/ast/TemporarVariable
    \livescript-compiler/lib/livescript/Plugin
    \livescript-compiler/lib/nodes/MatchMapCascadeNode
    \livescript-compiler/lib/nodes/ConditionalNode
    \livescript-compiler/lib/nodes/IfNode
    \livescript-compiler/lib/nodes/identity
    \livescript-compiler/lib/nodes/TrueNode
    \livescript-compiler/lib/nodes/JsNode
    \livescript-compiler/lib/nodes/symbols : { copy, as-node }
    \livescript-compiler/lib/livescript/SourceNode
    \livescript-compiler/lib/core/symbols : {create, init}
    \./livescript/ast/Export
    \./livescript/ast/ReExport
    \./livescript/ast/Import
    \./nodes/MatchMap
    \./import-plugin
    \./dynamic-import-plugin

          
# Question unfold-soak, compile vs compile-node
# info scope.temporary

TemporarAssigment = ^^Node
    import-properties .., Creatable
TemporarAssigment <<<
    (type): \TemporarAssigment

    (init): (@{left,right}) !->

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

literal-to-string = -> it.value.substring 1, it.value.length - 1


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
        if it[type] == Export[type]
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

  
extract-name-from-source = ->
    it
    |> (.replace /'/gi,'')
    |> (.split path.sep)
    |> (.[* - 1])
    |> path.basename

ExpandArrayExports = ^^BaseNode
ExpandArrayExports <<<
    name: \ExpandArrayExports
    ast: {}
    match: ->
        if it.local[type] == \Arr
            it.local.items
    map: (items) ->
        items.map ~> @ast.Export[create] local: it

ExpandBlockExports = ^^BaseNode
ExpandBlockExports <<<
    name: \ExpandBlockExports
    ast: {}
    match: ->
        if it.local[type] == \Block
            lines: it.local.lines
            alias: it.alias
    map: ({lines, alias}) ->
        lines.map ~> @ast.Export[create] local: it, alias: alias


EnableDefaultExports = ^^BaseNode
EnableDefaultExports <<<
    name: \EnableDefaultExports
    ast: {}
    match: ->
        if (cascade = it.local)[type] == \Cascade
        and cascade.input[type] == \Var
        and cascade.input.value == \__es-export-default__
            cascade.output.lines.0
    map: (line) ->
        @ast.Export[create] local: line, alias: Identifier[create] name: \default


WrapLiteralExports = ^^BaseNode
WrapLiteralExports <<<
    name: \WrapLiteralExports
    ast: {}
    match: ->
        {local} = it
        Type = local[type]
        if Type == \Literal
        or (Type == \Fun and not local.name?)
        or (Type == \Class and not local.name?)
            it
    
    map: (node) ->
        tmp = TemporarVariable[create] name: \export, is-export: true
        assign = TemporarAssigment[create] left: tmp, right: node.local
        [assign, @ast.Export[create] local: assign.left, alias: node.alias]

WrapAnonymousFunctionExports = ^^BaseNode
WrapAnonymousFunctionExports <<<
    name: \WrapAnonymousFunctionExports
    ast: {}
    match: ->
        if (fn = it.local)[type] == \Fun
        and fn.name?
            fn
    
    map: (fn) ->
        [fn, @ast.Export[create] local: Identifier[create] fn{name}, exported: true]

ExpandObjectExports = ^^BaseNode
ExpandObjectExports <<<
    name: \ExpandObjectExports
    ast: {}
    match: ->
        if (object = it.local)[type] == \Obj
            object.items
    map: (items) ->
        items.map ({key,val}) ~>
          @ast.Export[create] local: val, alias: key

ExpandObjectPatternExports = ^^BaseNode
ExpandObjectPatternExports <<<
    name: \ExpandObjectExports
    ast: {}
    match: ->
        if (object = it.local)[type] == ObjectPattern[type]
            object.items
    map: (items) ->
        items.map ~>
          @ast.Export[create] local: it

SplitAssignExports = ^^BaseNode
SplitAssignExports <<<
    name: \SplitAssignExports
    ast: {}
    (copy): -> ^^@
    match: ->
        if(assign = it.local)[type] == \Assign
            {alias:it.alias,assign}
    map: ({alias, assign}) ->
        identifier = Identifier[create] name: assign.left.value, exported: true
        assign.left = identifier
        [assign, @ast.Export[create] {local: assign.left, alias}]
    
    exec: ->
        if matched = @match it
            @replace matched


InsertExportNodes =
    name: \InsertExportNodes
    ast: {}
    match: (node)->
        if node[type] == \Cascade
        and node.input.value == \__es-export__
            node
    map: (cascade) ->
        const {lines} = cascade.output
        if lines.length == 0
            throw Error "Empty export at #{cascade.line}:#{cascade.column}"
        lines.map ~> @ast.Export[create] local: it
    
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
    test: (.[type] in [Export[type]])

ExportsAndReExports = ^^FilterAst
ExportsAndReExports <<<
    name: \ExportsAndReExports
    test: (.[type] in [Export[type], ReExport[type]])

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

# TODO this should be ConditionalNode
ExtractExportNameFromAssign = ^^BaseNode
ExtractExportNameFromAssign <<<
    name: \ExtractExportNameFromAssign
    ast: {}
    (copy): -> ^^@
    match: ->
        if(assign = it.local)[type] == \Assign
        and not it.alias?
            {node:it,assign}

    map: ({node, assign}) ->
        node.alias = Identifier[create] name: assign.left.value, exported: true
    
    exec: ->
        exports = OnlyExports.exec it
        for e in exports
            if matched = @match e
                @map matched
                
        it

# TODO this should be ConditionalNode
ExtractExportNameFromLiteral = ^^BaseNode
ExtractExportNameFromLiteral <<<
    name: \ExtractExportNameFromLiteral
    ast: {}
    (copy): -> ^^@
    match: ->
        if(assign = it.local)[type] == \Literal
        and not it.alias?
            {node:it, name: literal-to-string it.local}

    map: ({node, name}) ->
        node.alias = Identifier[create] name: name
    
    exec: ->
        exports = OnlyExports.exec it
        for e in exports
            if matched = @match e
                @map matched
                
        it

ExtractNameFromClass = MatchMap[copy]!
ExtractNameFromClass <<<
    name: \ExtractNameFromClass
    ast: {}
    (copy): -> ^^@
    match: ->
        if(_class = it.local)[type] == \Class
        and not it.alias?
            {node:it, name: _class.title.value}

    map: ({node, name}) ->
        node
            ..alias = Identifier[create] {name}


ExtractExportNameFromImport = ^^MatchMap
ExtractExportNameFromImport <<<
    name: \ExtractExportNameFromImport
    ast: {}
    match: ->
        if(_import = it.local)[type] == Import[type]
        and _import.names?[type] in [\Literal \Identifier Literal[type]]
        and not it.alias?
            name = if _import.names.value then that else _import.names.name
            {name, _import}

    map: ({_import, name}) ->
        tmp = TemporarVariable[create] name: \import, is-import: true
        # assign = Assign[create] do
        #     left: tmp
        #     right: _import
        _import.names = tmp    
        _export = @ast.Export[create] do
            local: tmp #Identifier[create] name: name
            alias: Identifier[create] name: name
        [_import, _export]
        # name =  path.basename name.replace /'/gi ''
        # @ast.ReExport[create] do
        #     names: Identifier[create] {name}
        #     source: source

MoveExportsToTop = ^^BaseNode
MoveExportsToTop <<<
    name: \MoveExportsToTop
    exec: (ast-root) !->
        exports = OnlyExports.exec ast-root
        RemoveNodes.exec exports
        ast-root.exports = exports
        ast-root.is-module = ast-root.is-module or ast-root.exports.length != 0

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
        names = TemporarVariable[create] name: \import, is-import: true
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
    Identifier[create] name: some-var.value
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
        for e in ast-root.exports when e.local?value
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
        exports = @exports.map ~> sn it, (it.compile scope: @scope), '\n'
        get-variable-name = -> it.local.compile {}
        variables-to-declare = @exports
            .filter -> !it.local.is-import
            .map -> it.local
        exports-declaration = if variables-to-declare.length
        then "var #{variables-to-declare.map (.compile {}) .join ','};\n"
        else ""
        sn @, exports-declaration, ...exports, result

CheckIfOnlyDefaultExports = ^^BaseNode
CheckIfOnlyDefaultExports <<<
    name: \CheckIfOnlyDefaultExports
    exec: (ast-root) !->
        only-defaults = true
        for e in ast-root.exports
            only-defaults = only-defaults and e.default
        if only-defaults
            for e in ast-root.exports
                e.override-module = true

MarkAsScript = JsNode.copy!
MarkAsScript <<<
    name: \MarkAsScript
    js-function: (ast-root) !->
        Object.define-property ast-root, \isModule,
            configurable: true
            enumerable: true
            get: -> false
            set: !-> # value is immutable
        
        # sn @, exports-declaration, ...exports, result

AddImportsDeclarations = JsNode.copy!
    ..name = \AddImportsDeclarations
    ..js-function = (result) ->
        imports = @imports.map -> sn it, (it.compile {}), '\n'
        sn @, ...imports, result

export default TransformESM = ^^Plugin
TransformESM <<<
    name: 'transform-esm'
    
    config: {}

    enable: !->
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
                    else if l.0 == ":"
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
                    else if l.0 == \DECL and l.1 == \import
                    and i + 3 < lexed.length
                    and lexed[i + 1].0 == \INDENT
                    and lexed[i + 2].0 == \...
                    and lexed[i + 3].0 == \INDENT
                        [,, ...rest] = l
                        result.push [ \DECL \importAll ...rest ]
                        i++
                        result.push lexed[i]
                        i++ # INDENT
                    else
                        result.push l
                result
            
        @livescript.lexer.tokenize.append special-lex
        Nodelivescript = @livescript
        MyExport = Export[copy]!
        @livescript.ast.Export = MyExport
        @livescript.ast.ReExport = ReExport[copy]!
        
        assert MyExport[type]
        assert.equal MyExport[type], Export[type]
        EnableExports = ConditionalNode[copy]!
            ..condition = JsNode.new -> it[type] == Export[type]
            ..next = ExportNodes = MatchMapCascadeNode[copy]!
        
        ExportNodes
            ..append ExtractNameFromClass
            ..append ExpandArrayExports with @livescript{ast}
            ..append ExpandBlockExports with @livescript{ast}
            ..append EnableDefaultExports with @livescript{ast}
            ..append ExpandObjectExports with @livescript{ast}
            ..append ExpandObjectPatternExports with @livescript{ast}
            ..append ExtractExportNameFromImport with @livescript{ast}
        @livescript.expand
            ..append InsertExportNodes with @livescript{ast}
            ..append EnableExports
        @livescript.postprocess-ast
            ..append RegisterExportsOnRoot
        
        if @config.format != \cjs
            ExportNodes                
                ..append WrapLiteralExports with @livescript{ast}
                ..append WrapAnonymousFunctionExports with @livescript{ast}
                ..append SplitAssignExports with @livescript{ast}
            @livescript.postprocess-ast
                ..append MoveExportsToTop
                ..append DisableImplicitExportVariableDeclaration
            @livescript.ast.Block.Compile.append AddExportsDeclarations
        else
            @livescript.postprocess-ast
                ..append ExtractExportNameFromAssign
                ..append ExtractExportNameFromLiteral
                ..append CheckIfOnlyDefaultExports
                ..append MarkAsScript
            MyExport.compile[as-node].js-function = (o) ->
                name = @name.compile o
                inner = (@local.compile o)
                wrap-default = -> if it == "'default'" then "Symbol.for('default.module')" else it
                # property = if 'default' in @name<[name value]>
                property = if @default
                    then "['__default__']"
                    else if @name.reserved
                        then "[#{@name.compile o}]"
                        else ".#{name}"
                if @override-module
                    named-default-export = if @local[type] == \Literal
                        then []
                        else [@terminator, "\n", o.indent, "Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports})"]
                    @to-source-node parts: [ "module.exports = " , inner, ...named-default-export ] 
                else
                    @to-source-node parts: [ "exports#{property} = " , inner, ]
                
        
        
        @livescript.ast.Block.Compile.append AddImportsDeclarations
        import-plugin.install @livescript, @config
        dynamic-import-plugin.install @livescript, @config
        
            