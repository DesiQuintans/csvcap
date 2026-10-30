
<!-- README.md is generated from README.Rmd. Please edit that file -->

# csvcap

<!-- badges: start -->

<!-- badges: end -->

This package provides tools for importing and working with REDCap
projects that were exported using the “R Statistical Software” export
format (i.e. as a flat ‘CSV’ file paired with a REDCap-generated R
script for R).

It provides functions for fixing REDCap’s import script, separating
instruments from each other, looking at the structure of those
instruments, and combining instruments that have similar structures.

## Installation

You can install the development version of csvcap from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("DesiQuintans/csvcap")
```

## Functions included

| Function | Usage |
|----|----|
| `use_redcap_import_script()` | Edits and runs a REDCap-generated R import script. |
| `convert_checkboxes()` | Converts checkbox and radio button variables to `TRUE` and `FALSE`. |
| `find_instruments()` | Find column positions of instruments in the dataset. |
| `split_instruments()` | Split the dataset into instruments, based on column positions found previously. |
| `report_instruments()` | Report the shape and collection frequency of each instrument. |
| `join_instruments()` | Join instruments together. |

# Example

The idea behind `csvcap` is to split the large REDCap dataset into
individual instruments. This is because each instrument can be presented
to different sets of people at different timepoints, either repeating or
not repeating, and for different purposes (e.g. a participant survey
versus a back-of-office form used only by study staff).

Once the instruments are separated, they can be individually cleaned and
then re-joined in ways that make sense for your analysis. For example, I
like to have 3 dataframes per project:

1.  The main one-row-per-person dataset. Everything that was asked only
    once per person goes here. This is used for descriptive statistics.
2.  A scheduled-repeats dataset, where each row is a person+timepoint
    and each column is a variable from a scheduled repeating instrument,
    e.g. 1-year follow-up, 2-year follow-up, etc. This is useful for
    modelling, especially time-varying modelling.
3.  An unscheduled-repeats dataset, where repeating instruments that
    were collected without a fixed schedule go.

## Step 1. Import the data

REDCap’s auto-generated R import script does some annoying things, which
this package solves with:

``` r
mydata <- use_redcap_import_script("../Raw_data/MyProject_R_2024-05-19_0931.r")
```

This does a few things:

- Removes `rm(list=ls())` and `graphics.off()`.
- Adds control of missing value detection to the \[utils::read.csv()\]
  call. By default, empty strings (`""`) or strings with only a space
  (`" "`) were not treated as `NA`, and this fixes that. Other values
  like `"Not Available"` and `"[not completed]"` are also converted to
  `NA`.
- Replaces use of `Hmisc::label()` with an internal function. `Hmisc`
  adds a ‘labelled’ class to the variables after labelling, which can
  create Errors later on. The most common Error from this is when trying
  to `pivot_longer()` variables which were labelled with
  `Hmisc::label()` on top of variables which were not.
- Moreover, labelling is performed as the last step to ensure that
  labels are not overwritten.
- Stops the creation of `.factor` copies of variables, e.g. `xyz` and
  `xyz.factor`. This makes the dataset agree more closely with the data
  dictionary and makes it possible to collect the variables associated
  with specific instruments based on their positions within the larger
  dataset.
- Returns the dataframe instead of saving through `saveRDS()` or
  `save()`.

You can also convert checkboxes and radio buttons to `TRUE/FALSE/NA`
automatically, which I think makes them easier to program with.

``` r
mydata <- convert_checkboxes(mydata)
```

## Step 2. Locate instruments

The columns of every REDCap dataset are actually the variables of each
instrument, in the order of their appearance in forms. REDCap inserts a
variable ending with `_complete` to mark the end of each instrument: the
variable `eligibility_complete`, for example, marks the end of the
instrument called `eligibility` and the start of the next instrument.

``` r
instr_locs <- find_instruments(mydata)
instr_locs

#>                instrument start end                    start_colname                     end_colname
#> 1        eligibility_form     7  25                 eligib_inclu_age       eligibility_form_complete
#> 2         medical_history    26  89                              sex        medical_history_complete
#> 3                 consent    90 104                consent_timestamp                consent_complete
#> 4           baseline_ecrf   105 119          baseline_ecrf_timestamp          baseline_ecrf_complete
#> 5      participant_survey   120 147     participant_survey_timestamp     participant_survey_complete
#> 6                   afeqt   148 171                  afeqt_timestamp                  afeqt_complete
#> 7                    jakq   172 192                   jakq_timestamp                   jakq_complete
#> 8                     tbq   193 209                    tbq_timestamp                    tbq_complete
#> 9              calm_scale   210 227             calm_scale_timestamp             calm_scale_complete
#> 10          randomisation   228 229              randomisation_group          randomisation_complete
#> 11 user_experience_survey   230 246 user_experience_survey_timestamp user_experience_survey_complete
```

Inspect this output together with your project’s REDCap Codebook to
verify that all instruments were found. If some of your own variables
are named with the `x_complete` naming scheme, then they will be wrongly
detected as instrument markers. Add them to the function’s `ignore`
argument to get it to ignore them.

## Step 3. Split instruments

If you’re happy with the results of `find_instruments()`, you can use it
to split your dataset:

``` r
instrument <- split_instruments(rcdata = mydata, locations = instr_locs)
```

This produces a named list of dataframes, where the names are the
instrument names and the dataframes are the rows and variables
associated with that instrument. Empty rows are automatically omitted
from each instrument.

``` r
str(instrument, 1)

