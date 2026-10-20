
#' Split instruments from a downloaded REDCap dataset
#'
#' @param rcdata (Dataframe) A REDCap dataset.
#' @param locations (Dataframe) A dataframe of instruments and column locations. See [find_instruments()].
#'
#' @returns A named List of dataframes. The names are the names of each
#'   instrument, and the dataframes contain the variables associated with
#'   the instruments. REDCap metadata fields are always included.
#'
#' @export
#' @md
split_instruments <- function(rcdata, locations) {
  # 1. Find the positions of REDCap metadata fields. These are always included
  # in the isolated instruments.
  noninstr_cols_loc <- redcap_metadata_fields(rcdata)

  # 2. Find the positions of the instrument variables themselves.
  # `locations` has the start and end of each instrument. I specifically chose
  # NOT to calculate it inside this function because I want the user to generate
  # the table themselves with `find_instruments()` so that they are forced to
  # ensure it's correct.

  # 3. For each instrument, extract the variables.
  splits <-
    Map(
      function(instr, instr_start, instr_end) {
        instr_cols_loc <- instr_start:instr_end

        this_instr <- rcdata[, c(noninstr_cols_loc, instr_cols_loc)]
        this_instr <- omit_empty_rows(this_instr, start = length(noninstr_cols_loc) + 1)

        return(this_instr)
      },

      locations$instrument,
      locations$start,
      locations$end
    )


  # 4. Return the isolated instruments in a list.
  return(splits)
}
