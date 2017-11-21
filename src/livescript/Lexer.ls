Lexer = ^^null
    module.exports = ..
Lexer <<<
    init: ({@livescript}) !->
      
    create: ->
        ^^@
            ..init ...&
    
    tokenize: ->
        @livescript.lexer.tokenize