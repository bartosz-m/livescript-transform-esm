require! {
    \source-map
}

class SourceNode extends source-map.SourceNode
    module.exports = @
    !->
        super ...
        
    replace: (...args) ->
        new SourceNode @line, @column, @source, [..replace(...args) for @children], @name
    
    set-file = (filename) ->
        @source = filename
        for child in @children when child instanceof SourceNode
            child.set-file filename

    to-string-with-source-map: (...args) ->
        gen = new source-map.SourceMapGenerator ...args
        gen-line = 1
        gen-column = 0
        stack = []
        code = ''
        debug-output = ''
        debug-indent = ''
        debug-indent-str = '  '

        gen-for-node = (node) ->
            if node instanceof SourceNode
                debug-output += debug-indent + node.display-name
                # Block nodes should essentially "clear out" any effects
                # from parent nodes, so always add them to the stack
                valid = node.line and 'column' of node
                if valid
                    stack.push node
                    debug-output += '!'
                debug-output += " #{node.line}:#{node.column} #{gen-line}:#{gen-column}\n"

                debug-indent += debug-indent-str
                for child in node.children
                    gen-for-node child
                debug-indent := debug-indent.slice 0, debug-indent.length - debug-indent-str.length

                if valid
                    stack.pop!
            else
                debug-output += "#{debug-indent}#{ JSON.stringify node }\n"
                code += node
                cur = stack[*-1]
                if cur
                    gen.add-mapping do
                        source: cur.source
                        original:
                            line: cur.line
                            column: cur.column
                        generated:
                            line: gen-line
                            column: gen-column
                        name: cur.name
                for i til node.length
                    c = node.char-at i
                    if c == "\n"
                        gen-column := 0
                        ++gen-line
                        if cur
                            gen.add-mapping do
                              source: cur.source
                              original:
                                  line: cur.line
                                  column: cur.column
                              generated:
                                  line: gen-line
                                  column: gen-column
                              name: cur.name
                    else
                        ++gen-column

        gen-for-node(this)
        {code: code, map: gen, debug: debug-output}
    
    @from-source-node = ->
        it with @{replace,set-file, to-string-with-source-map}