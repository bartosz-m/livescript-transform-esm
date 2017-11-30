require! {
    \./symbols : { copy }
}

AbstractNode = module.exports = ^^null
AbstractNode <<<
    (copy): -> throw Error "Cannot copy. Node doesn't implement method copy"
