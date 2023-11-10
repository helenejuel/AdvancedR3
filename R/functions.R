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
    dplyr::mutate(dplyr::across(
      {{ cols }},
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
} # only normalizes columns specified in "metabolite_variable"

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

#' Create a workflow object of the model including transformations
#'
#' @param model_specs The model specifications from function
#' @param recipe_specs The recipe specifications from function
#'
#' @return A workflow object

create_model_workflow <- function(model_specs, recipe_specs) {
  workflows::workflow() %>%
    workflows::add_model(model_specs) %>%
    workflows::add_recipe(recipe_specs)
}

#' Create a tidy output of model results
#'
#' @param workflow_fitted_model The model workflow object that has been fitted
#'
#' @return A data frame

tidy_model_output <- function(workflow_fitted_model) {
  workflow_fitted_model %>%
    workflows::extract_fit_parsnip() %>%
    broom::tidy(exponentiate = TRUE)
}

#' Convert the long form dataset into a list of wide form data frames
#'
#' @param data Lipidomics dataset
#'
#' @return A list of data frames

split_by_metabolite <- function(data) {
  data %>%
    column_values_to_snake_case(metabolite) %>%
    dplyr::group_split(metabolite) %>%
    purrr::map(metabolites_to_wider)
}

#' Generate the results of the model
#'
#' @param data Lipidomics dataset
#'
#' @return A data frame

generate_model_results <- function(data) {
  create_model_workflow(
    parsnip::logistic_reg() %>%
      parsnip::set_engine("glm"),
    data %>%
      create_recipe_spec(tidyselect::starts_with("metabolite_"))
  ) %>%
    parsnip::fit(data) %>%
    tidy_model_output()
}

#' Adding original metabolite names to final results
#'
#' @param model_results Results from the model output (model estimates)
#' @param data Lipidomics data
#'
#' @return A data frame

add_original_metabolite_names <- function(model_results, data) {
  data %>%
    dplyr::mutate(term = metabolite) %>%
    column_values_to_snake_case(term) %>%
    dplyr::mutate(term = stringr::str_c("metabolite_", term)) %>%
    dplyr::distinct(term, metabolite) %>%
    dplyr::right_join(model_results, by = "term")
}

#' Calculate the estimates for the model for each metabolite.
#'
#' @param data The lipidomics dataset.
#'
#' @return A data frame.
#'
calculate_estimates <- function(data) {
  data %>%
    split_by_metabolite() %>%
    purrr::map(generate_model_results) %>%
    purrr::list_rbind() %>%
    dplyr::filter(stringr::str_detect(term, "metabolite_")) %>%
    add_original_metabolite_names(data)
}

#' Plotting the model estimates
#'
#' @param results Model estimates from model
#'
#' @return A ggplot forest plot

plot_estimates <- function(results) {
  results %>%
    ggplot(aes(
      x = estimate, y = metabolite,
      xmin = estimate - std.error,
      xmax = estimate + std.error
    )) +
    geom_pointrange() +
    coord_fixed(xlim = c(0, 5))
}
