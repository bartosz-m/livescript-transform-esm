export copy-source-location = (source, target) !->
    if target.line?
        return
    {first_line,first_column,last_line,last_column,line,column,filename}  = source
    target <<< {first_line,first_column,last_line,last_column,line,column,filename}