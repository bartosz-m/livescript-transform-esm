require! {
    assert
    fs
    path
    \diff-lines
    livescript
    \livescript/lib/lexer
    # \../src/register
    \../lib/plugin
    \livescript-compiler/lib/livescript/Compiler
}

esm-compiler = Compiler.create livescript: livescript with {lexer}
    plugin.install ..

cjs-compiler = Compiler.create livescript: livescript with {lexer}
    plugin.install .., format: \cjs

assert esm-compiler.ast.Block != cjs-compiler.ast.Block

failed = 0

test-compilation = ({compiler, ls-code,js-code,filename}) !->
    try
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



for test in tests# when test.match /^generate/
    console.log "testing #{test}"
    try
        code-file = path.join __dirname, test
        output-file = code-file.replace /\.ls$/ '-expected.js'
        module-file = code-file.replace /\.ls$/ '-expected.mjs'
        ls-code = fs.read-file-sync code-file, \utf8
        cjs-code = fs.read-file-sync output-file, \utf8
        ems-code = fs.read-file-sync module-file, \utf8
        test-compilation {compiler: esm-compiler, ls-code, js-code:ems-code, filename: code-file}
        test-compilation {compiler: cjs-compiler, ls-code, js-code:cjs-code, filename: code-file}
    catch
        if m = e.message.match /ENOENT\: no such file or directory, open '([^']+)'/
            fs.write-file m.1, ""
        failed++
        console.log e.stack

if failed 
    process.exit 1