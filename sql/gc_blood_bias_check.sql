SELECT sampleId,
sum(if(observedNormalRatio>0.9 and observedNormalRatio<1.1,bafCount,0))/sum(if(observedNormalRatio>0.65 and observedNormalRatio<1.35,bafCount,0)) as QCcheck
FROM copyNumberRegion
WHERE sampleId IN 
('XXX')
GROUP BY 1 ORDER BY 2;