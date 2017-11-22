# TODO: convert tokenize method to Node 
Lexer = module.exports = ^^null
Lexer <<<
    init: ({@livescript}) !->
      
    create: ->
        ^^@
            ..init ...&
    
    lex: (code, options) -> @tokenize code || '' options || {}
    
    tokenize: -> @livescript.lexer.tokenize ...&
    
    copy: -> ^^@