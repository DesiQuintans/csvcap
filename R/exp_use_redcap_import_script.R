
#' Edit and run a REDCap R import script
#'
#' When you export data from REDCap using the "R Statistical Software" export
#' format, it provides two files: A .CSV spreadsheet which is the raw data, and
#' a .R script which imports that spreadsheet into R. In my opinion and
#' experience, this script produces problems later in the analysis. This
#' function loads the import script, edits it to remove these problems, saves it
#' to a temporary file in the same directory as the original, and then
#' runs it.
#'
#' The specific changes this function makes to the import script are:
#'
#' - Removes `rm(list=ls())` and `graphics.off()`.
#' - Adds control of missing value detection to the [utils::read.csv()] call.
#'   By default, empty strings ("") or strings with only a space (" ") were
#'   not treated as `NA`, and this fixes that. Other values like "Not Available"
#'   and "\[not completed\]" are also converted to `NA`.
#' - Replaces use of `Hmisc::label()` with an internal function. `Hmisc`
#'   adds a 'labelled' class to the variables after labelling, which can create
#'   Errors later on. The most common Error from this is when trying to
#'   `pivot_longer()` variables which were labelled with `Hmisc::label()` on
#'   top of variables which were not.
#' - Moreover, labelling is performed as the last step to ensure that labels
#'   are not overwritten.
#' - Stops the creation of `.factor` copies of variables, e.g. `xyz` and
#'   `xyz.factor`. This makes the dataset agree more closely with the data
#'   dictionary and makes it possible to collect the variables associated with
#'   specific instruments based on their positions within the larger dataset.
#' - Disables saving through [base::saveRDS()] or [base::save()], returning the
#'   object instead.
#'
#'
#' @param path (Character) Path to the REDCap .R import script.
#' @param na.strings (Character) Vector of values that will be interpreted as `NA`.
#' @param cleanup (Logical) If `TRUE` (default), tries to clean up the temporary
#'   edited REDCap import script. If `FALSE`, leaves the temporary file there so
#'   that it can be inspected.
#'
#' @returns A Dataframe.
#' @md
#' @export
use_redcap_import_script <- function(path,
                                     na.strings = c("", " ", "na", "NA", "N/A", "N / A", "N A", "Not Available", "[not completed]"),
                                     cleanup = TRUE) {
  na.strings <- deparse1(na.strings)

  if (!file.exists(path)) {
    stop("The input file `", path, "` does not exist.")
  }


  # 0. The REDCap import script creates an object called `data`. I will
  # initialise it to avoid issues in R CMD CHECK. I know that this masks
  # a base R function; blame REDCap!
  data <- data.frame()


  # 1. Read the file in line-by-line.
  origfile <- readLines(path, warn = FALSE)


  # 2. Separate code that performs import/transform from code that does
  # labelling. The labelling code appears first in the REDCap import script, but
  # it actually needs to be run last or else variables that are converted to
  # Factor by the script will have no label.
  import_lines <- grepv(pattern = "label(", x = origfile, fixed = TRUE, invert = TRUE)
  labels_lines <- grepv(pattern = "label(", x = origfile, fixed = TRUE, invert = FALSE)


  # 3. Apply modifications to import/transform code.
  # HALT() is a utility function that returns nothing, i.e. it disarms a function.
  import_lines <- gsub("rm(list=ls())",  "",      import_lines, fixed = TRUE)
  import_lines <- gsub("graphics.off()", "",      import_lines, fixed = TRUE)
  import_lines <- gsub("library(Hmisc)", "",      import_lines, fixed = TRUE)
  import_lines <- gsub(".factor",        "",      import_lines, fixed = TRUE)
  import_lines <- gsub("saveRDS(",       "HALT(", import_lines, fixed = TRUE)
  import_lines <- gsub("save(",          "HALT(", import_lines, fixed = TRUE)

  # Replacing the entire read.csv() call with a HALT() because it may have been
  # modified by someone across multiple lines. I insert my own read.csv() call
  # right in front of the HALT()ed version.
  import_lines <-
    gsub(
      pattern     = 'read.csv\\(\\"(.*?)\\"',
      replacement = sprintf('read.csv("\\1", na.strings = %s); HALT(', na.strings),
      x           = import_lines,
      fixed       = FALSE
    )


  # 4. Apply modifications to labelling code.
  labels_lines <- gsub("label(",  "inline_label(", labels_lines, fixed = TRUE)


  # 3. Save the modified code to temporary files and source them.
  # Note that the file needs to be saved in the same directory as the original
  # import script, since the script assumes the data are alongside it.
  import_lines_file <- tempfile(tmpdir = dirname(path), fileext = ".R")
  labels_lines_file <- tempfile(tmpdir = dirname(path), fileext = ".R")

  writeLines(import_lines, import_lines_file)
  writeLines(labels_lines, labels_lines_file)

  if (!file.exists(import_lines_file)) {
    cli::cli_abort(
      "x" = "A temporary version of the edited import script could not be saved.",
      "!" = "Write access is required to the path:",
      dirname(path)
    )
  }

  if (!file.exists(labels_lines_file)) {
    cli::cli_abort(
      "x" = "A temporary version of the edited import script could not be saved.",
      "!" = "Write access is required to the path:",
      dirname(path)
    )
  }

  source(file = import_lines_file, local = TRUE, verbose = FALSE, chdir = TRUE)
  source(file = labels_lines_file, local = TRUE, verbose = FALSE, chdir = TRUE)


  if (cleanup) {
    # 4. Clean up by deleting the temporary file.
    file.remove(import_lines_file)
    file.remove(labels_lines_file)
  }

  return(invisible(data))
}
