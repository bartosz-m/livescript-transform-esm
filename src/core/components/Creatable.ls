require! {
    \./symbols : { create, init }
}

module.exports = Creatable =
    (create): (arg) ->
        ^^@
            ..[init] arg