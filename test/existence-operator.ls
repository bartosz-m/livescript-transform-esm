test = (v) -> v?length

# Maximum call stack size exceeded
# RangeError: Maximum call stack size exceeded
#     at SourceNode_toString [as toString] (/home/bartek/Projekty/ehelon/livescript-plugins/transform-esm/node_modules/source-map/lib/source-node.js:318:61)
#     at Array.join (native)
#     at ctor$.exports.Existence.Existence.compileNode (/home/bartek/Projekty/ehelon/livescript-plugins/transform-esm/node_modules/livescript/lib/ast.js:3003:52)
#     at ctor$.compile (/home/bartek/Projekty/ehelon/livescript-plugins/transform-esm/node_modules/livescript/lib/ast.js:199:40)
#     at ctor$.exports.If.If.compileExpression (/home/bartek/Projekty/ehelon/livescript-plugins/transform-esm/node_modules/livescript/lib/ast.js:4313:33)
#     at ctor$.exports.If.If.compileNode (/home/bartek/Projekty/ehelon/livescript-plugins/transform-esm/node_modules/livescript/lib/ast.js:4285:19)
#     at Chain.compile (/home/bartek/Projekty/ehelon/livescript-plugins/transform-esm/node_modules/livescript/lib/ast.js:199:40)
#     at ctor$.exports.If.If.compileExpression (/home/bartek/Projekty/ehelon/livescript-plugins/transform-esm/node_modules/livescript/lib/ast.js:4315:44)
#     at ctor$.exports.If.If.compileNode (/home/bartek/Projekty/ehelon/livescript-plugins/transform-esm/node_modules/livescript/lib/ast.js:4285:19)
#     at Chain.compile (/home/bartek/Projekty/ehelon/livescript-plugins/transform-esm/node_modules/livescript/lib/ast.js:199:40)