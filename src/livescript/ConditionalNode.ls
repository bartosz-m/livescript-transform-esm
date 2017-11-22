ConditionalNode = module.exports = ^^null
ConditionalNode <<<
    name: \ConditionalNode
    
    next: 
        process: !->
        copy: -> ^^@
    
    condition: 
        process: -> true
        copy: -> ^^@
        
    process: (value) ->
        try
          if @condition.process value
              @next.process value
        catch
            e.message = "#{e.message} at node #{@name}"
            throw e
    
    copy: ->
        ^^@
            ..condition = @condition.copy!
            ..next = @next.copy!