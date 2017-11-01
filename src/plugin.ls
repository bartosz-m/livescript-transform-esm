require! <[ assert stream source-map livescript-ast-transform livescript ./livescript/ast/Node ./selectors/selectors ]>
{ Duplex } = stream
{ SourceNode } = source-map
{ parent, type } = require \./livescript/ast/symbols

require! {
    \./components/core/Creatable
    \./composition : { import-properties }
    \./streams/symbols : { pipe }
    \./streams : { ArraySink, CascadeStream, ComposedStream, DuplexStream, FilterStream, ForkStream, MergeStream, Sink, SyncSink, TransformStream }
}

BooleanSpliter = ^^ForkStream
BooleanSpliter <<<
    routes: [true, false]
    init: (arg) !->
        ForkStream.init.call @, arg with {route: arg.check}

Helper =
    filter: (...filters) ->
        streams = filters.map ~> FilterStream.create filter: it
        CascadeStream.create { streams }
            @[pipe] ..
        
    map: (...transforms) ->
        if transforms.length == 1
            TransformStream.create { transform: transforms.0 }
                @[pipe] ..
        else
            streams = transforms.map ~> TransformStream.create transform: it
            CascadeStream.create { streams }
                @[pipe] ..
    
    merge: (...streams) ->
        MergeStream.create streams: [@, ...streams]
        
    series: (...streams) ->
        CascadeStream.create { streams }
            @[pipe] ..
            
    sync: !-> @to-array!
        
    to-array: ->
        result = ArraySink.create!
            @[pipe] ..
        result.value
            
for Type in [CascadeStream, ComposedStream, DuplexStream, TransformStream]
    Type <<< Helper

# tests
do !->
    input = [1 2 3 4 5]
    stream = DuplexStream.create!
    output = stream.to-array!
    input.for-each stream~push
    assert Array.is-array output, 'output is array'
    assert.deep-equal output, input
do !->
    input = [1 2 3 4 5]
    stream = DuplexStream.create!
    tstream = stream.map (* 2)
    output = tstream.to-array!
    input.for-each stream~push
    assert Array.is-array output, 'output is array'
    assert.deep-equal output, [ 2 4 6 8 10 ]

do !->
    input = [1 2 3 4 5]
    stream = DuplexStream.create!
    tstream = stream.filter -> it % 2 == 0
    output = tstream.to-array!
    input.for-each stream~push
    assert Array.is-array output, 'output is array'
    assert.deep-equal output, [ 2 4 ]    

do !->
    input = [1 2 3 4 5]
    stream = DuplexStream.create!
    spliter = BooleanSpliter.create check: -> it % 2 == 0
    stream[pipe] spliter
    output = spliter.outputs.true.to-array!
    input.for-each stream~push
    assert Array.is-array output, 'output is array'
    assert.deep-equal output, [ 2 4 ]    
    


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

array-join = (array, separator) ->
  result = []
  if array.length
      for i til array.length - 1
          result.push array[i], separator
      result.push array[* - 1]
  result
  

class Variable
    (@{name,storage=\var,exported=false}) !->
      
    (type): \Variable
      
    @from-ast-node = ->
        storage = if it@@name == \Var
            then \var
            else throw Error "Unsupported storage type #{it@@name}"
        new Variable {name: it.value, storage}
    
    compile-as-expression: ->
        if @value?
            "#{@name} = #{@value}"
        else
            @name

class Constant
    (@{name,value,exported=false}) !->
      
    (type): \Constant
      
    storage: \const
    
    terminator: ';'
      
    compile: (o) ->
        if @exported
            sn @{line,column}, 'const export ', @name, ' = ', @value, @terminator
        else
            sn @{line,column}, 'const ', @name, ' = ', @value, @terminator
    
    compile-as-expression: -> "#{@name} = #{@value}"
      
    @from-ast-node = ->
        new Constant {name: it.left.value, value:it.right.value}
            .. <<< it{line,column}

Prototype = Symbol \prototype
Temporary = Symbol \scope::temporary
Variables = Symbol \scope::variables