#> List of 11
#>  $ eligibility_form      :'data.frame':  511 obs. of  25 variables:
#>  $ medical_history       :'data.frame':  511 obs. of  70 variables:
#>  $ consent               :'data.frame':  511 obs. of  21 variables:
#>  $ baseline_ecrf         :'data.frame':  511 obs. of  21 variables:
#>  $ participant_survey    :'data.frame':  976 obs. of  34 variables:
#>  $ afeqt                 :'data.frame':  976 obs. of  30 variables:
#>  $ jakq                  :'data.frame':  976 obs. of  27 variables:
#>  $ tbq                   :'data.frame':  976 obs. of  23 variables:
#>  $ calm_scale            :'data.frame':  976 obs. of  24 variables:
#>  $ randomisation         :'data.frame':  511 obs. of  8 variables:
#>  $ user_experience_survey:'data.frame':  465 obs. of  23 variables:
```

## Step 4. Inspect instrument frequency

Finally, and perhaps most importantly, you can look at the collection
frequency and the Records-to-IDs Ratio of each instrument. This
information tells you which instruments were collected at similar
frequencies and schedules, and therefore which instruments might be
useful to join together.

``` r
report_instruments(instrument)

#>  One-Time ORPP (1 instance collected at 1 event)    
#>                                                     
#>    Instrument                Records-to-IDs Ratio   
#>    eligibility_form          1.000 (511 / 511)      
#>    medical_history           1.000 (511 / 511)      
#>    consent                   1.000 (511 / 511)      
#>    baseline_ecrf             1.000 (511 / 511)      
#>    randomisation             1.000 (511 / 511)      
#>    user_experience_survey    1.000 (465 / 465)      
#>                                                     
#>                                                     
#>  Repeated ORPP (1 instance collected at ≥2 events)  
#>                                                     
#>    Instrument                Records-to-IDs Ratio   
#>    participant_survey        1.910 (976 / 511)      
#>    afeqt                     1.910 (976 / 511)      
#>    jakq                      1.910 (976 / 511)      
#>    tbq                       1.910 (976 / 511)      
#>    calm_scale                1.910 (976 / 511)      
#>                                                     
#>                                                     
#>  One-Time MRPP (≥2 instances collected at 1 event)  
#>                                                     
#>    Instrument                Records-to-IDs Ratio   
#>                                                     
#>                                                     
#>  Repeated MRPP (≥2 instances collected at ≥2 events)
#>                                                     
#>    Instrument                Records-to-IDs Ratio   
#>                                                     
```

Instruments are collected on 4 frequencies:

- **One-Time ORPP** (one-row-per-person)
  - An instrument was presented at 1 event only.
  - Example: Eligibility questionnaire at recruitment.
- **Repeated ORPP**
  - An instrument was presented at 2 or more events.
  - Example: A standard questionnaire presented at each follow-up
    timepoint.
- **One-Time MRPP** (many-rows-per-person)
  - An instrument was completed multiple times at 1 event.
  - Example: A participant and a study recruiter are filling out a form
    describing each medication the participant is taking at baseline.
    The participant is on 5 medications, so 5 copies of the medication
    form are filled out.
- **Repeated MRPP**
  - An instrument was completed 2 or more times at 2 or more events.
  - Example: In the above example, the medication form would be a
    Repeated MRPP if it had to be filled out at every follow-up.

## Step 5. Re-assemble similar instruments

If you are agree with the instrument report, and once you’ve finished
cleaning the instruments to your liking, you can start to re-assemble
instruments that are similar to each other to form your final
dataset(s).

``` r
# One row per person.
myproject <-
    join_instruments(
        instrument$eligibility_form,
        instrument$medical_history,
        instrument$consent,
        instrument$baseline_ecrf,
        instrument$randomisation,
        instrument$user_experience_survey,

        .exclude = c(
            "redcap_event_name",
            "redcap_repeat_instrument",
            "redcap_repeat_instance",
            "redcap_data_access_group",
            "redcap_survey_identifier"
        )
    )


# Repeated measures.
myproject.rep <-
    join_instruments(
        instrument$participant_survey,
        instrument$afeqt,
        instrument$jakq,
        instrument$tbq,
        instrument$calm_scale,

        .exclude = c(
            "redcap_repeat_instrument",
            "redcap_repeat_instance",
            "redcap_data_access_group",
            "redcap_survey_identifier"
        )
    )
```
