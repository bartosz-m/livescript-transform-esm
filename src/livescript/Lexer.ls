require! {
    assert
    \../nodes/JsNode
    \../nodes/SeriesNode
    \../nodes/symbols : { copy }
}

OriginalLex = JsNode[copy]!
    ..name = \original-lex.Lexer
    ..js-function = (code, options) ->
        assert.equal \Lexer @name
        @tokenize.call @, code || '' options || {}
          

Lex = SeriesNode[copy]!
    ..name = \lex.Lexer
    ..append OriginalLex

    
OriginalTokenize = JsNode[copy]!
    ..js-function = (code, options) ->
          assert.equal \Lexer @name
          assert @livescript
          (^^@livescript.lexer).tokenize ...&

Tokenize = SeriesNode[copy]!
    ..name = \tokenize.Lexer
    ..append OriginalTokenize

Lexer = module.exports = ^^null
Lexer <<<
    count: 0
    id: 0
    name: \Lexer
    
    nodes-names: <[ lex tokenize ]>
    
    init: ({@livescript}) !->
        unless @livescript.lexer
            throw Error "LiveScript implementation is missing lexer"
        @id = Lexer.count++
        @nodes-names = Array.from @nodes-names
        for name in @nodes-names
            @[name] = @[name][copy]!
                ..this = @
      
    create: ->
        ^^@
            ..init ...&
    
    lex: Lex
    
    tokenize: Tokenize
    
    copy: ->
        result = ^^@
            ..id = Lexer.count++
            ..nodes-names = Array.from ..nodes-names
            for name in ..nodes-names
                ..[name] = ..[name][copy]!
                    ..this = result
    (copy): ->
        result = ^^@
            ..id = Lexer.count++
            ..nodes-names = Array.from ..nodes-names
            for name in ..nodes-names
                ..[name] = ..[name][copy]!
                    ..this = result
Lex.this = Lexer
Tokenize.this = Lexer

# some test
copy-lexer = Lexer.copy!
assert.equal copy-lexer.name, copy-lexer.lex.this.name