SELECT structuralVariant.sampleId, structuralVariant.modified, gene, strand, isStartEnd, exonRankUpstream, exonRankDownstream, exonMax, startOrientation, endOrientation, type, ploidy FROM structuralVariantDisruption
INNER JOIN structuralVariantBreakend ON structuralVariantBreakend.id = structuralVariantDisruption.breakendId
INNER JOIN structuralVariant ON structuralVariant.id = structuralVariantBreakend.structuralVariantId
WHERE isReported = 1
AND structuralVariant.sampleId IN ('XXX');