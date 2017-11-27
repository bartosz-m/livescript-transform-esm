# Base for all plugins
Plugin = module.exports = ^^null
Plugin <<<
    get-default-compiler: ->
        require!{
            \livescript
            \livescript/lib/lexer
            \./Compiler
        }
        plugable-compiler = Symbol.for \plugable-compiler.livescript
        unless compiler = livescript[plugable-compiler]
            livescript[plugable-compiler] = compiler = Compiler.create {livescript,lexer}
            compiler.install!
        compiler

    install: (@livescript, config) !->
        @livescript = @get-default-compiler! unless @livescript
        @config <<< config
        @enable!
    
    enable: !-> throw Error "Plugin must override 'enable' method"