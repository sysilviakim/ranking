#' Bias-correct the Distribution of Ranking Permutations
#' (IPW Estimator Version)
#'
#' @description This function implements the bias correction of the ranking
#' distribution using a paired anchor question, using the IPW estimator.
#'
#' @importFrom dplyr `%>%` mutate select group_by left_join arrange summarise
#' @importFrom tidyselect matches
#' @importFrom combinat permn
#' @importFrom questionr wtd.table
#'
#' @param data The input dataset with ranking data.
#' @param J The number of items in the ranking question. Defaults to NULL,
#' in which case it will be inferred from the data.
#' @param main_q Column name for the main ranking question to be analyzed.
#' @param anc_correct Indicator for passing the anchor question.
#' @param seed Seed for \code{set.seed} for reproducibility.
#' @param weight A vector of weights. Defaults to NULL.
#'
#' @return A list.
#'
#' @export

imprr_weights <- function(data,
                          J = NULL,
                          main_q,
                          anc_correct,
                          seed = 123456,
                          weight = NULL) {
  ## Suppress global variable warning
  count <- n <- n_adj <- n_renormalized <- prop <- ranking <- w <- NULL

  # Setup ======================================================================
  N <- nrow(data)
  if (is.null(J)) {
    J <- nchar(data[[main_q]][[1]])
  }

  if (is.null(weight)) {
    weight <- rep(1, N)
  }

  # Check the validity of the input arguments ==================================
  ## Main ranking only (Silvia, I edited here slightly)
  glo_app <- data %>%
    select(matches(main_q)) %>%
    select(matches("_[[:digit:]]$"))

  # Step 1: Get the proportion of random answers -------------------------------
  p_non_random <- (mean(data[[anc_correct]]) - 1 / factorial(J)) /
    (1 - 1 / factorial(J))

  # Step 2: Get the uniform distribution ---------------------------------------
  U <- rep(1 / factorial(J), factorial(J))

  # Step 3: Get the observed PMF based on raw data -----------------------------
  ## Get raw counts of ranking profiles
  D_0 <- glo_app %>%
    unite(ranking, sep = "") %>%
    mutate(survey_weight = weight)

  ## Get a weighted table
  tab_vec <- wtd.table(x = D_0$ranking, weights = D_0$survey_weight)%>%
    tibble()

  D_PMF_0 <- D_0 %>%
    group_by(ranking) %>%
    count()

  ## Over-write "n" with weighted results
  D_PMF_0$n <- as.numeric(tab_vec$.)

  ## Create sample space to merge
  perm_j <- permn(1:J)
  perm_j <- do.call(rbind.data.frame, perm_j)
  colnames(perm_j) <- c(paste0("position_", 1:J))
  perm_j <- perm_j %>%
    unite(col = "ranking", sep = "") %>%
    arrange(ranking)

  ## We need this because some rankings may not appear in the data
  PMF_raw <- perm_j %>%
    left_join(D_PMF_0, by = "ranking") %>%
    mutate(
      n = ifelse(is.na(n) == T, 0, n),
      prop = n / sum(weight),
      prop = ifelse(is.na(prop), 0, prop)
    ) %>%
    arrange(ranking)

  # Step 4: Get the bias-corrected PMF -----------------------------------------
  ## Apply Equation A.11
  imp_PMF_0 <- (PMF_raw$prop - (U * (1 - p_non_random))) / p_non_random

  ## Recombine with ranking ID
  imp_PMF_1 <- perm_j %>%
    mutate(n = imp_PMF_0)

  # Step 5: Re-normalize the PMF -----------------------------------------------
  ## The previous step may produce outside-the-bound values
  ## (negative proportions)
  imp_PMF <- imp_PMF_1 %>%
    mutate(
      n_adj = ifelse(n < 0, 0, n),
      n_renormalized = n_adj / sum(n_adj)
    ) %>%
    rename(
      prop = n,
      prop_adj = n_adj,
      prop_renormalized = n_renormalized
    ) %>%
    arrange(ranking)

  # Step 6: Get the bias-correction weight vector ------------------------------
  df_w <- perm_j %>%
    mutate(
      w = imp_PMF$prop_renormalized / PMF_raw$prop, # Inverse probability weight
      w = ifelse(w == Inf, 0, w),
      w = ifelse(is.na(w), 0, w)
    ) %>% # NA arise from 0/0
    arrange(ranking)

  # Summarize results ----------------------------------------------------------
  return(
    list(
      est_p_random = 1 - p_non_random,
      obs_pmf = PMF_raw,
      corrected_pmf = imp_PMF,
      weights = df_w
    )
  )
}
