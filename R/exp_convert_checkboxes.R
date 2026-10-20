
#' Convert checkboxes and radio buttons to Logical
#'
#' This function automatically converts columns that meet the strict definitions
#' of checkboxes and radio buttons, being:
#'
#' 1. A column whose only possible values are "Yes", "No", or `NA`.
#' 2. A column whose only possible values are "Checked", "Unchecked", or `NA`.
#' 3. A column whose only possible values are "1", "0", or `NA`.
#' 4. A column with a name containing "___1", "___2", etc. which is how REDCap
#'    represents checkboxes in an exported dataset.
#'
#' Columns that don't meet these criteria can be converted using the
#' `include` argument. Columns that are entirely `NA` or named in the `exclude`
#' argument will not be modified by this function.
#'
#'
#' @param df (Dataframe) A dataframe.
#' @param include (Character) Names of columns to force conversion to Logical.
#' @param exclude (Character) Names of columns that will not be converted even if they meet the criteria.
#' @param trues (Character) Values that will be regarded as `TRUE`.
#' @param falses (Character) Values that will be regarded as `FALSE`.
#' @param nas (Character) Values that will be regarded as `NA`.
#' @param quiet (Logical) If FALSE (default), report which columns are being changed.
#'
#' @returns An edited version of `df` (invisibly).
#' @export
#'
#' @examples
#' test_data <-
#'   data.frame(
#'     yesno  = c("Yes", "No", NA),
#'     check  = c("Unchecked", "Checked", NA),
#'     compl  = c("Complete", "Incomplete", NA),
#'     nums   = c("1", "0", NA),
#'     ignore = c("Y", "N", NA)
#'   )
#'
#' convert_checkboxes(test_data)
#' convert_checkboxes(test_data, include = "ignore")
convert_checkboxes <- function(df,
                               include = character(0),
                               exclude = c("redcap_repeat_instrument", "redcap_repeat_instance", "redcap_survey_identifier"),
                               trues   = c("Yes", "Checked", "Y", "1", "Complete"),
                               falses  = c("No", "Unchecked", "N", "0", "Incomplete"),
                               nas     = c("NA", "", " ", "-", "Unknown", "Unverified"),
                               quiet   = FALSE) {
  stopifnot(
    "The `include` argument names columns that are not in the dataframe." =
      identical(setdiff(include, colnames(df)), character(0))
  )

  saved_labels <- save_varlabels(df)

  allmissing_cols <-
    names(
      Filter(
        isTRUE,

        Map(
          function(this_col) {
            all(is.na(this_col))
          },

          df
        )
      )
    )

  yesno_cols <-
    names(
      Filter(
        isTRUE,

        Map(
          function(this_col) {
            any(
              identical(setdiff(na.omit(unique(this_col)), c("Yes",      "No")),         character(0)),
              identical(setdiff(na.omit(unique(this_col)), c("Checked",  "Unchecked")),  character(0)),
              identical(setdiff(na.omit(unique(this_col)), c("1",        "0")),          character(0))
            )
          },

          df
        )
      )
    )

  cols_with_namingconvention <- grepv("___", colnames(df))

  cols_for_conversion <- unique(c(yesno_cols, cols_with_namingconvention, include))
  cols_for_conversion <- setdiff(cols_for_conversion, exclude)
  cols_for_conversion <- setdiff(cols_for_conversion, allmissing_cols)

  for (this_col in cols_for_conversion) {
    df[[this_col]] <-
      dplyr::case_when(
        is.na(df[[this_col]])      ~ NA,
        df[[this_col]] %in% nas    ~ NA,
        df[[this_col]] %in% trues  ~ TRUE,
        df[[this_col]] %in% falses ~ FALSE,

        .default = NA
      )
  }

  df <- load_varlabels(df, saved_labels)

  if (!quiet) {
    message(
      "These columns were converted to TRUE/FALSE/NA:",
      "\n\n",
      sprintf("- %s\n", intersect(colnames(df), cols_for_conversion))  # So that they're listed in order of occurrence.
    )

    if (length(allmissing_cols) > 0) {
      message(
        "These columns were not converted because they were entirely NA already:",
        "\n\n",
        sprintf("- %s\n", intersect(colnames(df), allmissing_cols))  # So that they're listed in order of occurrence.
      )
    }
  }

  return(invisible(df))
}