extendable-function = (fn) ->
    let extensions = {original:fn, overrides: [], preprocessors: [], postprocessors: []}
        extended-fn = ->
            for preprocessor in extensions.preprocessors
                preprocessor ...
            for override in extensions.overrides
                if result = (override ...)
                    break
            unless result != void
                result = extensions.original ...
            for postprocessor in extensions.postprocessors
                result = postprocessor.apply @, [result, ...&]
            result
        extended-fn
            .. <<< {extensions}
    

Export = ^^Node
    import-properties .., Creatable
Export <<<
    (type): \Export
    init: (@{local, alias}) ->
      
    traverse-children: (visitor, cross-scope-boundary)->
        visitor @local, @, \local
        visitor @alias, @, \alias if @alias
        @local.traverse-children ...&
        @alias.traverse-children ...& if @alias
        
    
    compile: (o) ->
        alias =
            if @alias
                if  @alias.name != \default
                then [" as ", (@alias.compile o )]
                else [" as default" ]
            else []
        inner = (@local.compile o)
        sn @local, "export { ", inner, ...alias, " }"

    terminator: ';'
    
    local:~
        -> @_local
        (v) ->
            v[parent] = @
            @_local = v
            

DefaultExport = ^^Export
DefaultExport <<<
    (type): \DefaultExport
    
    init: (@{local}) !->
      
    traverse-children: (visitor, cross-scope-boundary) ->
        visitor @local, @, \local
        @local.traverse-children ...&
    
    compile: extendable-function (o) ->
        inner = (@local.compile o)
        sn @local, "export default ", inner
    
    terminator:~
        -> @local.terminator

TemporarVariable = ^^Node
    import-properties .., Creatable
TemporarVariable <<<    
    (type): \TemporarVariable
    
    init: (@{name}) !->
      
    traverse-children: (visitor, cross-scope-boundary) ->
    
    compile: (o) ->
        @temporary-name ?= o.scope.temporary @name
        sn @, @temporary-name
    
Identifier = ^^Node
    import-properties .., Creatable
Identifier <<<    
    (type): \Identifier
    
    init: (@{name}) !->
      
    traverse-children: (visitor, cross-scope-boundary) ->
    
    compile: (o) ->
        sn @, @name

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

assert DefaultExport instanceof Export
assert DefaultExport instanceof Node





as-array = ->
    if Array.is-array it
    then it
    else [ it ]

line-to-export = (cascade) ->
    const {input, {lines}: output} = cascade
    if lines.length == 0
        throw Error "Empty export at #{cascade.line}:#{cascade.column}"
    lines.map -> Export.create local: it


replace-nodes = (to-replace) !->
    to-replace.for-each ({original,transformed}) !->
        original.replace ...transformed

        
insert-export-nodes = ->
    TransformStream.create transform: (node) -> as-array line-to-export node

expand-array-exports = ->
    if-array-exports = BooleanSpliter.create check: (.local[type] == \Arr)
    
    expand-array-exports = if-array-exports.outputs.true.map (node) ->
        assert node.local[type] == \Arr
        node.local.items.map -> Export.create local: it
    
    transformed = expand-array-exports.merge if-array-exports.outputs.false
    
    ComposedStream.create input: if-array-exports, output: transformed

enable-default-exports = ->
    if-export-with-default = BooleanSpliter.create check: ->
        it.local[type] == \Cascade
        and it.local.input[type] == \Var
        and it.local.input.value == \__es-export-default__
        
    extract-export-target = if-export-with-default.outputs.true.map (node) ->
        {input,output} = node.local 
        unless output[type] == \Block
            throw Error "Expected Block at #{output.line} but found #{output@@name}"
        unless output.lines.length == 1
            throw Error "Expected exacly one line in default export at #{output.line} but found #{output.lines.length}"
        output.lines.0
        
    mark-as-default = extract-export-target.map (node) ->
        Export.create local: node, alias: Identifier.create name: \default
    
    transformed = mark-as-default.merge if-export-with-default.outputs.false
    ComposedStream.create input: if-export-with-default, output: transformed


