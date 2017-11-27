require! {
    \./symbols : { copy }
    \./nop
    \./TrueNode
    \./components/Copiable
}

IfNode = module.exports = ^^null
IfNode <<< Copiable
IfNode <<<
    name: \IfNode
    nodes-names: <[ test then else ]>
    test: TrueNode.as-function
    then: nop
    else: nop
    
    apply: (this-arg, args) ->
        if @test.apply this-arg, args
        then @then.apply this-arg, args
        else @else.apply this-arg, args
    
    call: (this-arg, ...args) ->
        if @test.apply this-arg, args
        then @then.apply this-arg, args
        else @else.apply this-arg, args
      
    exec: ->
        if @test ...&
        then @then ...&
        else @else ...&