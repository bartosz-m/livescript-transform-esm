require! <[ assert stream source-map livescript-ast-transform livescript ./livescript/ast/Node ./selectors/selectors ]>
{ Duplex } = stream
{ SourceNode } = source-map
{ parent, type } = require \./livescript/ast/symbols

sn = (node = {}, ...parts) ->
    try
        result = new SourceNode node.line, node.column, null, parts
        result.display-name = node[type]
        result
    catch e
        console.dir parts
        throw e

Creatable = 
    create: (arg) ->
          Object.create @
              ..init arg
          
          
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
    .. <<< Creatable
    ..[type] = \Export
    ..init = extendable-function (@{local, alias}) ->
      
    ..traverse-children = (visitor, cross-scope-boundary)->
        visitor @local, @, \local
        visitor @alias, @, \alias if @alias
        @local.traverse-children ...&
        @alias.traverse-children ...& if @alias
        
    
    ..compile = extendable-function (o) ->
        alias =
            if @alias
                if  @alias.name != \default
                then [" as ", (@alias.compile o )]
                else [" as default" ]
            else []
        inner = (@local.compile o)
        sn @local, "export { ", inner, ...alias, " }"

    ..terminator = ';'
    
    Object.define-properties ..,
        local:
            get: -> @_local
            set: ->
                it[parent] = @
                @_local = it
            

DefaultExport = ^^Export
    ..[type] = \DefaultExport
    
    ..init = extendable-function (@{local}) !->
      
    ..traverse-children = (visitor, cross-scope-boundary) ->
        visitor @local, @, \local
        @local.traverse-children ...&
    
    ..compile = extendable-function (o) ->
        inner = (@local.compile o)
        sn @local, "export default ", inner
    
    .. <<<
        terminator:~
            -> @local.terminator
    
    # Object.define-properties ..,
    #     # terminator dependts on export target
    #     terminator:
    #         get: -> @local.terminator
    

TemporarVariable = ^^Node
    .. <<< Creatable
    ..[type] = \TemporarVariable
    
    ..init = extendable-function (@{name}) !->
      
    ..traverse-children = (visitor, cross-scope-boundary) ->
    
    ..compile = extendable-function (o) ->
        @temporary-name ?= o.scope.temporary @name
        sn @, @temporary-name
    
Identifier = ^^Node
    .. <<< Creatable
    ..[type] = \Identifier
    
    ..init = extendable-function (@{name}) !->
      
    ..traverse-children = (visitor, cross-scope-boundary) ->
    
    ..compile = extendable-function (o) ->
        sn @, @name

TemporarAssigment = ^^Node
    .. <<< Creatable
    ..[type] = \TemporarAssigment
        
    ..init = extendable-function (@{left,right}) !->
      
    ..traverse-children = (visitor, cross-scope-boundary) ->
        visitor @left, @, \left
        visitor @right, @, \right
        @left.traverse-children ...&
        @right.traverse-children ...&
    
    ..compile = extendable-function (o) ->
        sn @, (@left.compile o), ' = ' @right.compile o
    
    ..terminator = ';'
    
    .. <<<
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
    
    # Object.define-properties ..,
    #     left:
    #         get: -> @_left
    #         set: ->
    #             it[parent] = @
    #             @_left = it
    #     right:
    #         get: -> @_right
    #         set: ->
    #             it[parent] = @
    #             @_right = it

assert DefaultExport instanceof Export
assert DefaultExport instanceof Node

import-properties = (target, ...sources) ->
    for source in sources
        Object.define-properties target, Object.get-own-property-descriptors source
    target

pipe = Symbol \Stream::pipe

Passthrough = ^^null
    .. <<< Creatable
Passthrough <<<
    init: !->
        @buffer = []
        @outputs = []
    
    (pipe): (output) ->
        @outputs.push output
        @flush!
        output
        
    flush: !->
        for element in @buffer
            for output in @outputs
                output.write element
        @buffer = []
        
    write: (x) !->
        @buffer.push x
        @flush! if @outputs.length > 0

Transformator = ^^null
    .. <<< Creatable
Transformator <<< 
    init: (arg) !->
        Passthrough.init.call @, arg
        @transform = arg.transform if arg?transform?
        
    (pipe): Passthrough[pipe]
        
    flush: !->
        for element in @buffer
            @debug? \flushing, element
            if element[pipe]?
                element[pipe] @
            else                
                transformed = @transform element
                if transformed?[pipe]?
                    for output in @outputs
                        transformed[pipe] output
                else if transformed.length
                    for e in transformed
                        for output in @outputs
                          output.write e
                else
                    for output in @outputs
                        output.write transformed
        @buffer = []
        
    write: (x) !->
        @buffer.push x
        @flush! if @outputs.length > 0
              
    transform: (x) ->
        throw Error "You need to implement transform method youreself"

Sink = ^^null
    .. <<< Creatable
