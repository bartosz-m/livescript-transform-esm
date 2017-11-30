import 
    \livescript-compiler/lib/nodes/symbols : { copy }
    \livescript-compiler/lib/nodes/TrueNode
    \livescript-compiler/lib/nodes/identity
    
    
export default MatchMap = ^^null
MatchMap <<<
    name: \MatchMap
    match: TrueNode.as-function

    map: identity
        
    exec: ->
        if matched = @match ...&
            @map.call @, matched

    (copy): -> ^^@