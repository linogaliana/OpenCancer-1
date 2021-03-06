% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/simplelasso.R
\name{simplelasso}
\alias{simplelasso}
\title{Perform LASSO to select best features}
\usage{
simplelasso(df, yvar = "incidence", crossvalidation = T, nfolds = 10,
  include.intercept = TRUE, lag.order = NULL)
}
\arguments{
\item{df}{Dataframe}

\item{crossvalidation}{Should cross-validation be performed? TRUE or FALSE}

\item{nfolds}{Number of folds for cross-validation. Ignored if
\code{crossvalidation = T}}

\item{simplify}{Boolean indicating whether some factor variables should
be dropped}
}
\value{
A list of three elements.

\code{output$model} returns the model. \cr

\code{output$plot} returns a plot. If \code{crossvalidation = F},
coefficients values when $\lambda$ penalization term
evolves is represented.
If \code{crossvalidation = T}, the RMSE is represented with respect to the
number of variables with non-zero weight \cr

\code{output$coeff} returns the coefficient values returned by the LASSO
(or the coefficients of the RMSE-minimizing model if \code{crossvalidation = T})
}
\description{
\code{simplelasso} estimates a model using LASSO and
returns a sparse structure.
Cross-validation can be used to select best covariates
combination
}
