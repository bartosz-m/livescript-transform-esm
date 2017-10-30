require! <[ assert stream source-map livescript-ast-transform livescript ./livescript/ast/Node ./selectors/selectors ./NodePointer ]>
{ Duplex } = stream
{ SourceNode } = source-map
sn = (node = {}, ...parts) ->
    try
        result = new SourceNode node.line, node.column, null, parts
        result.display-name = node.constructor.display-name
        result
    catch e
        console.dir parts
        throw e

Creatable = Object.create null
    ..create = (arg) ->
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
      
SymbolExport = Object.create Node
    ..init = (@{symbol, alias}) ->
    
    
    ..compile = (o) ->
        { Literal } = @livescript.ast
        alias = if @alias
            then [" as ", (@alias.compile o )]
            else []
        inner = (@symbol.compile o)
        sn @symbol, "export { ", inner, ...alias," }"
    
    ..create = extendable-function (arg) ->
        Object.create @
            ..init arg
    
    ..terminator = ';'

Export = Object.create Node
    ..type = \Export
    ..prototype = ..
    ..display-name = \Export
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
    
    ..create = extendable-function (arg) ->
        Object.create @
            ..init arg
    
    ..terminator = ';'

DefaultExport = Object.create Export
    ..display-name = \DefaultExport
    
    ..init = extendable-function (@{local}) !->
      
    ..traverse-children = (visitor, cross-scope-boundary) ->
        visitor @local, @, \local
        @local.traverse-children ...&
    
    ..compile = extendable-function (o) ->
        inner = (@local.compile o)
        sn @local, "export default ", inner,
    
    ..create = extendable-function (arg) ->
        Object.create @
            ..init arg
    
    # terminator dependts on export target
    Object.define-property .., \terminator,
        get: -> @local.terminator

TemporarVariable = Object.create Node
    ..display-name = \TemporarVariable
    ..constructor = ..
    
    ..init = extendable-function (@{name}) !->
        
      
    ..traverse-children = (visitor, cross-scope-boundary) ->
    
    ..compile = extendable-function (o) ->
        @temporary-name ?= o.scope.temporary @name
        sn @, @temporary-name
    
    ..create = extendable-function (arg) ->
        Object.create @
            ..init arg

Identifier = Object.create Node
    .. <<< Creatable
    ..display-name = \Identifier
    ..constructor = ..
    
    ..init = extendable-function (@{name}) !->
        
      
    ..traverse-children = (visitor, cross-scope-boundary) ->
    
    ..compile = extendable-function (o) ->
        sn @, @name
    
    # terminator dependts on export target
    # ..terminator = ';'

TemporarAssigment = Object.create Node
    ..display-name = \TemporarAssigment
    ..constructor = ..
    
    ..init = extendable-function (@{left,right}) !->
      
    ..traverse-children = (visitor, cross-scope-boundary) ->
        visitor @local, @, \left
        visitor @local, @, \right
        @left.traverse-children ...&
        @right.traverse-children ...&
    
    ..compile = extendable-function (o) ->
        # tmp = o.scope.temporary @left.name
        # @left.name = tmp
        # v = new @livescript.ast.Var tmp
        # assign = @livescript.ast.Assign v, @right
        # console.log @right
        sn @, (@left.compile o), ' = ' @right.compile o#assign.compile o
    
    ..create = extendable-function (arg) ->
        Object.create @
            ..init arg
    
    # terminator dependts on export target
    ..terminator = ';'

assert DefaultExport instanceof Export
assert DefaultExport instanceof Node

FunctionExport = Object.create Node
    ..init = (@{\function,alias}) ->
      
    ..terminator = \;
    
    ..create = (arg) ->
        Object.create @
            ..init arg
      
    ..compile = (o) ->
        if @alias
            if @function.name
                if @function.name != alias
                    function-declaration = @function.compile o
                    export-expression = sn @variable, "export #{@function.name} as ", @alias.compile o
                    sn @function, function-declaration, export-expression
                else
                    sn @function, function-declaration, export-expression
            else
                tmp = o.scope.temporary \export
                function-declaration = sn @function, "var #{tmp} = ", @function.compile o
                sn @function, function-declaration, "\n#{o.indent}export { #{tmp} as ", (@alias.compile o), ' }'
        else
            unless @function.name
                throw Error "Export of anonymous functions is not supported line #{@function.line}"
            sn @function, 'export ' @function.compile o

ExpressionExport = Object.create Node
    ..init = (@{expression}) ->
      
    ..terminator = ';'
    
    ..create = (arg) ->
        Object.create @
            ..init arg
      
    ..compile = (o) ->
        if @moved-to-top
            @expression.compile o
        else
            symbol = @expression.left
            if @expression.const
                constant = o.scope{}[Variables][symbol.value] ?= Constant.from-ast-node @expression
                    ..exported = true
                o.scope.variables[symbol.value + '.'] = ""
                constant.compile o
                sn @expression, ''
            else
                o.scope{}[Variables][symbol.value] ?= Variable.from-ast-node symbol
                    ..exported = true
                sn @expression, (@expression.compile o)



