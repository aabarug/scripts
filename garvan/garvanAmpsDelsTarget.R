library(dplyr)
library(tidyr)
library(GenomicRanges)

collapseCandidates <- function(x) {
    x = x[!is.na(x)]
    if (length(x) == 0) {
        return (NA)
    }
    return (paste(x, collapse = ","))
}

highestScoringCodingCandidate <- function(candidates, canonicalTranscripts) {
    candidateVector = data.frame(gene = unlist(strsplit(candidates, split = ",")), stringsAsFactors = F) %>% mutate(rank = row_number())
    candidateVector = left_join(candidateVector, canonicalTranscripts %>% select(gene, codingBases), by = "gene") %>%
        mutate(isCoding = codingBases > 0) %>%
        arrange(!isCoding, rank) %>% dplyr::slice(1)
    return (collapseCandidates(candidateVector$gene))
}

categoriseCandidates <-function(gene, candidates, genePanel) {

    candidateVector = unlist(strsplit(candidates, split = ","))
    candidatePanel = genePanel[genePanel$gene_name %in% candidateVector, ]

    result = candidatePanel %>% mutate_all(funs(ifelse(. != F, gene_name, NA))) %>% select(-gene_name) %>% summarise_all(funs(collapseCandidates))

    result$remainders <- collapseCandidates(candidateVector[!candidateVector %in% genePanel$gene_name])
    result$gene = gene

    return(result)
}

superSizedCandidates <-function(candidates, superGenes) {
    candidateVector = data.frame(gene = unlist(strsplit(candidates, split = ",")), stringsAsFactors = F) %>%
    mutate(rank = row_number())
    candidateSupers = inner_join(candidateVector, superGenes, by = c("gene" = "sub")) %>% select(gene = super, rank)
    result = bind_rows(candidateVector, candidateSupers) %>% arrange(rank)
    return(collapseCandidates(unique(result$gene)))
}

candidatesRange <- function(gene, candidates, canonicalTranscripts) {
    candidateVector = unlist(strsplit(candidates, split = ","))
    candidateTranscripts = canonicalTranscripts[canonicalTranscripts$gene %in% candidateVector, ]
    return (data.frame(gene, superCandidatesStart = as.numeric(min(candidateTranscripts$geneStart)), superCandidatesEnd = max(candidateTranscripts$geneEnd)))
}


singleTarget <- function(targets, superCandidates) {
    targetVector = unlist(strsplit(targets, split = ","))
    superCandidateDF = data.frame(gene = unlist(strsplit(superCandidates, split = ",")), stringsAsFactors = F)  %>% mutate(rank = row_number()) %>%
        filter(gene %in% targetVector) %>% arrange(rank)
    return (superCandidateDF[1, "gene"])
}

attach_target <- function(copyNumberSummary, cosmic, known) {
    copyNumberSummary$method <- "panel"
    copyNumberSummary$target <- copyNumberSummary$dnds
    copyNumberSummary$target <- ifelse(is.na(copyNumberSummary$target), copyNumberSummary$garvan, copyNumberSummary$target)
    copyNumberSummary$target <- ifelse(is.na(copyNumberSummary$target), copyNumberSummary$cosmicCurated, copyNumberSummary$target)
    copyNumberSummary$method <- ifelse(is.na(copyNumberSummary$target), "known", copyNumberSummary$method)
    copyNumberSummary$target <- ifelse(is.na(copyNumberSummary$target), copyNumberSummary[[known]], copyNumberSummary$target)
    copyNumberSummary$method <- ifelse(is.na(copyNumberSummary$target), "cosmic", copyNumberSummary$method)
    copyNumberSummary$target <- ifelse(is.na(copyNumberSummary$target), copyNumberSummary[[cosmic]], copyNumberSummary$target)
    copyNumberSummary$method <- ifelse(is.na(copyNumberSummary$target), "highest", copyNumberSummary$method)
    copyNumberSummary$target <- ifelse(is.na(copyNumberSummary$target), copyNumberSummary$highestScoring, copyNumberSummary$target)
    copyNumberSummary$telomere <- ifelse(copyNumberSummary$method == "highest" & copyNumberSummary$telomereSupported > copyNumberSummary$N / 2, paste0(copyNumberSummary$chromosome, substr(copyNumberSummary$chromosomeBand,1,1), "_telomere"), NA)
    copyNumberSummary$centromere <- ifelse(copyNumberSummary$method == "highest" & copyNumberSummary$centromereSupported > copyNumberSummary$N / 2, paste0(copyNumberSummary$chromosome, substr(copyNumberSummary$chromosomeBand,1,1), "_centromere"), NA)

    copyNumberSummary = copyNumberSummary %>% group_by(gene) %>% mutate(target = singleTarget(target, superCandidates))
    return(copyNumberSummary)
}


