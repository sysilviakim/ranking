#' Compute the Average Rank of All Items
#'
#' This function calculates the average rank for the data frame that contains
#' ranking data. It can be used for both long- and wide-type data frames.
#'
#' @param x A data frame that contains rankings of items.
#' @param rankings The name of the column that contains the rankings.
#' Defaults to NULL, which means that the function will look for a data frame
#' with two columns, "item" and "rank".
#' @param items The name of the column that contains the items' names, or,
#' in case of a wide file, the item names in the reference choice set.
#' Defaults to NULL.
#' @param long The type of the data frame. Defaults to `FALSE`.
#' It `TRUE`, which means that the data frame is in
#' the long format, it is presumed to be generated by \code{rank_longer()}.
#' If the data frame is in the wide format, it should be set to `FALSE`.
#' This only accepts a data frame with a single ranking variable that
#' contains rankings, and the rankings should be in the form of a string
#' such as \code{"123"}.
#' @param raw If \code{TRUE}, the function will return the raw average rank.
#' If \code{FALSE}, the function will return the average rank after correcting
#' based on the IPW estimator. Defaults to \code{TRUE}.
#' @param weight The name of the column that contains the weights for the IPW
#' estimator. Defaults to \code{NULL}.
#' @param round The number of decimal places to round the output to.
#' Defaults to \code{NULL}.
#'
#' @return A data frame with the average rank of each item in the
#' reference choice set.
#'
#' @importFrom dplyr group_by summarise across everything `%>%` mutate
#' select left_join
#' @importFrom tidyr pivot_longer pivot_wider
#' @importFrom purrr imap
#' @importFrom stringr str_split
#' @importFrom rlang !! set_names
#' @importFrom tidyselect all_of
#' @importFrom stats sd
#' @importFrom estimatr lm_robust
#'
#' @examples
#' x <- data.frame(
#'   id = c("Bernie", "Yuki", "Silvia"),
#'   rank = c("123", "321", "213")
#' )
#' avg_rank(x, "rank")
#' avg_rank(x, "rank", items = c("Money", "Power", "Respect"))
#'
#' y <- data.frame(rank = c("123", "321", "213"))
#' avg_rank(y, "rank")
#' z <- rank_longer(
#'   y,
#'   cols = "rank", id = "id",
#'   reference = c("Money", "Power", "Respect")
#' )
#' avg_rank(z, "ranking", items = "item_name", long = TRUE)
#'
#' ## Example output from item_to_rank
#' x <- data.frame(
#'   item = c("a", "b", "c", "a", "b", "c", "a", "b", "c"),
#'   rank = c(3L, 1L, 2L, 1L, 2L, 3L, 3L, 2L, 1L)
#' )
#' avg_rank(x, long = TRUE)
#'
#' @export