Passthrough = Object.create null
    .. <<< Creatable
    ..name = \Passthrough
    ..init = !->
        @buffer = []
        @outputs = []
    
    ..pipe = (output) ->
        @outputs.push output
        @flush!
        output
        
    ..flush = !->
        for element in @buffer
            for output in @outputs
                output.write element
        @buffer = []
        
    ..write = (x) !->
        @buffer.push x
        @flush! if @outputs.length > 0

Transformator = Object.create null
    .. <<< Creatable
    ..init = (arg) !->
        @transform = arg.transform if arg?transform?
        @buffer = []
        @outputs = []
        
    ..pipe = (output) ->
        @outputs.push output
        @flush!
        output
        
    ..flush = !->
        for element in @buffer
            transformed = @transform element
            if transformed?pipe?
                for output in @outputs
                    transformed.pipe output
            if transformed.length
              for e in transformed
                  for output in @outputs
                      output.write e
            else
                for output in @outputs
                    output.write transformed
        @buffer = []
        
    ..write = (x) !->
        @buffer.push x
        if @outputs.length > 0
            @flush!
              
    ..transform = (x) ->
        throw Error "You need to implement transform method youreself"
        
Sink = Object.create null
    .. <<< Creatable
    ..init = ({on-data} = {}) !->
        @on-data = on-data if on-data?
        
    ..write = (x) !->
        @on-data x
    
    ..on-data = !-> throw Error "You need to implement on-data method youreself"

ArraySink = Object.create null
    .. <<< Creatable
    ..init = !->
        @value = []
    ..write = (x) !->
        @value.push x
      
BooleanSpliter = Object.create null
    .. <<< Creatable
    ..init = (arg) !->
        @check = arg.check if arg?check?
        @true-output = Passthrough.create!
            ..name = \true-output
        @false-output = Passthrough.create!
            ..name = \false-output
    ..check = ->  throw Error "You need to implement check method youreself"
    
    ..write = ->
        if @check it
        then @true-output.write it
        else @false-output.write it
      
Merger = Object.create null
    .. <<< Passthrough
    ..init = (arg) !->
        Passthrough.init.call @, arg
        if arg.streams
            for stream in arg.streams
                stream.pipe @

SyncSink = Object.create null
    .. <<< Sink
    ..init = !-> Sink.init.call @, it
    ..write = (element) ->
        if Array.is-array element
            for k,v in element
                if v?pipe?
                    array-sink = ArraySink.create!
                    v.pipe array-sink
                    element[k] = array-sink.value
        else if \Object == typeof! element 
            for own k,v of element
                if v?pipe?
                    array-sink = ArraySink.create!
                    v.pipe array-sink
                    element[k] = array-sink.value
        Sink.write.call @, element

# Encapsulates multiple streams into single one
ComposedStream = Object.create null
    .. <<< Creatable
    ..init = (arg) !->
        @input = arg.input
        @output = arg.output
        unless @input? or @output
            throw Error "ComposedStream requires both input and output"
    ..write = !-> @input.write it
    ..pipe = -> @output.pipe it

as-array = ->
    if Array.is-array it
    then it
    else [ it ]

line-to-export = (livescript,cascade) ->
    const {input, {lines}: output} = cascade
    if lines.length == 0
        throw Error "Empty export at #{cascade.line}:#{cascade.column}"
    lines.map -> Export.create local: it

flatten = (array) ->
    result = []
        array.for-each ->
            if Array.is-array it
                ..push ...it
            else
                ..push it

find-exports = (livescript, node) ->
    { Cascade } = livescript.ast
    pointer = NodePointer.create node: node
    to-replace = pointer.filter ({node,parent,name,index}) ->
        node instanceof Cascade and node.input?value == \__es-export__

replace-nodes = (to-replace) !->
    to-replace.for-each ({original,transformed}) !->
        original.replace ...as-array transformed

        
insert-export-nodes = (livescript) ->
    Transformator.create!
        ..transform = ({node}: original) -> as-array line-to-export livescript, node

expand-array-exports = (livescript) ->
    { Arr } = livescript.ast
    if-array-exports = BooleanSpliter.create check: (.local instanceof Arr)
                
    expand-array-exports = Transformator.create!
        ..transform = (node) -> node.local.items.map -> Export.create local: it
    
    if-array-exports
        ..true-output.pipe expand-array-exports
    
    transformed = Merger.create streams: [
        expand-array-exports,
        if-array-exports.false-output
    ]
    ComposedStream.create input: if-array-exports, output: transformed