####### START OF ALGORITHM

outputDir = "~/garvan/RData/"
outputDir = "~/Documents/LKCGP_projects/RData/"
referenceDir = paste0(outputDir, "reference/")
processedDir = paste0(outputDir, "processed/")

load(paste0(referenceDir, "canonicalTranscripts.RData"))
load(paste0(processedDir, "genePanel.RData"))
load(paste0(processedDir, "geneCopyNumberDeletionsSummary.RData"))
load(paste0(processedDir, "geneCopyNumberAmplificationSummary.RData"))

canonicalTranscripts$range = GRanges(canonicalTranscripts$chromosome, IRanges(canonicalTranscripts$geneStart, canonicalTranscripts$geneEnd))
canonicalTranscriptsOverlaps = data.frame(findOverlaps(canonicalTranscripts$range, canonicalTranscripts$range, type="within")) %>% filter(queryHits != subjectHits)
superGenes = data.frame(sub = canonicalTranscripts[canonicalTranscriptsOverlaps[, 1], c("gene")], super = canonicalTranscripts[canonicalTranscriptsOverlaps[, 2], c("gene")], stringsAsFactors = F)

#### Load Amps and Dels Gene Panel
genePanel[is.na(genePanel)] <- F
delGenePanel  = genePanel %>% select(-cosmicOncogene, -amplification) %>%
    filter(garvan| dnds | cosmicCurated | cosmicTsg | deletion)
ampGenePanel  = genePanel %>% select(-cosmicTsg, -deletion) %>%
    filter(garvan| dnds | cosmicCurated | cosmicOncogene | amplification)
rm(genePanel)

#### DELETIONS
dels = geneCopyNumberDeletionsSummary %>%
    group_by(gene) %>%
    filter(score > 1, unsupported < N / 2) %>% ##### MAY NEED TO CHANGE THIS CRITERIA HERE
    mutate(candidatesCount = length(unlist(strsplit(candidates, split = ",")))) %>%
    mutate(superCandidates = superSizedCandidates(candidates, superGenes)) %>%
    mutate(superCandidatesCount = length(unlist(strsplit(superCandidates, split = ","))))

delCandidatesRange = apply(dels[, c("gene","superCandidates")], 1, function(x) {candidatesRange(x[1], x[2], canonicalTranscripts)})
dels = merge(dels, do.call(rbind, delCandidatesRange), by = "gene")

delCandidates = apply(dels[, c("gene","superCandidates")], 1, function(x) {categoriseCandidates(x[1], x[2], delGenePanel)})
dels = merge(dels, do.call(rbind, delCandidates), by = "gene")

dels =  dels %>%
    group_by(gene) %>%
    mutate(highestScoring = highestScoringCodingCandidate(remainders, canonicalTranscripts))

dels = attach_target(dels, "cosmicTsg", "deletion")

geneCopyNumberDeleteTargets = dels
save(geneCopyNumberDeleteTargets, file = paste0(processedDir, "geneCopyNumberDeleteTargets.RData"))

rm(dels)
rm(delCandidates)
rm(canonicalTranscriptsOverlaps)
rm(delCandidatesRange)
rm(geneCopyNumberDeletionsSummary)

#### AMPLIFICAIONS
amps = geneCopyNumberAmplificationSummary %>%
    group_by(gene) %>%
    filter(N > 1) %>%  #### AGAIN MIGHT WANT TO CHANGE THIS
    mutate(candidatesCount = length(unlist(strsplit(candidates, split = ",")))) %>%
    mutate(superCandidates = superSizedCandidates(candidates, superGenes)) %>%
    mutate(superCandidatesCount = length(unlist(strsplit(superCandidates, split = ","))))

ampCandidatesRange = apply(amps[, c("gene","superCandidates")], 1, function(x) {candidatesRange(x[1], x[2], canonicalTranscripts)})
amps = merge(amps, do.call(rbind, ampCandidatesRange), by = "gene")

ampCandidates = apply(amps[, c("gene","superCandidates")], 1, function(x) {categoriseCandidates(x[1], x[2], ampGenePanel)})
amps = merge(amps, do.call(rbind, ampCandidates), by = "gene")

amps = amps %>%
    group_by(gene) %>%
    mutate(highestScoring = highestScoringCodingCandidate(remainders, canonicalTranscripts))

amps = attach_target(amps, "cosmicOncogene", "amplification")

geneCopyNumberAmplificationTargets = amps
save(geneCopyNumberAmplificationTargets, file = paste0(processedDir, "geneCopyNumberAmplificationTargets.RData"))

rm(amps)
rm(ampCandidates)
rm(ampCandidatesRange)
rm(geneCopyNumberAmplificationSummary)

