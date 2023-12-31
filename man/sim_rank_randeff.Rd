% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sim_rank_randeff.R
\name{sim_rank_randeff}
\alias{sim_rank_randeff}
\title{Simulate the Probability that a Given Ranking Permutation Pattern is Chosen
Over a Random Effect Variable}
\usage{
sim_rank_randeff(
  m,
  permn,
  random_var,
  continuous = TRUE,
  range_cont = NULL,
  conf_level = 0.95,
  seed = NULL,
  n = 1000,
  vcov = NULL,
  coefs = NULL,
  dist = NULL
)
}
\arguments{
\item{m}{An \code{mlogit} object.}

\item{permn}{A permutation pattern that is being checked over a combination
of variables.}

\item{random_var}{A character string that specifies the random effect
variable.}

\item{continuous}{A logical value that indicates whether the random effect
variable is continuous or not. The default is \code{TRUE}.}

\item{range_cont}{A vector that specifies the range of the random effect
variable to be visualized/simulated.}

\item{conf_level}{A numeric value that specifies the confidence level of the
confidence interval. The default is \code{0.95}.}

\item{seed}{An integer that specifies the seed for the random number.
Default is \code{NULL}.}

\item{n}{An integer that specifies the number of simulations.
Defaults to 1,000.}

\item{vcov}{Argument for \code{clarify::sim}. The default is \code{NULL}.}

\item{coefs}{Argument for \code{clarify::sim}. The default is \code{NULL}.}

\item{dist}{Argument for \code{clarify::sim}. The default is \code{NULL}.}
}
\value{
A data frame that contains the mean, lower bound, and upper bound of
the probability that a given ranking permutation pattern is chosen over a
random effect variable's values.
}
\description{
This function simulates the probability that a given ranking permutation
pattern is chosen over a random effect variable. The function is based on
the \code{sim} function from the \pkg{clarify} package as well as the
\code{mlogit} package, and designed to work with \code{mlogit}
objects.
}
\details{
Warning: the `mlogit`'s `reflevel` should match the last element of
\code{permn}. (This should be fixed in a future version.)
}
\examples{

## This model does not mean *anything.*
## This is simply to demonstrate the function.
library(mlogit)
library(dfidx)

data("Fishing", package = "mlogit")
Fish <- dfidx(Fishing, varying = 2:9, shape = "wide", choice = "mode")
m1 <- mlogit(mode ~ 1 | price, reflevel = "beach", data = Fish)

sim_rank_randeff(
  m = m1,
  permn = c("charter", "boat", "pier", "beach"),
  random_var = "price",
  range_cont = c(10, 50, 100),
  seed = 123
)

}
