require! {
    assert
    fs
    path
    \diff-lines
    livescript
    \../src
}
# 
# filepath = __dirname + \/simple.ls
# js-filepath = __dirname + \/simple-expected.js
# source = fs.read-file-sync filepath, \utf8
# expected = fs.read-file-sync js-filepath, \utf8 
# result = livescript.compile source
# console.log result
# assert result == expected


test-compilation = ({ls-code,js-code,filename}) !->
    try
        compiler = livescript
        generated-output = compiler.compile ls-code, {filename, -map, -header}
        if generated-output != js-code
            console.log "Generated output is different than expected"
            console.log diff-lines js-code, generated-output
            console.log generated-output
    catch
        console.log '##### Error'
        console.error e.message
        console.error e.stack


tests = fs.readdir-sync __dirname .filter -> it != \index.ls and it.match /\.ls$/

for test in tests
    console.log "testing #{test}"
    code-file = path.join __dirname, test
    output-file = code-file.replace /\.ls$/ '-expected.js'
    ls-code = fs.read-file-sync code-file, \utf8
    js-code = fs.read-file-sync output-file, \utf8
    test-compilation {ls-code, js-code, filename: code-file}
