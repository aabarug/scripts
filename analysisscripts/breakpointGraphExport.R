#!/usr/bin/env Rscript
library(argparser)
argp = arg_parser("Generates pre and post simplification breakpoint graph visualisations")
argp = add_argument(argp, "--sampleId", default="", help="Sample ID")
argp = add_argument(argp, "--cn", help="Copy number file")
argp = add_argument(argp, "--sv", help="Remaining SV file")
argp = add_argument(argp, "--output", help="Output html file for visJS visualisation.")
argp = add_argument(argp, "--directory", help="Generates visualisation for all samples in the given directory")
argv = parse_args(argp)
argv = list(sampleId="COLO829T", cn="D:/hartwig/graph/COLO829T_cn_reduced.purple.cnv", sv="D:/hartwig/graph/COLO829T_sv_remaining.csv.sv", output="D:/hartwig/graph/COLO829T.graph.simplified.html")

source("livSvAnalyser.R")
library(tidyverse)
library(readr)
library(stringr)

if (!is.null(argv$directory) | !is.na(argv$directory)) {
  lapply(list.files(path=argv$directory, pattern="*_cn_reduced.purple.cnv"), function(cnFile) {
    sampleId = str_replace(cnFile, stringr::fixed("_cn_reduced.purple.cnv"), "")
    generate_breakpoint_graph_visualisation(
      sampleId,
      paste0(argv$directory, "/", sampleId, "_cn_reduced.purple.cnv"),
      paste0(argv$directory, "/", sampleId, "_sv_remaining.csv.sv"),
      paste0(argv$directory, "/", sampleId, ".graph.simplified.html"))})
} else {
  generate_breakpoint_graph_visualisation(argv$sampleId, cnFile=argv$cn, svFile=argv$sv, outputFile=argv$output)
}

