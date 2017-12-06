var copySourceLocation;
exports.copySourceLocation = copySourceLocation = function(source, target){
  var first_line, first_column, last_line, last_column, line, column, filename, children, i$, len$, child;
  if (target.line != null) {
    return;
  }
  first_line = source.first_line, first_column = source.first_column, last_line = source.last_line, last_column = source.last_column, line = source.line, column = source.column, filename = source.filename;
  if (line == null) {
    first_line = line = 10000000000;
    first_column = column = 10000000000;
    last_line = -1;
    last_column = -1;
    children = source.getChildren();
    for (i$ = 0, len$ = children.length; i$ < len$; ++i$) {
      child = children[i$];
      if (child.line != null) {
        line = first_line = Math.min(line, child.line);
      }
      if (child.first_line != null) {
        line = first_line = Math.min(line, child.first_line);
      }
      if (child.column != null) {
        column = first_column = Math.min(column, child.column);
      }
      if (child.first_column != null) {
        column = first_column = Math.min(column, child.first_column);
      }
      if (child.line != null) {
        last_line = Math.max(last_line, child.line);
      }
      if (child.last_line != null) {
        last_line = Math.max(last_line, child.last_line);
      }
      if (child.column) {
        last_column = Math.max(last_column, child.column);
      }
      if (child.last_column) {
        last_column = Math.max(last_column, child.last_column);
      }
      filename = filename || child.filename;
    }
  }
  target.first_line = first_line;
  target.first_column = first_column;
  target.last_line = last_line;
  target.last_column = last_column;
  target.line = line;
  target.column = column;
  target.filename = filename;
};
//# sourceMappingURL=utils.js.map