enable-default-exports = (livescript) ->
    { Block, Cascade, Var } = livescript.ast
    if-export-with-default = BooleanSpliter.create check: ->
        it.local instanceof Cascade
        and it.local.input instanceof Var
        and it.local.input.value == \__es-export-default__
    
    
    extract-export-target = Transformator.create!
        ..transform = (node) ->
            {input,output} = node.local 
            unless output instanceof Block
                throw Error "Expected Block at #{output.line} but found #{output@@name}"
            unless output.lines.length == 1
                throw Error "Expected exacly one line in default export at #{output.line} but found #{output.lines.length}"
            output.lines.0
    
    mark-as-default = Transformator.create!
        ..transform = (node) ->
            Export.create local: node, alias: name: \default
    
    if-export-with-default.true-output.pipe extract-export-target .pipe mark-as-default
    
    transformed = Merger.create streams: [
        mark-as-default,
        if-export-with-default.false-output
    ]
    ComposedStream.create input: if-export-with-default, output: transformed


enable-literal-exports = (livescript) ->
    { Assign, Fun, Literal } = livescript.ast
    if-anonymous-export = BooleanSpliter.create check: ->
        it.local instanceof Literal
        or (it.local instanceof Fun and not it.local.name?)
    
    create-temporary-variable = Transformator.create!
        ..transform = (node) ->
            tmp = TemporarVariable.create name: \export
            assign = TemporarAssigment.create left: tmp, right: node.local
            [assign, Export.create local: assign.left, alias: node.alias]
    
    if-anonymous-export.true-output.pipe create-temporary-variable
    
    transformed = Merger.create streams: [
        create-temporary-variable,
        if-anonymous-export.false-output
    ]
    ComposedStream.create input: if-anonymous-export, output: transformed
    
enable-anonymous-function-exports = (livescript) ->
    { Fun } = livescript.ast
    if-literal-export = BooleanSpliter.create check: ->
        it.local instanceof Fun and it.local.name?
    
    create-temporary-variable = Transformator.create!
        ..transform = (node) ->
            [node.local, Export.create local: Identifier.create node.local{name}]
    
    if-literal-export.true-output.pipe create-temporary-variable
    
    transformed = Merger.create streams: [
        create-temporary-variable,
        if-literal-export.false-output
    ]
    ComposedStream.create input: if-literal-export, output: transformed

enable-object-exports = (livescript) ->
    { Obj } = livescript.ast
    if-object-export = BooleanSpliter.create check: ->
        it.local instanceof Obj
    
    expand-object-exports = Transformator.create!
        ..transform = (node) ->
            {items} = node.local
            items.map ({key,val}) -> Export.create local: val, alias: key
    
    if-object-export.true-output.pipe expand-object-exports
    
    transformed = Merger.create streams: [
        expand-object-exports,
        if-object-export.false-output
    ]
    ComposedStream.create input: if-object-export, output: transformed

enable-assign-exports = (livescript) ->
    { Assign } = livescript.ast
    if-assign-exports = BooleanSpliter.create check: (.local instanceof Assign)
    
    extract-assigns = Transformator.create!
        ..transform = (node) ->
            assign = node.local
            [assign, Export.create local: assign.left]
    
    if-assign-exports.true-output.pipe extract-assigns
    
    transformed = Merger.create streams: [
        extract-assigns,
        if-assign-exports.false-output
    ]
    ComposedStream.create input: if-assign-exports, output: transformed


# livescript-ast-transform gives us install and uninstall methods
# also throws error with more meaningfull message if we forget implement
# 'enable' and 'disable' methods
Plugin = Object.create livescript-ast-transform
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
        #     @original-compile-root  = ..
        Self = @
        original-cascade-compile = Cascade::compile
      
        Nodelivescript = @livescript
        Block::compile-root = ->
            console.dir @, depth: 6
            exports = find-exports Self.livescript, @
            
            transformations = [
                insert-export-nodes
                enable-default-exports
                enable-object-exports
                expand-array-exports
                enable-assign-exports
                enable-literal-exports
                enable-anonymous-function-exports
            ]
            
            t0 = Transformator.create!
                ..transform = ({node,parent,name,index}: original) ->
                    i = 0
                    first-stream = transformations[i] livescript
                        out-stream = ..
                    while ++i < transformations.length 
                        in-stream = out-stream
                        out-stream = transformations[i] livescript
                        in-stream.pipe out-stream
                    
                    first-stream.write original
                    {original,transformed:out-stream}
            
            replacer = SyncSink.create on-data: (element) !->
                {original,transformed} = element
                original.replace ...transformed
            t0.pipe replacer
            exports.for-each t0~write
            
            console.dir @, depth: 6
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
                    console.log \exported exported
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

