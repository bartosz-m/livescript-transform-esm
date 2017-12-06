var { copy } = require('js-nodes/symbols');
var TrueNode = (require('js-nodes/TrueNode')['__default__'] || require('js-nodes/TrueNode'));
var identity = (require('js-nodes/identity')['__default__'] || require('js-nodes/identity'));
var MatchMap;
module.exports = MatchMap = clone$(null);
Object.defineProperty(module.exports, '__default__', {enumerable:false, value: module.exports});
MatchMap.name = 'MatchMap';
MatchMap.match = TrueNode.asFunction;
MatchMap.map = identity;
MatchMap.exec = function(){
  var matched;
  if (matched = this.match.apply(this, arguments)) {
    return this.map.call(this, matched);
  }
};
MatchMap[copy] = function(){
  return clone$(this);
};
function clone$(it){
  function fun(){} fun.prototype = it;
  return new fun;
}
//# sourceMappingURL=MatchMap.js.map
