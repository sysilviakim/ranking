% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rpluce.R
\name{rpluce}
\alias{rpluce}
\title{Draw Samples from the Plackett-Luce Model}
\usage{
rpluce(n, t, prob, choices = NULL, seed = NULL)
}
\arguments{
\item{n}{The total number of samples to draw.}

\item{t}{The number of items or alternatives to choose from.}

\item{prob}{A vector of choice probabilities.}

\item{choices}{A vector of choices to be ranked.}

\item{seed}{An optional seed for the random number generator.}
}
\value{
A data frame of rankings of t items for n assessors.
}
\description{
This function draws samples from the Plackett-Luce model, using
Algorithm 2.1, "Efficient Sampling from Plackett-Luce," in Xia (2019),
page 20, Section 2.2.3 Sampling from Random Utility Models.
The name \code{rpluce} is a convention that follows random generations of
numbers from statistical distributions such as \code{rnorm} or
\code{rmultinom}.
}
\details{
Input: A parameter \eqn{\overrightarrow{\gamma} = (\gamma_1, \cdots, \gamma_m)}
of Plackett-Luce. \cr

Output: A ranking \eqn{R \in \mathcal{L}(\mathcal{A})} from
\eqn{pi_{\overrightarrow{\gamma}} ( \cdot )} under Plackett–Luce.  \cr
  1: Let \eqn{R = \emptyset} and \eqn{A = \mathcal{A}}.  \cr
  2: for \eqn{t = 1} to \eqn{m} do  \cr
  3:   Choose an alternative \eqn{a_{i_t}} from \eqn{A}
       with probability proportional to \eqn{\gamma_{i_t}}.  \cr
  4:   \eqn{R \leftarrow R \succ a_{i_t}} and
       \eqn{A \leftarrow A \ \{ a_{i_t} \}}.  \cr
  5: end for \cr
  6: return \eqn{R}.
}
\examples{
rpluce(n = 10, t = 3, prob = c(0.5, 0.3, 0.2), seed = 123)

}
