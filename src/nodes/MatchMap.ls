import 
    \js-nodes/symbols : { copy }
    \js-nodes/TrueNode
    \js-nodes/identity
    
    
export default MatchMap = ^^null
MatchMap <<<
    name: \MatchMap
    match: TrueNode.as-function

    map: identity
        
    exec: ->
        if matched = @match ...&
            @map.call @, matched

    (copy): -> ^^@