Sink <<<
    init: ({on-data} = {}) !->
        @on-data = on-data if on-data?
        
    write: (x) !->
        @on-data x
    
    on-data: !-> throw Error "You need to implement on-data method youreself"

ArraySink = ^^null
    .. <<< Creatable
ArraySink <<<
    init: !->
        @value = []
    write: (x) !->
        @value.push x


BooleanSpliter = ^^null
    .. <<< Creatable
BooleanSpliter <<<
    init: (arg) !->
        @check = arg.check if arg?check?
        @true-output = Passthrough.create!
            ..name = \true-output
        @false-output = Passthrough.create!
            ..name = \false-output
    check: ->  throw Error "You need to implement check method youreself"
    
    write: ->
        if @check it
        then @true-output.write it
        else @false-output.write it

FilterStream = ^^null
    import-properties .., Passthrough
FilterStream <<<
    init: (arg) !->
        Passthrough.init ...
        @filter = arg.filter if arg?filter?
    filter: ->  throw Error "You need to implement filter method youreself"
    
    write: ->
        if @filter it
            Passthrough.write ...
      
Merger = ^^null
    import-properties .., Passthrough
    ..init = (arg) !->
        Passthrough.init ...
        if arg.streams
            for stream in arg.streams
                stream[pipe] @

SyncSink = ^^null
    .. <<< Sink
    ..init = !-> Sink.init ...
    ..write = (element) ->
        if Array.is-array element
            for k,v in element
                if v?[pipe]?
                    array-sink = ArraySink.create!
                    v[pipe] array-sink
                    element[k] = array-sink.value
        else if \Object == typeof! element 
            for own k,v of element
                if v?[pipe]?
                    array-sink = ArraySink.create!
                    v[pipe] array-sink
                    element[k] = array-sink.value
        Sink.write.call @, element

# Encapsulates two streams into single one
ComposedStream = ^^null
    .. <<< Creatable
    ..init = (arg) !->
        @input = arg.input
        @output = arg.output
        unless @input? or @output
            throw Error "ComposedStream requires both input and output"
    ..write = !-> @input.write it
    ..[pipe] = -> @output[pipe] it

# Encapsulates multiple streams into single one
CascadeStream = ^^null
    .. <<< Creatable
    ..init = (arg) !->
        @streams = arg.streams
        @input = @streams.0
        @output = @streams[* - 1]
        
        for stream in @streams
            previous-stream[pipe] stream if previous-stream
            previous-stream = stream
        unless @input? or @output
            throw Error "ComposedStream requires both input and output"
    ..write = !-> @input.write it
    ..[pipe] = -> @output[pipe] it

Helper =
    filter: (...filters) ->
        streams = filters.map ~> FilterStream.create filter: it
        CascadeStream.create { streams }
            @[pipe] ..
    map: (...transforms) ->
        if transforms.length == 1
            Transformator.create { transform: transforms.0 }
                @[pipe] ..
        else
            streams = transforms.map ~> Transformator.create transform: it
            CascadeStream.create { streams }
                @[pipe] ..
    
    merge: (...streams) ->
        Merger.create streams: [@, ...streams]
            
    sync: !-> @to-array!
        
    to-array: ->
        result = ArraySink.create!
            @[pipe] ..
        result.value
            
for Type in [CascadeStream, ComposedStream, Passthrough, Transformator]
    Type <<< Helper


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
    Transformator.create transform: (node) -> as-array line-to-export node

expand-array-exports = ->
    if-array-exports = BooleanSpliter.create check: (.local[type] == \Arr)
    
    expand-array-exports = if-array-exports.true-output.map (node) ->
        assert node.local[type] == \Arr
        node.local.items.map -> Export.create local: it
    
    transformed = expand-array-exports.merge if-array-exports.false-output
    
    ComposedStream.create input: if-array-exports, output: transformed

enable-default-exports = ->
    if-export-with-default = BooleanSpliter.create check: ->
        it.local[type] == \Cascade
        and it.local.input[type] == \Var
        and it.local.input.value == \__es-export-default__
        
    extract-export-target = if-export-with-default.true-output.map (node) ->
        {input,output} = node.local 
        unless output[type] == \Block
            throw Error "Expected Block at #{output.line} but found #{output@@name}"
        unless output.lines.length == 1
            throw Error "Expected exacly one line in default export at #{output.line} but found #{output.lines.length}"
        output.lines.0
        
    mark-as-default = extract-export-target.map (node) ->
        Export.create local: node, alias: Identifier.create name: \default
    
    transformed = mark-as-default.merge if-export-with-default.false-output
    ComposedStream.create input: if-export-with-default, output: transformed


