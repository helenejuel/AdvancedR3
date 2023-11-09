#' Calculate descriptive statistics for each metabolite
#'
#' @param data Lipidomics dataset
#'
#' @return A data.frame/tibble

descriptive_stats <- function(data) {
  data %>%
    dplyr::group_by(metabolite) %>%
    dplyr::summarise(dplyr::across(value, list(mean = mean, sd = sd))) %>%
    dplyr::mutate(dplyr::across(tidyselect::where(is.numeric), ~ round(.x, digits = 1)))
}


#' Distribution plot
#'
#' @param data lipidomics data
#'
#' @return A facetwrapped ggplot

plot_distributions <- function(data) {
  ggplot2::ggplot(
    data,
    ggplot2::aes(x = value)
  ) +
    ggplot2::geom_histogram() +
    ggplot2::facet_wrap(dplyr::vars(metabolite), scales = "free")
}


#' Change column values that are strings/characters to snakecase
#'
#' @param data Any data with string columns, in this case the lipidomics data
#' @param cols The column to convert to snakecase, in this case the metabolite column
#'
#' @return A data frame

column_values_to_snake_case <- function(data, cols) {
  data %>%
    dplyr::mutate(dplyr::across({{ cols }},
      snakecase::to_snake_case
    ))
}

#' Transformation recipe to pre-process metabolite data
#'
#' @param data Lipidomics dataset
#' @param metabolite_variable The metabolite you want to test in the regression
#'
#' @return Recipe with specifications

create_recipe_spec <- function(data, metabolite_variable) {
    recipes::recipe(data) %>%
        recipes::update_role({{ metabolite_variable }}, age, gender, new_role = "predictor") %>%
        recipes::update_role(class, new_role = "outcome") %>%
        recipes::step_normalize(tidyselect::starts_with("metabolite_"))
} #only normalizes columns specified in "metabolite_variable"

#' Pivot data to wide
#'
#' @param data Lipidomics data
#'
#' @return Data frame

metabolites_to_wider <- function(data) {
    data %>%
        tidyr::pivot_wider(
            names_from = metabolite,
            values_from = value,
            values_fn = mean,
            names_prefix = "metabolite_"
        )
}
