require! {
    \path
    \chokidar
    \fs-extra : fs
    \livescript : livescript
    \livescript/lib/lexer
    \livescript-transform-object-create
    \../lib/plugin : transform-esm
    \livescript-compiler/lib/livescript/Compiler : {__default__ : Compiler}
    # \../src
}

ls-compiler = Compiler.create {livescript: livescript with {lexer}}
transform-esm.install ls-compiler, format: \cjs

absolute-path = -> path.normalize path.join __dirname, it

lib-path = absolute-path '../lib'
src-path = absolute-path '../src/'
watching = true

default-options =
    map: 'linked'
    bare: true
    header: false
    format: \cjs

ls-ast = (code, options = {}) ->
      ast = livescript.ast code
      output = ast.compile-root options
      output.set-file options.relative-filename
      result = output.to-string-with-source-map!
          ..ast = ast

to-compile = 0

set-watching = ->
    watching := it
    # console.log "ready[#{ready}] to-compile[#{to-compile}] watching[#{watching}]"
    if ready and to-compile == 0 and not watching
        watcher.close!

compile = (filepath) !->>
    to-compile++
    relative-path = path.relative src-path, filepath
    # relative-js-path = relative-path.replace '.ls', '.js'
    # output = path.join lib-path, relative-js-path
    # relative-map-file = "#relative-js-path.map"
    # map-file = path.join lib-path, relative-map-file
    try
        ls-code = await fs.read-file filepath, \utf8
        options =
            # filename: path.join \../src relative-path
            filename: filepath
            relative-filename: path.join \../src relative-path
            output-filename: relative-path.replace /.ls$/ '.js'
        console.log "compiling #relative-path"
        # js-result = ls-ast ls-code, options <<< default-options
        js-result = ls-compiler.compile ls-code, options <<< default-options
        ext = if default-options.format == \esm and (js-result.ast.exports?length or js-result.ast.imports?length)
        then '.mjs'
        else '.js'
        relative-js-path = relative-path.replace '.ls', ext
        output = path.join lib-path, relative-js-path
        relative-map-file = "#relative-js-path.map"
        map-file = path.join lib-path, relative-map-file
        js-result
            ..source-map = ..map.to-JSON!
        fs.output-file output, js-result.code
        fs.output-file map-file, JSON.stringify js-result.map.to-JSON!
    catch
        console.error e
        console.error e.stack
    to-compile--
    set-watching watching

ready = false

console.log \watching "#{src-path}**/*.ls"
watcher = chokidar.watch "#{src-path}**/*.ls", ignored: /(^|[\/\\])\../
.on \ready (event, filepath) ->
    console.log 'initiall scan completed'
    ready := true
    set-watching watching
.on \change compile
.on \add compile
.on \unlink (filepath) ->
    relative-path = path.relative src-path, filepath
    js-file = path.join lib-path, (relative-path.replace '.ls', '.js')
    map-file = js-file + \.map
    fs.remove js-file
    fs.remove map-file

compiler = {}
Object.define-property compiler, \watch,
    get: -> watching
    set: set-watching


module.exports = compiler
