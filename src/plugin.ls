require! <[ assert source-map livescript-ast-transform livescript ]>
{ SourceNode } = source-map
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
}

sn = (node = {}, ...parts) ->
    try
        result = new SourceNode node.line, node.column, null, parts
        result.display-name = node[type]
        result
    catch e
        console.dir parts
        throw e


          
          
# Question unfold-soak, compile vs compile-node
# info scope.temporary


Prototype = Symbol \prototype
Temporary = Symbol \scope::temporary
Variables = Symbol \scope::variables

TemporarVariable = ^^Node
    import-properties .., Creatable
TemporarVariable <<<    
    (type): \TemporarVariable
    
    init: (@{name,is-export}) !->
      
    traverse-children: (visitor, cross-scope-boundary) ->
    
    compile: (o) ->
        @temporary-name ?= o.scope.temporary @name
        if @is-export
            o.scope?variables["#{@temporary-name}."] = 'DONT TOUTCH'
        sn @, @temporary-name
  

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
        sn @, (@left.compile o), ' = ' @right.compile o

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

fixes =
    livescript:
        ast :
            entries:
                assign-type: ([class-name, _class]) ->
                    if _class::
                        _class::[type] = class-name
                
            values:
                add-method-replace-with: ->
                    unless it{}::replace-with
                        it::replace-with = Node.replace-with
                    it
                      
                add-method-get-children: (Class) ->
                    unless Class{}::get-children
                        Class::get-children = Node.get-children
                add-replace-child-method: (Class) ->
                    unless Class::replace-child?
                        if Class::[type] == \Block
                            Class::replace-child = (child, ...nodes) ->
                                idx = @lines.index-of child
                                unless idx > -1
                                    throw Error "Trying to replace node witch is not child of current node"
                                unless nodes.length
                                    throw Error "Replace called without nodes"
                                @lines.splice idx, 1, ...nodes
                                for node in nodes
                                    node[parent] = @
                                child
                        else if Class::[type] == \Assign
                            Class::replace-child = (child, ...nodes) ->
                                if nodes.length != 1 
                                    throw new Error "Cannot replace child of assign with #{nodes.length} nodes."
                                [new-node] = nodes
                                if @left == child
                                    @left = new-node
                                else if @right == child
                                    @right = new-node
                                else
                                  throw new Error "Node is not child of Assign"
                        else
                            Class::replace-child = Node.replace-child
                add-remove-child-method: (Class) ->
                    unless Class::remove-child?
                        if Class::[type] == \Block
                            Class::remove-child = (child) ->
                                idx = @lines.index-of child
                                unless idx > -1
                                    throw Error "Trying to replace node witch is not child of current node"
                                @lines.splice idx, 1
                                child
                        else
                            Class::remove-child = Node.remove-child

flatten = (arr) ->
    result = []
    arr.for-each ->
        if Array.is-array it
            result.push ...it
        else
            result.push it
    result

as-array = ->
    if Array.is-array it
    then it
    else [it]

convert-literal-to-string = -> it.value.substring 1, it.value.length - 1
camelize = (.replace /-[a-z]/ig -> it.char-at 1 .to-upper-case!)

CascadeRule =
    append: (rule) ->
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

ImportRules = ^^CascadeRule
ImportRules <<<
    name: \Import
    rules: []
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

OriginalImports = ^^CascadeRule
OriginalImports <<<
    name: \Import
    rules: []
    match: ->
        if it[type] == \Import
        and it.left.value == 'this'
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

ConvertImports = 
    name: \ConvertImports
    match: ->
        source: it.right
        all: it.all
    
    replace: ({all,source}) ->
        Import.create {all,source}

OriginalImports.append ConvertImports
      

ExtractNamesFromSource =
    name: \ExtractNamesFromSource
    match: ->
        if not it.names
        and value = it.source.value
            node: it
            names: path.basename value.replace /\'/gi, ''
    replace: ({node,names}) ->
        node.names = Identifier.create name: names
        node
  
ImportRules.append ExtractNamesFromSource

ExpandObjectImports =
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

ConvertImportsObjectNamesToPatterns =
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

ExpandArrayImports =
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

ExpandArrayExports =
    name: \ExpandArrayExports
    match: ->
        if it.local[type] == \Arr
            it.local.items
    replace: (items) ->
        items.map -> Export.create local: it

ExportRules.append ExpandArrayExports

EnableDefaultExports =
    name: \EnableDefaultExports
    match: ->
        if (cascade = it.local)[type] == \Cascade
        and cascade.input[type] == \Var
        and cascade.input.value == \__es-export-default__
            cascade.output.lines.0
    replace: (line) ->
        Export.create local: line, alias: Identifier.create name: \default

ExportRules.append EnableDefaultExports

WrapLiteralExports =
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

WrapAnonymousFunctionExports =
    name: \WrapAnonymousFunctionExports
    match: ->
        if (fn = it.local)[type] == \Fun
        and fn.name?
            fn
    
    replace: (fn) ->
        [fn, Export.create local: Identifier.create fn{name}, exported: true]

ExportRules.append WrapAnonymousFunctionExports


ExpandObjectExports =
    name: \ExpandObjectExports
    match: ->
        if (object = it.local)[type] == \Obj
            object.items
    replace: (items) ->
        items.map ({key,val}) -> Export.create local: val, alias: key
            
ExportRules.append ExpandObjectExports


SplitAssignExports =
    name: \SplitAssignExports
    match: ->
        if(assign = it.local)[type] == \Assign
            {alias:it.alias,assign}
    replace: ({alias, assign}) ->
        identifier = Identifier.create name: assign.left.value, exported: true
        assign.left = identifier
        [assign, Export.create {local: assign.left, alias}]

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

