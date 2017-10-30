require!{
  'source-map': { SourceNode }
}

function YES  then true
function NO   then false
function THIS then this
function VOID then void

(Node = -> ...):: =
    compile: (options, level) ->
        o = {} <<< options
        o.level? = level
        node = @unfold-soak o or this
        # If a statement appears within an expression, wrap it in a closure.
        return node.compile-closure o if o.level and node.is-statement!
        code = (node <<< tab: o.indent).compile-node o
        if node.temps then for tmp in that then o.scope.free tmp
        code

    compile-closure: (o) ->
        # A statement that _jumps_ out of current context (like `return`) can't
        # be an expression via closure-wrapping, as its meaning will change.
        that.carp 'inconvertible statement' if @get-jump!
        fun = Fun [] Block this
        call = Call!
        fun.async = true if o.in-async
        fun.generator = true if o.in-generator
        var hasArgs, hasThis
        @traverse-children !->
            switch it.value
            | \this      => hasThis := true
            | \arguments => hasArgs := it.value = \args$
        if hasThis
            call.args.push Literal \this
            call.method = \.call
        if hasArgs
            call.args.push Literal \arguments
            fun.params.push Var \args$
        # Flag the function as `wrapper` so that it shares a scope
        # with its parent to preserve the expected lexical scope.
        out = Parens(Chain fun<<<{+wrapper, @void} [call]; true)
        if o.in-generator
            out = new Yield 'yieldfrom', out
        else if o.in-async
            out = new Yield 'await', out
        out.compile o

    # Compiles a child node as a block statement.
    compile-block: (o, node) ->
        unless sn-empty(code = node?compile o, LEVEL_TOP)
            sn(null, "{\n", code, "\n#{@tab}}")
        else
            sn(node, '{}')

    # Spreads a transformation over a list and compiles it.
    compile-spread-over: (o, list, transform) ->
        ob = list instanceof Obj
        them = list.items
        for node, i in them
            node.=it if sp = node instanceof Splat
            node.=val if ob and not sp
            node = transform node
            node = lat = Splat node if sp
            if ob and not sp then them[i].val = node else them[i] = node
        if not lat and (@void or not o.level)
            list = Block(if ob then [..val for them] else them) <<< {@front, +void}
        list.compile o, LEVEL_PAREN

    # If the code generation wishes to use the result of a complex expression
    # in multiple places, ensure that the expression is only ever evaluated once,
    # by assigning it to a temporary variable.
    cache: (o, once, level) ->
        unless @is-complex!
            return [if level? then @compile o, level else this] * 2
        sub = Assign ref = Var(o.scope.temporary!), this
        # Pass a `level` to precompile.
        if level?
            sub.=compile o, level
            o.scope.free ref.value if once
            return [sub, ref.value]
        # If flagged as `once`, the tempvar will be auto-freed.
        if once then [sub, ref <<< {+temp}] else [sub, ref, [ref.value]]

    # Compiles to a variable/source pair suitable for looping.
    compile-loop-reference: (o, name, ret, safe-access) ->
        if this instanceof Var   and o.scope.check @value
        or this instanceof Unary and @op in <[ + - ]> and -1/0 < +@it.value < 1/0
        or this instanceof Literal and not @is-complex!
            code = @compile o, LEVEL_PAREN
            code = "(#code)" if safe-access and this not instanceof Var
            return [code] * 2
        asn = Assign Var(tmp = o.scope.temporary name), this
        ret or asn.void = true
        [tmp; asn.compile o, if ret then LEVEL_CALL else LEVEL_PAREN]

    # Passes each child to a function, returning its return value if exists.
    each-child: (fn) ->
        for name in @children when child = @[name]
            if \length of child
                for node, i in child then return that if fn(node, name, i)
            else
                return that if fn(child, name)?

    # Performs `each-child` on every descendant.
    # Overridden by __Fun__ not to cross scope by default.
    traverse-children: (fn, xscope) ->
        @each-child (node, name, index) ~>
            fn(node, this, name, index) ? node.traverse-children fn, xscope

    # Walks every descendent to expand notation like property shorthand and
    # slices. `assign` is true if this node is in a negative position, like
    # the right-hand side of an assignment. Overrides of this function can
    # return a value to be replaced in the tree.
    rewrite-shorthand: (o, assign) !->
        for name in @children when child = @[name]
            if \length of child
                for node, i in child
                    if node.rewrite-shorthand o, assign then child[i] = that
            else if child.rewrite-shorthand o, assign then @[name] = that

    # Performs anaphoric conversion if a `that` is found within `@aTargets`.
    anaphorize: ->
        @children = @aTargets
        if @each-child hasThat
            # Set a flag and deal with it in the Existence node (it's too
            # tricky here).
            if (base = this)[name = @a-source] instanceof Existence
                base[name].do-anaphorize = true
            # 'that = x' here is fine.
            else if base[name]value is not \that
                base[name] = Assign Var(\that), base[name]
        function hasThat
            it.value is \that or if it.a-source
            then hasThat that if it[that]
            else it.each-child hasThat
        delete @children
        @[@a-source] <<< {+cond}

    # Throws a syntax error, appending `@line` number to the message.
    carp: (msg, type = SyntaxError) ->
        throw type "#msg on line #{ @line or @traverse-children -> it.line }"

    # Defines delegators.
    delegate: !(names, fn) ->
        for let name in names
            @[name] = -> fn.call this, name, it

    # Default implementations of the common node properties and methods. Nodes
    # will override these with custom logic, if needed.
    children: []

    terminator: \;

    is-complex: YES

    is-statement  : NO
    is-assignable : NO
    is-callable   : NO
    is-empty      : NO
    is-array      : NO
    is-string     : NO
    is-regex      : NO

    is-matcher: -> @is-string! or @is-regex!

    # Do I assign a certain variable?
    assigns: NO

    # Picks up name(s) from LHS.
    rip-name: VOID

    unfold-soak   : VOID
    unfold-assign : VOID
    unparen       : THIS
    unwrap        : THIS
    maybe-key     : VOID
    var-name      : String
    get-accessors : VOID
    get-call      : VOID
    get-default   : VOID
    # Digs up a statement that jumps out of this node.
    get-jump      : VOID
    is-next-unreachable : NO

    # If this node can be used as a property shorthand, finds the implied key.
    # If the key is dynamic, this node may be mutated so that it refers to a
    # temporary reference that this function returns (whether a reference or
    # the declaration of the reference is returned depends on the value of the
    # assign parameter). Most of the interesting logic here is to be found in
    # Parens::extract-key-ref, which handles the dynamic case.
    extract-key-ref: (o, assign) -> @maybe-key! or
        @carp if assign then "invalid assign" else "invalid property shorthand"

    invert: -> Unary \! this, true

    invert-check: ->
        if it.inverted then @invert! else this

    add-else: (@else) -> this

    # Constructs a node that returns the current node's result.
    # If obj is true, interprets this node as a key-value pair to be
    # stored on ref. Otherwise, pushes this node into ref.
    make-return: (ref, obj) ->
        if obj then
            items = if this instanceof Arr
                if not @items.0? or not @items.1?
                    @carp 'must specify both key and value for object comprehension'
                @items
            else
                kv = \keyValue$
                for v, i in [Assign(Var(kv), this), Var(kv)]
                    Chain v .add Index Literal i
            Assign (Chain Var ref).add(Index items.0, \., true), items.1
        else if ref
            Call.make JS(ref + \.push), [this]
        else
            Return this

    # Extra info for `toString`.
    show: String

    # String representation of the node for inspecting the parse tree.
    # This is what `lsc --ast` prints out.
    to-string: (idt or '') ->
        tree  = \\n + idt + @constructor.display-name
        tree += ' ' + that if @show!
        @each-child !-> tree += it.toString idt + TAB
        tree

    # JSON serialization
    stringify: (space) -> JSON.stringify this, null space
    to-JSON: -> {type: @constructor.display-name, ...this}
    
module.exports = Node