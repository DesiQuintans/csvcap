
#' Left-join instruments to each other
#'
#' @param ... (Dataframes) Instruments to join, usually elements from [split_instruments()].
#' @param .exclude (Character) A vector of column names to exclude from all of
#'   the instruments before joining. For example, the metadata column "redcap_repeat_instance" is
#'   not relevant when you are joining non-repeating instruments.
#' @param .check_ratio (Logical) If `TRUE` (default), instruments will only be joined
#'   if they have the same row-to-ID ratio (for example, if they are all one-row-per-person). If `FALSE`,
#'   this check will not be made.
#'
#' @returns A Dataframe.
#' @export
join_instruments <- function(..., .exclude = character(), .check_ratio = TRUE) {
  dotsnames <- as.character(eval(substitute(alist(...))))
  dfs <- list(...)
  names(dfs) <- dotsnames


  # 1. If requested, ensure that the instruments have the same row-to-ID ratio.
  if (.check_ratio == TRUE) {
    row_id_ratio <- calculate_row_id_ratio(dfs)

    if (length(unique(row_id_ratio$ratio)) != 1) {
      instrmaxlength <- max(nchar(row_id_ratio$instrument))
      sprintf_format <- paste0("%", instrmaxlength, "-s %s")

      stop(
        cli::format_error(c(
                "Did not allow the join to go ahead.",
          "x" = "Not all of the instruments had the same row-to-ID ratio.",
          "i" = "To ignore this check and force the join, use {.code .check_ratio = FALSE}.",
                "",
                "The row-to-ID ratios were:",
                "",

          sprintf(
            sprintf_format,
            row_id_ratio$instrument,
            row_id_ratio$ratio_chr
          )
        ))
      )
    }
  }


  # 2. Omit the columns that were requested from each instrument.
  dfs <-
    Map(
      function(this_instr) {
        dplyr::select(this_instr, -dplyr::any_of(.exclude))
      },

      dfs
    )


  # 3. Get the base dataset out of the instruments provided.
  common_cols <- Reduce(intersect, Map(colnames, dfs))

  basedata <-
    Reduce(
      dplyr::bind_rows,

      Map(
        function(this_instr) {
          dplyr::select(this_instr, dplyr::all_of(common_cols))
        },

        dfs
      )
    )

  basedata <- dplyr::distinct(basedata)


  # 4. Left-join the instruments.
  result <-
    Reduce(
      function(x, y) {
        dplyr::left_join(
          x = x,
          y = y,
          by = common_cols
        )
      },

      append(list(.basedata = basedata), dfs)
    )


  # 5. Done!
  return(result)
}
