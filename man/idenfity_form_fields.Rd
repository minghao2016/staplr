% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fill_pdf.R
\name{idenfity_form_fields}
\alias{idenfity_form_fields}
\title{Identify text form fields}
\usage{
idenfity_form_fields(input_filepath = NULL, output_filepath = NULL,
  overwrite = TRUE)
}
\arguments{
\item{input_filepath}{the path of the input PDF file. The default is set to
NULL. IF NULL, it  prompt the user to select the folder interactively.}

\item{output_filepath}{the path of the output PDF file. The default is set to
NULL. IF NULL, it  prompt the user to select the folder interactively.}

\item{overwrite}{If a file exists in \code{output_filepath}, should it be overwritten.}
}
\description{
Helps identification of text forum fields by creating a file that is filled
with field names. Some pdf editors show field names when you mouse over the
fields as well.
}
\examples{
\dontrun{
pdfFile = system.file('testForm.pdf',package = 'staplr')
idenfity_form_fields(pdfFile, 'testOutput.pdf')
}
}