avg_rank <- function(x,
                     rankings = NULL,
                     items = NULL,
                     long = FALSE,
                     raw = TRUE,
                     weight = NULL,
                     round = NULL) {
  ## Suppress "no visible binding for global variable" warnings
  . <- item <- lower <- upper <- se <- variable <- method <- std.error <-
    estimate <- conf.low <- conf.high <- outcome <- qoi <- NULL

  if (long != FALSE & long != TRUE) {
    stop("The 'long' argument must be either TRUE or FALSE.")
  }
  if (raw != FALSE & raw != TRUE) {
    stop("The 'raw' argument must be either TRUE or FALSE.")
  }

  if (raw == FALSE & is.null(items)) {
    stop("If using the IPW estimator, the items variable must be specified.")
  }
  if (raw == FALSE & is.null(weight)) {
    stop("If using the IPW estimator, the weight variable must be specified.")
  }
  if (raw == FALSE & long == TRUE) {
    stop("If using the IPW estimator, the data frame must be in wide format.")
  }
  if (raw == TRUE & !is.null(weight)) {
    stop("If not using the IPW estimator, the weight variable must be NULL.")
  }
  if (!is.null(weight)) {
    if (!(weight %in% names(x))) {
      stop("The weight variable is not contained in the given data frame.")
    }
  }

  ## Use the output from `item_to_rank` without having to specify input.
  if (
    is.null(rankings) & is.null(items) &
      ncol(x) == 2 & ("rank" %in% names(x)) & ("item" %in% names(x))
  ) {
    rankings <- "rank"
    items <- "item"
  }

  if (is.null(rankings) & long == FALSE & ("rank" %in% names(x))) {
    rankings <- "rank"
  }

  if (is.null(rankings) & !("rank" %in% names(x)) & raw == TRUE) {
    stop("The rankings variable must be specified.")
  }

  ## What is the J?
  if (!is.null(rankings)) {
    J <- max(nchar(x[[rankings]]))
  } else if (!is.null(items)) {
    J <- length(items)
  } else {
    stop("There is no information about the number of items in the data frame.")
  }

  ## Class sanity checks
  if (!("data.frame" %in% class(x))) {
    stop("x must be a data frame.")
  }
  if (!is.null(rankings)) {
    if (!("character" %in% class(rankings))) {
      stop("The rankings variable must be a character.")
    }
    if (!(rankings %in% colnames(x))) {
      stop("The rankings variable is not contained in the given data frame.")
    }
  }

  ## Sanity checks for "rankings" and "items" arguments.
  if (!is.null(items)) {
    if (long == FALSE) {
      if (J < length(items)) {
        stop(
          paste0(
            "The number of reference choice set's elements in the items ",
            "variable does not match the number of items ranked."
          )
        )
      }
    } else {
      if (!(items %in% colnames(x))) {
        stop("The items variable is not contained in the given data frame.")
      }
    }
  } else {
    if (long == TRUE) {
      stop("If long data frame, the items variable must be specified.")
    }
  }

  ## Depending on whether it's a long- or wide-type data frame,
  ## treat differently
  if (raw == TRUE) {
    if (long == TRUE) {
      out <- x %>%
        group_by(!!as.name(items))
    } else {
      if (is.null(items)) {
        ## Just use the ranking positions to identify the items
        out <- x %>%
          separate(!!as.name(rankings), sep = seq(J), into = ordinal_seq(J)) %>%
          mutate(across(all_of(ordinal_seq(J)), as.numeric)) %>%
          pivot_longer(
            all_of(ordinal_seq(J)),
            names_to = "item",
            values_to = "rankings"
          )
      } else {
        ## Use the items variable as item names
        out <- x %>%
          separate(!!as.name(rankings), sep = seq(J), into = items) %>%
          mutate(across(all_of(items), as.numeric)) %>%
          pivot_longer(
            all_of(items),
            names_to = "item",
            values_to = "rankings"
          )
      }
      rankings <- "rankings"
      out <- out %>%
        group_by(item) %>%
        select(item, !!as.name(rankings))
    }

    ## Compute the average rank and the 95% CI
    out <- out %>%
      summarise(
        qoi = "Average Rank",
        mean = mean(!!as.name(rankings), na.rm = TRUE),
        se = sd(!!as.name(rankings), na.rm = TRUE) / sqrt(nrow(x)),
        lower = mean - 1.96 * se,
        upper = mean + 1.96 * se,
        method = "Raw Data"
      )
  } else {
    vars <- items
    if (is.data.frame(items)) {
      if (all(sort(colnames(items)) == c("item", "variable"))) {
        vars <- items$variable
      } else {
        stop(
          paste0(
            "If items argument is a data frame, make sure that the columns are",
            " named 'item' and 'variable'."
          )
        )
      }
    }

    out <- vars %>%
      set_names(., .) %>%
      imap(
        ~ lm_robust(
          !!as.name(.x) ~ 1,
          weights = !!as.name(weight), data = x
        ) %>%
          tidy() %>%
          mutate(outcome = .y)
      ) %>%
      Reduce(rbind, .) %>%
      mutate(
        mean = estimate,
        se = std.error,
        lower = conf.low,
        upper = conf.high,
        item = outcome,
        qoi = "Average Rank"
      ) %>%
      mutate(method = "IPW")

    if (is.data.frame(items)) {
      out <- out %>%
        rename(variable = item) %>%
        left_join(., items) %>%
        select(-variable)
      items <- items$item
    }

    out <- out %>%
      mutate(item = factor(item, levels = items))
  }

  if (!is.null(items) & long == FALSE) {
    ## Must align the summary output by the item order given;
    ## otherwise, the summary tibble appears in alphabetical order
    out$item <- factor(out$item, levels = items)
    out <- out[order(out$item), ]
  } else if (!is.null(items) & long == TRUE) {
    out[[items]] <- factor(out[[items]], levels = items)
    out <- out[order(out[[items]]), ]
  }

  ## When printing, round if specified
  if (!is.null(round)) {
    out <- out %>%
      mutate(across(c(mean, lower, upper), ~ round(., digits = round)))
  }

  return(
    as.data.frame(out) %>% select(item, qoi, mean, se, lower, upper, method)
  )
}
