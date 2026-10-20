
# A function that returns nothing.
# Use this by find-replacing unwanted function names with "HALT".
HALT <- function(...) { return(NULL) }





# Remove empty rows from dataframes. Only columns between start:end
# are considered. Labels are saved and then reapplied at the end of
# this process because `[` removes attributes.
omit_empty_rows <- function(df, start = 1, end = NULL) {
  if(is.null(end)) {
    end <- ncol(df)
  }

  # Omit empty rows
  empty_row <- rowSums(is.na(df[, start:end])) == length(start:end)
  result <- df[!empty_row, ]

  # Re-apply variable labels that were removed by the `[` function.
  saved_labels <- save_varlabels(df)
  result <- load_varlabels(result, saved_labels)

  return(result)
}





# Returns a Character vector of REDCap metadata fields that are actually in
# the dataset. As a bonus, returns the name of the identifier as the first
# element (it is not always `record_id`).
redcap_metadata_fields <- function(rcdata) {
  # The first variable is always the identifier.
  # Subsequent metadata fields may or may not be present, e.g.
  # `redcap_survey_identifier` is only present in some project structures, and
  # `redcap_data_access_group` has a no-export option associated with it.

  possible_names <-
    c(
      colnames(rcdata)[[1]],
      "redcap_event_name",
      "redcap_repeat_instrument",
      "redcap_repeat_instance",
      "redcap_survey_identifier",
      "redcap_data_access_group"
    )


  # Note that the code below retrieves and returns columns in the order they
  # appear in the dataset.
  cols_present  <- possible_names[which(possible_names %in% colnames(rcdata))]
  col_positions <- which(colnames(rcdata) %in% cols_present)

  stats::setNames(object = col_positions, nm = colnames(rcdata)[col_positions])
}





# Returns a dataframe of instruments, the number of rows/identifiers/events in
# them, and the ratio of rows to identifiers.
calculate_row_id_ratio <- function(splits) {
  Reduce(
    rbind,

    Map(
      function(instrname, this_df) {
        result <-
          data.frame(
            instrument = instrname,
            n_rows     = nrow(this_df),
            n_units    = length(stats::na.omit(unique(unlist(this_df[, 1])))),
            n_events   = length(stats::na.omit(unique(this_df$redcap_event_name))),
            max_instances =
              ifelse(
                all(is.na(this_df$redcap_repeat_instance)),
                1,
                max(this_df$redcap_repeat_instance, na.rm = TRUE)
              )
          )

        result$ratio <- ifelse(result$n_units <= 0, 0, result$n_rows / result$n_units)
        result$ratio_chr <-
          sprintf(
            "%.3f (%i / %i)",
            result$ratio,
            result$n_rows,
            result$n_units
          )

        return(result)
      },

      names(splits),
      splits
    )
  )
}
