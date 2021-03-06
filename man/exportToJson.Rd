% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/exportToJson.R
\name{exportToJson}
\alias{exportToJson}
\title{exportToJson}
\usage{
exportToJson(connectionDetails, cdmDatabaseSchema, resultsDatabaseSchema,
  outputPath = getwd(), reports = allReports, cdmVersion = "4")
}
\arguments{
  \item{connectionDetails}{An R object of type
  ConnectionDetail (details for the function that contains
  server info, database type, optionally username/
  password, port)} \item{cdmDatabaseSchema}{Name of the
  database schema that contains the vocabulary files}
  \item{resultsDatabaseSchema}{Name of the database schema
  that contains the Achilles analysis files. Default is
  cdmDatabaseSchema} \item{outputPath}{A folder location
  to save the JSON files. Default is current working
  folder} \item{reports}{A character vector listing the
  set of reports to generate. Default is all reports. See
  \code{data(allReports)} for a list of all report types}
}
\value{
none
}
\description{
\code{exportToJson} Exports Achilles statistics into a JSON
form for reports.
}
\details{
Creates individual files for each report found in
Achilles.Web
}
\examples{
\dontrun{
  connectionDetails <- createConnectionDetails(dbms="sql server", server="yourserver")
  exportToJson(connectionDetails, cdmDatabaseSchema="cdm4_sim", outputPath="your/output/path")
}
}