enable-literal-exports = ->
    if-anonymous-export = BooleanSpliter.create check: ->
        unless it.local?
            console.warn "missing .local"
        it.local?[type] == \Literal
        or (it.local?[type] == \Fun and not it.local.name?)
        or (it.local?[type] == \Class and not it.local.name?)
    
    create-temporary-variable = TransformStream.create!
        ..transform = (node) ->
            tmp = TemporarVariable.create name: \export
            assign = TemporarAssigment.create left: tmp, right: node.local
            [assign, Export.create local: assign.left, alias: node.alias]
    
    if-anonymous-export.outputs.true[pipe] create-temporary-variable
    
    transformed = MergeStream.create streams: [
        create-temporary-variable,
        if-anonymous-export.outputs.false
    ]
    ComposedStream.create input: if-anonymous-export, output: transformed
    
enable-anonymous-function-exports = ->
    if-literal-export = BooleanSpliter.create check: ->
        it.local?[type] == \Fun and it.local.name?
    
    create-temporary-variable = TransformStream.create!
        ..transform = (node) ->
            [node.local, Export.create local: Identifier.create node.local{name}]
    
    if-literal-export.outputs.true[pipe] create-temporary-variable
    
    transformed = MergeStream.create streams: [
        create-temporary-variable,
        if-literal-export.outputs.false
    ]
    ComposedStream.create input: if-literal-export, output: transformed

enable-object-exports = (livescript) ->
    if-object-export = BooleanSpliter.create check: ->
        it.local?[type] == \Obj
    
    expand-object-exports = TransformStream.create!
        ..transform = (node) ->
            {items} = node.local
            items.map ({key,val}) -> Export.create local: val, alias: key
    
    if-object-export.outputs.true[pipe] expand-object-exports
    
    transformed = MergeStream.create streams: [
        expand-object-exports,
        if-object-export.outputs.false
    ]
    ComposedStream.create input: if-object-export, output: transformed

enable-assign-exports = ->
    if-assign-exports = BooleanSpliter.create check: (.local?[type] == \Assign)
    
    extract-assigns = TransformStream.create!
        ..transform = (node) ->
            assign = node.local
            [assign, Export.create local: assign.left]
    
    if-assign-exports.outputs.true[pipe] extract-assigns
    
    transformed = MergeStream.create streams: [
        extract-assigns,
        if-assign-exports.outputs.false
    ]
    ComposedStream.create input: if-assign-exports, output: transformed

stream-object-entries = (object) ->
    result = DuplexStream.create!
    for own k,v of object
        result.push [k,v]
    result

stream-object-values = (object) ->
    result = DuplexStream.create!
    for own k,v of object
        result.push v
    result

every-ast-node = ->
    walker = TransformStream.create transform: (node) ->
        let output = DuplexStream.create!
            output.push {node,parent: null}
            walk-ast = (node, parent, name, index) !->
                output.push {node,parent,name,index}
        
            # console.log \walking node
        
            node.traverse-children walk-ast
            output
    walker
    
assign-parent-return-as-node = ->
    TransformStream.create transform: ->
        it.node[parent] = it.parent
        it.node

assign-type = ->
    TransformStream.create transform: ->
        unless it[type]
            it-prototype = Object.get-prototype-of it
            it-prototype[type] = it@@display-name ? it@@name
                console.log "setting type" ..
        it

add-replace-with-method = ->
    TransformStream.create transform: ->
        unless it.replace-with
            it-prototype = Object.get-prototype-of it
            it-prototype.replace-with = Node.replace-with
        it

add-replace-child-method = ->
    TransformStream.create transform: ->
        unless it.replace-child?
            it-prototype = Object.get-prototype-of it
            if it[type] == \Block
                it-prototype.replace-child = (child, ...nodes) ->
                    idx = @lines.index-of child
                    unless idx > -1
                        throw Error "Trying to replace node witch is not child of current node"
                    unless nodes.length
                        throw Error "Replace called without nodes"
                    @lines.splice idx, 1, ...nodes
                    for node in nodes
                        node[parent] = @
                    child
            else
                it-prototype.replace-child = (child, ...nodes) -> ...
        it


