require! {
    assert
    fs
    path
    \diff-lines
    livescript
    \livescript/lib/lexer
    \../src/plugin
    \../src/livescript/Compiler
}

livescript.lexer = lexer
compiler = Compiler.create {livescript}
plugin.install compiler

failed = 0

test-compilation = ({ls-code,js-code,filename}) !->
    try
        # compiler = livescript
        generated-output = compiler.compile ls-code, {filename, -map, -header}
        if generated-output != js-code
            unless generated-output
                throw Error "Generated output is undefined"
            unless \String == (type = typeof! generated-output)
                console.log generated-output
                throw Error "Generated is not a string but #{type}"
            if generated-output
                
                console.log "Generated output is different than expected"
                console.log diff-lines js-code, generated-output
                console.log generated-output
            
            failed++
    catch
        console.log '##### Error'
        console.error e.message
        console.error e.stack
        failed++


tests = fs.readdir-sync __dirname .filter -> it != \index.ls and it.match /\.ls$/



for test in tests# when test.match /^ls-compile/
    console.log "testing #{test}"
    code-file = path.join __dirname, test
    output-file = code-file.replace /\.ls$/ '-expected.js'
    ls-code = fs.read-file-sync code-file, \utf8
    js-code = fs.read-file-sync output-file, \utf8
    test-compilation {ls-code, js-code, filename: code-file}

if failed 
    process.exit 1