enable-literal-exports = ->
    if-anonymous-export = BooleanSpliter.create check: ->
        unless it.local?
            console.warn "missing .local"
        it.local?[type] == \Literal
        or (it.local?[type] == \Fun and not it.local.name?)
        or (it.local?[type] == \Class and not it.local.name?)
    
    create-temporary-variable = Transformator.create!
        ..transform = (node) ->
            tmp = TemporarVariable.create name: \export
            assign = TemporarAssigment.create left: tmp, right: node.local
            [assign, Export.create local: assign.left, alias: node.alias]
    
    if-anonymous-export.true-output[pipe] create-temporary-variable
    
    transformed = Merger.create streams: [
        create-temporary-variable,
        if-anonymous-export.false-output
    ]
    ComposedStream.create input: if-anonymous-export, output: transformed
    
enable-anonymous-function-exports = ->
    if-literal-export = BooleanSpliter.create check: ->
        it.local?[type] == \Fun and it.local.name?
    
    create-temporary-variable = Transformator.create!
        ..transform = (node) ->
            [node.local, Export.create local: Identifier.create node.local{name}]
    
    if-literal-export.true-output[pipe] create-temporary-variable
    
    transformed = Merger.create streams: [
        create-temporary-variable,
        if-literal-export.false-output
    ]
    ComposedStream.create input: if-literal-export, output: transformed

enable-object-exports = (livescript) ->
    if-object-export = BooleanSpliter.create check: ->
        it.local?[type] == \Obj
    
    expand-object-exports = Transformator.create!
        ..transform = (node) ->
            {items} = node.local
            items.map ({key,val}) -> Export.create local: val, alias: key
    
    if-object-export.true-output[pipe] expand-object-exports
    
    transformed = Merger.create streams: [
        expand-object-exports,
        if-object-export.false-output
    ]
    ComposedStream.create input: if-object-export, output: transformed

enable-assign-exports = ->
    if-assign-exports = BooleanSpliter.create check: (.local?[type] == \Assign)
    
    extract-assigns = Transformator.create!
        ..transform = (node) ->
            assign = node.local
            [assign, Export.create local: assign.left]
    
    if-assign-exports.true-output[pipe] extract-assigns
    
    transformed = Merger.create streams: [
        extract-assigns,
        if-assign-exports.false-output
    ]
    ComposedStream.create input: if-assign-exports, output: transformed

stream-object-entries = (object) ->
    result = Passthrough.create!
    for own k,v of object
        result.write [k,v]
    result

stream-object-values = (object) ->
    result = Passthrough.create!
    for own k,v of object
        result.write v
    result

every-ast-node = ->
    walker = Transformator.create transform: (node) ->
        let output = Passthrough.create!
            output.write {node,parent: null}
            walk-ast = (node, parent, name, index) !->
                output.write {node,parent,name,index}
        
        # console.log \walking node
        
            node.traverse-children walk-ast
            output
    walker
    
assign-parent-return-as-node = ->
    Transformator.create transform: ->
        it.node[parent] = it.parent
        it.node

assign-type = ->
    Transformator.create transform: ->
        unless it[type]
            it-prototype = Object.get-prototype-of it
            it-prototype[type] = it@@display-name ? it@@name
                console.log "setting type" ..
        it

add-replace-with-method = ->
    Transformator.create transform: ->
        unless it.replace-with
            it-prototype = Object.get-prototype-of it
            it-prototype.replace-with = Node.replace-with
        it

add-replace-child-method = ->
    Transformator.create transform: ->
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
        ast-entries-fixes = Object.values fixes.livescript.ast.entries .map -> Transformator.create transform: it
        ast-fixes = CascadeStream.create streams: ast-entries-fixes
        stream = Passthrough.create!
        entries-fixed = stream.map Object.entries .filter (.0 != \plugins) .[pipe] ast-fixes .sync!
        stream.write @livescript.ast
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
            walker[pipe] fix-input
            
            # fixed-nodes[pipe] sink
            found-exports = BooleanSpliter.create check: (node) ->
                { Cascade } = Self.livescript.ast
                node instanceof Cascade and node.input?value == \__es-export__
            fix-output[pipe] found-exports
            # found-exports.true-output[pipe] sink
            
            transformations = [
                enable-default-exports
                enable-object-exports
                expand-array-exports
                enable-assign-exports
                enable-literal-exports
                enable-anonymous-function-exports
            ]
            
            filter-exports = BooleanSpliter.create check: -> (.[type] == \Export )
            
            do-something-with-exports = Transformator.create transform: (export-node) ->
                i = 0
                first-stream = transformations[i] livescript
                    out-stream = ..
                while ++i < transformations.length 
                    in-stream = out-stream
                    out-stream = transformations[i] livescript
                    in-stream[pipe] out-stream
            
                first-stream.write original
            filter-exports.true-output[pipe] do-something-with-exports
            
            t0 = Transformator.create!
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
                    inserted-exports.write original
                    {original,transformed:out-stream}
            replacer = SyncSink.create on-data: (element) !->
                {original,transformed} = element
                # console.log \replacing original[type]
                original.replace-with ...transformed
            t0[pipe] replacer
            found-exports.true-output[pipe] t0
            # walker.write @
            root = Passthrough.create!
            root[pipe] walker
            root.map (node) ->
                replacer.sync!
            root.write @
            
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

