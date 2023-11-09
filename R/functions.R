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
    ggplot2::ggplot(data,
                    ggplot2::aes(x = value)) +
        ggplot2::geom_histogram() +
        ggplot2::facet_wrap(dplyr::vars(metabolite), scales = "free")

}

