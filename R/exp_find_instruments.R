
#' Find instruments in a REDCap dataset.
#'
#' @param rcdata (Dataframe) A REDCap dataset.
#' @param ignore (Character) Column names that should be ignored when identifying instruments. See Details.
#'
#' @details
#' REDCap adds a `"..._complete"` variable to the dataset at the end of every
#' instrument, e.g. a column called `consent_complete` is inserted after all of
#' the variables in the `consent` instrument. This function finds instruments by
#' looking for any variable ending with `"_complete"`. If your REDCap designers
#' have named any of their survey variables in this way, then add those variable
#' names to the `ignore` argument.
#'
#' @returns A dataframe, where `instrument` is the name of the instrument,
#'   `start` is the column number of the first variable in the instrument, and
#'   `end` is the column number of the last variable (i.e. the instrument's
#'   `"_complete"` marker). The actual names of the columns at the `start` and
#'   `end` positions are also added to this dataframe for sanity checking.
#' @md
#' @export
find_instruments <- function(rcdata, ignore = character()) {
  # 0. Get the positions of metadata columns.
  metadata_pos <- redcap_metadata_fields(rcdata)

  # 1. Get the positions of all instrument markers. All instruments are marked
  # with a column whose name ends with "_complete", e.g. `consent_complete` for
  # the "consent" instrument. Columns in the `ignore` list should be omitted,
  # e.g. if a REDCap administrator has ended some of their variable names with
  # "_complete".
  instrument_cols <- grep(pattern = "_complete$", x = colnames(rcdata), value = TRUE)
  instrument_cols <- instrument_cols[!(instrument_cols %in% ignore)]
  instrument_cols

  # 2. Get column locations of these instrument markers.
  locs <-
    which(colnames(rcdata) %in% instrument_cols) |>
    stats::setNames(gsub("_complete", "", instrument_cols)) |>
    sort()

  # 3. Return locations of instruments. The `start` column shows the position of
  # the first variable in the instrument, and the `end` column is the position
  # of the "_complete" marker.
  result <-
    data.frame(
      instrument = names(locs),
      start      = c(max(metadata_pos) + 1, (locs[seq_along(locs) - 1]) + 1),
      end        = locs
    )

  rownames(result) <- NULL

  # 4. For sanity-checking, add what the names of the first and last cols
  # actually are.
  result$start_colname <- colnames(rcdata)[result$start]
  result$end_colname   <- colnames(rcdata)[result$end]


  # 5. Specifically warn about empty instruments.
  empty_instruments <- result[result$start == result$end, ]
  if (nrow(empty_instruments) > 0) {
    warning(
      "\n  These variables seem to point to empty instruments.\n",
      "  You may want to add them to the `ignore` list.\n\n",
      paste(paste0("    - ", empty_instruments$instrument, "_complete"), sep = "\n"),
      call. = FALSE,
      immediate. = TRUE
    )
  }


  return(result)
}
