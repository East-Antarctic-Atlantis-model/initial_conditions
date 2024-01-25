harvest_ini <- function(nc_file, calculate_mean = FALSE, fillVal = FALSE, output_file = 'IniCond', exclude_row = NULL) {
  nc <- nc_open(nc_file)
  var2d <- NULL
  fillvalue <- NULL
  var_names <- names(nc[['var']])
  
  for (i in 1:length(var_names)) {
    var_tmp <- ncvar_get(nc, var_names[i])
    fillvalue <- c(fillvalue, ncatt_get(nc, var_names[i], "_FillValue")$value)
    
    if (length(dim(var_tmp)) >= 2) {
      if (!is.null(exclude_row)) {
        var_tmp <- var_tmp[-exclude_row, , drop = FALSE]
      }
      
      if (calculate_mean) {
        var_tmp[var_tmp == 0] <- NA
        temp2d <- colMeans(var_tmp, na.rm = TRUE)
      } else {
        temp2d <- colSums(var_tmp, na.rm = TRUE)
      }
      
      var2d <- cbind(var2d, temp2d)
    } else {
      var2d <- cbind(var2d, var_tmp)
    }
  }
  
  colnames(var2d) <- var_names

  fillvalue = data.frame(Variables = var_names, fillvalues = fillvalue)
  if(fillVal){
      write.table(fillvalue, paste0(output_file, 'FillValues.csv'), row.names = FALSE, sep = ',')
      cat(paste('File with default values has been created\n'))
      }

  if (calculate_mean) {
    output_file <- paste0(output_file, '_Means.csv')
  } else if(fillVal){
    output_file <- paste0(output_file, '_Sums.csv')
  }

  write.table(var2d, output_file, row.names = FALSE, sep = ',')
  cat(paste('File', output_file, 'has been created\n'))
}