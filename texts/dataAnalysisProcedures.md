# Data Analysis Procedures

### Patient report procedure

For tumor biopsies within the CPCT and DRUP studies, Hartwig Medical Foundation provides centers with a "patient report" that contains findings that are considered potentially clinically relevant. The reported variants are based on the final list of somatic variants from our analysis pipeline but in addition have to pass certain rules before they end up in the report:

- Consensus rule: only variants with enough support from the various somatic callers are reported (see details below)
- Consequence rule: only variants located in certain transcripts of genes and with predicted effect are reported (see details below)

**Details Consensus Rule**  
For a variant to be reported **any** of the following needs to be true:
- include SNV if found by 3 or more callers (out of 4 total)
- include INDEL if found by 2 or more callers (out of 3 total)
- include variant if located in the "high confidence region" AND is called by at least 2 callers AND is present in COSMIC database OR not present in DBSNP
- include variant if located within "CPCT slicing panel" genes (about 75 kBases in 65 genes)

**Details Consequence Rule**  
In addition to the consensus rule, **all** of the following have to be true:
- variant is located within one of 118 chosen [canonical transcripts](http://www.ensembl.org/Help/Glossary?id=346) of genes (15.5 MBases), the list of genes can be found in any patient report
- variant has one of the following consequences/effects on canonical transcript: transcript ablation, transcript_amplification, splice_acceptor_variant,
splice_donor_variant, splice_region_variant, stop_gained, stop_lost, start_lost, frameshift_variant, inframe_insertion, inframe_deletion, missense_variant.

**Mutational Load**  
The total number of missense variants in the genome is reported as the "mutational load". The definition of missense is as follows: a sequence variant, that changes one or more bases, resulting in a different amino acid sequence but where the length is preserved. For all consequence definitions see the [calculated variant consequences table](http://www.ensembl.org/info/genome/variation/predicted_data.html) at Ensembl.

**Relevant Code**  
[Source code Consensus Rule Filter](https://github.com/hartwigmedical/hmftools/tree/master/consensus-rule-filter)  
[Source code Patient Reporter](https://github.com/hartwigmedical/hmftools/tree/master/patient-reporter)

-----

