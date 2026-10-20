
# Apply a variable label without messing with a variable's class.
`inline_label<-` <- function(x, value) {
  attr(x, "label") <- value
  x
}





# Copy variable labels from one dataframe to a named list, omitting variables
# with no label.
save_varlabels <- function(df) {
  all_labels <-
    Filter(
      function(this_var) { !is.null(this_var) },

      Map(
        function(this_var) { attr(this_var, "label") },
        df
      )
    )

  return(all_labels)
}




# Copy variable labels from multiple dataframes to a named list, omitting
# duplicates and variables with no label.
save_all_varlabels <- function(...) {
  dfs <- list(...)

  result <-
    Reduce(
      append,

      Map(
        save_varlabels,
        dfs
      )
    )

  return(result[!duplicated(names(result))])
}





# Apply saved variable labels to a dataframe. Skips variables that aren't in
# the dataframe.
load_varlabels <- function(df, savedlabs) {
  for (this_var in names(savedlabs)) {
    if (!is.null(df[[this_var]])) {
      inline_label(df[[this_var]]) <- savedlabs[[this_var]]
    }
  }

  return(df)
}
