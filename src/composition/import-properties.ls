{ define-properties, get-own-property-descriptors } = Object

import-properties = (target, ...sources) ->
    for source in sources
        descriptor = get-own-property-descriptors source
        keys = (Object.keys descriptor) ++ Object.get-own-property-symbols descriptor
        only-enumerable = { [k,v] for k in keys when (v = descriptor[k]).enumerable }
        define-properties target, only-enumerable
    target
    
module.exports =  import-properties