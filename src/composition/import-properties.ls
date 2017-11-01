{ define-properties, get-own-property-descriptors } = Object

import-properties = (target, ...sources) ->
    for source in sources
        define-properties target, get-own-property-descriptors source
    target
    
module.exports =  import-properties