fixes =
    livescript:
        ast :
            entries:
                assign-type: ([class-name, _class]) ->
                    console.log class-name
                    _class::[type] = class-name
            values:
                add-method-replace-with: ->
                    unless it::replace-with
                        it::replace-with = Node.replace-with
                    it
                      
util =
    inject-output: (stream, injected) ->
        output = stream.output
        stream.output = injected
        injected.output = output

LogNode = TransformStream.create transform: ->
    console.log \log it[type]
    it
# livescript-ast-transform gives us install and uninstall methods
# also throws error with more meaningfull message if we forget implement
# 'enable' and 'disable' methods
Plugin = ^^livescript-ast-transform
    module.exports = ..

    ..name = 'transform-es-modules'

    ..enable = !->
        console.log \installing
        original-tokenize = @livescript.lexer.tokenize
        @livescript.lexer.tokenize = ->
            result = []
            console.log \tokenizing
            lexed = original-tokenize ...
            i = -1
            while ++i < lexed.length              
                l = lexed[i]
                console.log l
                [,, ...rest] = l
                
                if l.0 == \DECL and l.1 == \export
                    result.push [\ID \__es-export__ ...rest]
                    # result.push lexed[++i]
                else if l.0 == \DEFAULT
                    result.push [\ID \__es-export-default__ ...rest]
                else
                    result.push l
            result
        # console.log "#{@name} enabled"
        { Arr, Assign, Block, Cascade, Fun, Literal, Obj, Var } = @livescript.ast
        original-compile-root = Block::compile-root
        Self = @
        original-cascade-compile = Cascade::compile
        ast-entries-fixes = Object.values fixes.livescript.ast.entries .map -> TransformStream.create transform: it
        stream = DuplexStream.create!
        entries-fixed = stream.map (.ast)
        .map Object.entries .filter (.0 != \plugins)
        .series ...ast-entries-fixes
        .sync!        
        stream.push @livescript
        Nodelivescript = @livescript
        Block::compile-root = (o) ->
            # console.dir @, depth: 6
            walker = every-ast-node!
            
            fix0 = assign-parent-return-as-node!
            fix1 = add-replace-with-method!
            fix2 = add-replace-child-method Self.livescript
            fix3 = assign-type!
            fix0[pipe] fix1
            fix1[pipe] fix2
            fix2[pipe] fix3
            fix-input = fix0
            fix-output = fix3
            util.inject-output fix-input, LogNode
            walker[pipe] fix-input
            
            # fixed-nodes[pipe] sink
            found-exports = BooleanSpliter.create check: (node) ->
                { Cascade } = Self.livescript.ast
                node instanceof Cascade and node.input?value == \__es-export__
            fix-output[pipe] found-exports
            # found-exports.outputs.true[pipe] sink
            
            transformations = [
                enable-default-exports
                enable-object-exports
                expand-array-exports
                enable-assign-exports
                enable-literal-exports
                enable-anonymous-function-exports
            ]
            
            filter-exports = BooleanSpliter.create check: -> (.[type] == \Export )
            
            do-something-with-exports = TransformStream.create transform: (export-node) ->
                i = 0
                first-stream = transformations[i] livescript
                    out-stream = ..
                while ++i < transformations.length 
                    in-stream = out-stream
                    out-stream = transformations[i] livescript
                    in-stream[pipe] out-stream
            
                first-stream.push original
            filter-exports.outputs.true[pipe] do-something-with-exports
            
            t0 = TransformStream.create!
                ..transform = (original) ->
                    inserted-exports = insert-export-nodes!
                    i = 0
                    first-stream = transformations[i] livescript
                        out-stream = ..
                    while ++i < transformations.length 
                        in-stream = out-stream
                        out-stream = transformations[i] livescript
                        in-stream[pipe] out-stream
                    inserted-exports[pipe] first-stream
                    inserted-exports.push original
                    {original,transformed:out-stream}
            replacer = SyncSink.create on-data: (element) !->
                {original,transformed} = element
                # console.log \replacing original[type]
                original.replace-with ...transformed
            t0[pipe] replacer
            found-exports.outputs.true[pipe] t0
            # walker.push @
            root = DuplexStream.create!
            root[pipe] walker
            root.map (node) ->
                replacer.sync!
            root.push @
            
            # console.dir @, depth: 6
            
            # result =
            #     if o.bare
            #     then original-compile-root ...
            #     else 
            #         wraper = new Self.livescript.ast.Block [@]
            #         original-compile-root.call wraper, o with {+bare}
            result = original-compile-root ...
            result
        original-compile-with-declarations = Block::compile-with-declarations
        scope-patched = false
        Block::compile-with-declarations = ->
            if @scope and not scope-patched
                scope-patched := true
                scope-prototype = Object.get-prototype-of @scope
                Scope = scope-prototype.constructor
                original-emit = scope-prototype.emit
                scope-prototype.is-top = -> not @parent?
                scope-prototype.get-top = ->
                    scope = @
                    while scope.parent
                        scope = scope.parent
                    scope
                scope-prototype[Temporary] = ({name = \tmp}: arg = arg = {} ) ->
                    tmp = @temporary name
                    @variables[tmp + '.'] = "SCOPE! DONT TOUTCH IT!"
                    @[Variables][tmp] = new Variable arg <<< {name:tmp}
                
                _Variables = Symbol 'Scope::Variables@privat'
                Object.define-property scope-prototype, Variables,
                    get: -> @{}[_Variables]
                    
                # @scope.emit = (code,tab) ->
                scope-prototype.emit = (code,tab) ->
                    exported = 
                        for own k,v of @[Variables] when v.exported
                            @variables[v.name + '.'] = "SCOPE! DONT TOUTCH IT!"
                            v
                    by-storage = {}
                    for e in exported
                        by-storage[][e.storage].push e
                    variables = exported.filter (.storage == \var)
                    constants = exported.filter (.storage == \const)
                    lets = exported.filter (.storage == \let)
                    lines = []
                    lines.push variables if variables.length
                    lines.push lets if lets.length
                    lines.push constants if constants.length
                    extra-code = lines.map -> "#{tab}export #{it.0.storage} #{it.map (.compile-as-expression!) .join ','};\n"
                    augmented-code = sn @, ...extra-code, code
                    # scope-prototype.emit code, tab
                    original-emit.call @, augmented-code, tab
                
                # add: (name, type, node) ->
                #     @[Variables] ?= {}
                #     result = scope-prototype.call @, name,type, node
                #     @[Variables][name] = Variable.from-ast-node node
                #     result
                
        
            original-compile-with-declarations ...
        #     is-async-block = has-await-in @
        #     # livescript has not so great documentation so I don't know how
        #     # to set default bare to false
        #     # so we need to soverride it manualy if we are running async code
        #     if is-async-block and Self.override-options
        #         options.bare = false
        #     if is-async-block and options.bare == true
        #         throw Error "Top level code should be wrap in async function but compile option 'bare' is preventing it."
        # 
        #     result = original-compile-root.call @, options
        #         ..children.0 = '(async function(){\n' if is-async-block
        # ast = @livescript.ast
        # @original-Block-compile = ast.Decl
        # @livescript.ast.Decl = (type, nodes, lno) ~>
        #     unless type == \export
        #         @original-Decl type, nodes, lno
        #     else
        #         @es-export nodes
              

    ..disable = !->
        @livescript.ast.Fun::compile = @original-compile
    
    ..es-export = (lines) ->
        { Block, Fun, Assign, Class, Chain, Index, Key } = @livescript.ast
        i = -1
        while node = lines[++i] 
            if node instanceof Block
                lines.splice i-- 1 ...node.lines
                continue
            if node instanceof Fun and node.name
                throw Error "Function export is not supported"
                # lines.splice i++ 0 Assign Chain(out, [Index Key that]), Var that
                continue
            lines[i] =
                if node.var-name!
                # or node instanceof Assign and node.left. var-name!
                # or node instanceof Class  and node.title?var-name!
                    EsModule lines
                # then Assign Chain(out, [Index Key that]), node
                # else Import out, node
        Block lines

