export args-length = (expected-count, args) !-->
    unless args.length == expected-count
        throw Error "There should be exacly #{expected-count} arguments but got #{args.length}"

export has-method = (method, object) !-->
    switch type = typeof! object[method]
    | 'Function' => return # wszystko wporządku wieć wracamy
    | 'Undefined' 'Null' => throw Error "[#{object@@name}] doesn't have property #{method}"
    | otherwise =>  throw Error "[#{object@@name}].#{method} should be Function but is a #{type}"

export is-array = (a, label = "[#{typeof! a}]") ->
    unless 'Array' == type = typeof! a
        throw Error "#{label} isn't Array"

export is-defined = (value, name) !->
    unless value?
        throw Error "#{name} must be defined"

export has-iterator = (o, name = "#{o@@name}")!->
    unless o[Symbol.iterator]
        throw Error "#{name} doesn't have iterator"
