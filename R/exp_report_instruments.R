
#' Report instruments found in REDCap dataset
#'
#' @param splits (List) The result of [split_instruments()].
#'
#' @returns Nothing, but prints tables to the console.
#' @md
#' @export
report_instruments <- function(splits) {
  # 1. Calculate the ratio of rows to unique person identifiers.
  ratio_row_id <- calculate_row_id_ratio(splits)


  # 2. Separate the instruments into types:
  # - One-Time ORPP: 1 instance collected at 1 event
  # - Repeated ORPP: 1 instance collected at ≥2 events
  # - One-Time MRPP: ≥2 instances collected at 1 event
  # - Repeated MRPP: ≥2 instances collected at ≥2 events
  #
  # Note that for `n_events` and `max_instances`, the test is for `<= 1` and not `== 0`.
  # I did this because I encountered a REDCap project that was entirely for backend use
  # by the study staff, so no events were set up for it.
  onetime_orpp <- ratio_row_id[ratio_row_id$n_events <= 1 & ratio_row_id$max_instances <= 1, ]
  onetime_mrpp <- ratio_row_id[ratio_row_id$n_events <= 1 & ratio_row_id$max_instances  > 1, ]

  repeated_orpp <- ratio_row_id[ratio_row_id$n_events > 1 & ratio_row_id$max_instances <= 1, ]
  repeated_mrpp <- ratio_row_id[ratio_row_id$n_events > 1 & ratio_row_id$max_instances  > 1, ]


  report_table <- function(df, tabledesc) {
    cli_input <-
      data.frame(
        cell1 = df$instrument,
        cell2 = df$ratio_chr
      )

    x <- cli::ansi_columns(
      text =
        c(
          cli::style_underline(cli::style_bold("Instrument")),
          cli_input$cell1,
          cli::style_underline(cli::style_bold("Records-to-IDs Ratio")),
          cli_input$cell2
        ),
      fill = "cols",
      max_cols = 2,
      align = "left",
      sep = "    "
    )

    cli::cat_boxx(
      x,
      border_style = "none",
      padding = 1,
      margin  = 0,
      header  = cli::style_underline(cli::style_bold(cli::col_green(tabledesc))),
      background_col = "grey99"
    )
  }

    report_table(onetime_orpp, tabledesc = "One-Time ORPP (1 instance collected at 1 event)")
    report_table(repeated_orpp, tabledesc = "Repeated ORPP (1 instance collected at \u22652 events)")

    report_table(onetime_mrpp, tabledesc = "One-Time MRPP (\u22652 instances collected at 1 event)")
    report_table(repeated_mrpp, tabledesc = "Repeated MRPP (\u22652 instances collected at \u22652 events)")

  return(invisible(NULL))
}