ExpandMetaImport =
    name: \ExpandMetaImport
    match: (node) ->
        if node.all
            node
    
    replace: (node) ->
        try
            export-resolver.resolve (convert-literal-to-string node.source), node.filename 
        catch
            if e.message.match /no such file/
                throw Error "Cannot meta-import module #{node.source.value} at #{node.line}:#{node.column} in #{node.filename}\nProbably mispelled module path"

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

expand-engine = 
    append-rule: (rule) !->
        unless rule.name
            throw new Error "Adding rule without a name is realy bad practice"
        @rules.push rule
      
    rules: [
    ]
    process: (ast-root) !->
        changed = false
        to-process = [ast-root]
        while to-process.length
            changed = false
            processing = to-process
            to-process = []
            for node in processing
                for rule in @rules when m = rule.match node
                    new-nodes = as-array rule.replace m
                    unless new-nodes.length == 1 
                    and new-nodes.0 == node
                        for n in new-nodes
                            copy-source-location node, n
                        node.replace-with ...new-nodes
                    changed = true
                    break
            if changed
                to-process.push ast-root
            else
                to-process.push ...flatten processing.map ->
                    it.get-children!
expand-engine
    ..append-rule AssignParent
    ..append-rule AssignFilename
    ..append-rule InsertExportNodes
    ..append-rule ExportRules                 
    ..append-rule OriginalImports                 
    ..append-rule ImportRules                 

MoveExportsToTop =
    process: (ast-root) !->
        exports = []
        walk = (node,parent,name,index) !->
            if node[type] == \Export
                exports.push node
        ast-root.traverse-children walk
        for _export in exports
            _export.remove!
        ast-root.exports = exports

MoveImportsToTop =
    process: (ast-root) !->
        imports = []
        walk = (node,parent,name,index) !->
            if node[type] == Import[type]
                imports.push node
        ast-root.traverse-children walk
        for _import in imports
            _import.remove!
        ast-root.imports = imports

identifier-from-var = (some-var) ->
    Identifier.create name: some-var.value
        copy-source-location some-var, ..


DisableImplicitExportVariableDeclaration =
    process: (ast-root) !->
        imports = []
        exports-names = new Set
        for e in ast-root.exports when e.local.value
            exports-names.add e.local.value
        
        walk = (node,parent,name,index) !->
            if node[type] == \Assign
            and node.left[type] == \Var
            and exports-names.has node.left.value
                identifier = identifier-from-var node.left
                node.left.replace-with identifier
            # if node[type] == \Var
            # and exports-names.has node.value
            #     identifier = identifier-from-var node
            #     node.replace-with identifier
        const cross-scope-boundary = false
        ast-root.traverse-children walk, cross-scope-boundary
  
second-stage-engine =
    mutators: [
        MoveExportsToTop
        MoveImportsToTop
        DisableImplicitExportVariableDeclaration
    ]
    process: (ast-root) ->
        for mutator in @mutators
            mutator.process ast-root
            
compiler =
    livescript: null
    ast: (code, options) ->
        unless options.filename
            throw Error "One of rules requires options.filename to be set"
        ast-root = @livescript.ast code
        ast-root.filename = options.filename
        expand-engine.process ast-root
        second-stage-engine.process ast-root
        ast-root

export-resolver-stage0 =
    remove-rule: (rule) !->
        if idx = @rules.index-of rule
            @rules.splice idx,1
    append-rule: (rule) !->
        unless rule.name
            throw new Error "Adding rule without a name is realy bad practice"
        @rules.push rule
      
    rules: Array.from expand-engine.rules
    process: (ast-root) !->
        changed = false
        to-process = [ast-root]
        while to-process.length
            changed = false
            processing = to-process
            to-process = []
            for node in processing
                for rule in @rules when m = rule.match node
                    new-nodes = as-array rule.replace m
                    unless new-nodes.length == 1 
                    and new-nodes.0 == node
                        for n in new-nodes
                            copy-source-location node, n
                        node.replace-with ...new-nodes
                    changed = true
                    break
            if changed
                to-process.push ast-root
            else
                to-process.push ...flatten processing.map ->
                    it.get-children!

export-resolver-stage0.remove-rule ExpandMetaImport

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
        ast-root = @livescript.ast code
        ast-root.filename = resolved-path
        export-resolver-stage0.process ast-root
        second-stage-engine.process ast-root
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

    ..enable = !->
        original-tokenize = @livescript.lexer.tokenize
        export-resolver{livescript} = @
        @livescript.lexer.tokenize = ->
            result = []
            lexed = original-tokenize ...
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
        { Block } = @livescript.ast
        original-compile-root = Block::compile-root
        Self = @
        for own k,v of @livescript.ast
            for own ,fix of fixes.livescript.ast.entries
                fix [k,v]
            for own ,fix of fixes.livescript.ast.values
                fix v
        Nodelivescript = @livescript
        Block::compile-root = (o) ->
            ast-root = @
            ast-root.filename = o.filename
            ast-root.is-root = true
            expand-engine.process ast-root
            second-stage-engine.process ast-root
            non-default-exports = ast-root.exports#.filter -> not it.default
            
            
            result = original-compile-root ...
            
            # third-stage can access scope
            exports = ast-root.exports.map -> sn it, (it.compile o), '\n'
            imports = ast-root.imports.map -> sn it, (it.compile o), '\n'
            
            get-variable-name = ->
                it.local.compile {}
            exports-declaration = if non-default-exports.length
            then "var #{non-default-exports.map get-variable-name .join ','};\n"
            else ""
            sn ast-root, ...imports, exports-declaration, ...exports, result
        original-compile-with-declarations = Block::compile-with-declarations
        scope-patched = false

    ..disable = !->
        @livescript.ast.Fun::compile = @original-compile
