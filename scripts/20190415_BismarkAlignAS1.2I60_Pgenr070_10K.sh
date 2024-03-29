#!/bin/bash
## Job Name
#SBATCH --job-name=BismarkAlignAS1.2I60_Pgenr070_10K
## Allocation Definition 
#SBATCH --account=srlab
#SBATCH --partition=srlab
## Resources
## Nodes 
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=10-15:30:00
## Memory per node
#SBATCH --mem=500G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=strigg@uw.edu
## Specify the working directory for this job
#SBATCH --workdir=/gscratch/srlab/strigg/analyses/20190415_10K



#trim reads
%%bash

zcat < /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/Tank2-025-026_R1_001.fastq.gz | \
awk '{if(($1 !~ /^@GWNJ-0901\:/) && ($1 !~ /^\+$/))print substr($1,7,93);else print $1}' | \
gzip > /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/Tank2-025-026_trim_R1_001.fastq.gz 

zcat < /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/Tank2-025-026_R2_001.fastq.gz | \
awk '{if(($1 !~ /^@GWNJ-0901\:/) && ($1 !~ /^\+$/))print substr($1,7,93);else print $1}' | \
gzip > /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/Tank2-025-026_trim_R2_001.fastq.gz 

zcat < /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/Tank3-15-16_R1_001.fastq.gz | \
awk '{if(($1 !~ /^@GWNJ-0901\:/) && ($1 !~ /^\+$/))print substr($1,7,93);else print $1}' | \
gzip > /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/Tank3-15-16_trim_R1_001.fastq.gz 

zcat < /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/Tank3-15-16_R2_001.fastq.gz | \
awk '{if(($1 !~ /^@GWNJ-0901\:/) && ($1 !~ /^\+$/))print substr($1,7,93);else print $1}' | \
gzip > /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/Tank3-15-16_trim_R2_001.fastq.gz 


#align with bismark
%%bash

find /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/Tank*R1* \
| xargs basename -s _R1_001.fastq.gz | xargs -I{} /gscratch/srlab/programs/Bismark-0.19.0/bismark \
--path_to_bowtie /gscratch/srlab/programs/bowtie2-2.3.4.1-linux-x86_64 \
--samtools_path /gscratch/srlab/programs/samtools-1.9 \
--score_min L,0,-1.2 \
-I 60 \
-p 28 \
--genome /gscratch/srlab/strigg/data/Pgenr/Pgenr_070_10K/ \
-1 /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/{}_R1_001.fastq.gz \
-2 /gscratch/srlab/strigg/data/Pgenr/FASTQS/2019_broodstock_amb_v_lowpH/{}_R2_001.fastq.gz \
-o /gscratch/srlab/strigg/analyses/20190415_10K


#run deduplicaiton
%%bash
/gscratch/srlab/programs/Bismark-0.19.0/deduplicate_bismark \
--bam -p \
/gscratch/srlab/strigg/analyses/20190415_10K/*.bam \
-o /gscratch/srlab/strigg/analyses/20190415_10K/ \
2> /gscratch/srlab/strigg/analyses/20190415_10K/dedup.err \
--samtools_path /gscratch/srlab/programs/samtools-1.9/

#create summary report
cat /gscratch/srlab/strigg/analyses/20190415_10K/*PE_report.txt | \
grep 'Mapping\ efficiency\:' | \
cat - /gscratch/srlab/strigg/analyses/20190415_10K/*.deduplication_report.txt | \
grep 'Mapping\ efficiency\:\|removed' \
> /gscratch/srlab/strigg/analyses/20190415_10K/mapping_dedup_summary.txt

#compile and sort bams
find /gscratch/srlab/strigg/analyses/20190415_10K/*deduplicated.bam| \
xargs basename -s _R1_001_bismark_bt2_pe.deduplicated.bam | xargs -I{} /gscratch/srlab/programs/samtools-1.9/samtools \
sort /gscratch/srlab/strigg/analyses/20190415_10K/{}_R1_001_bismark_bt2_pe.deduplicated.bam \
-o /gscratch/srlab/strigg/analyses/20190415_10K/{}_dedup.sorted.bam

#run methylation extractor
/gscratch/srlab/programs/Bismark-0.19.0/bismark_methylation_extractor \
--paired-end --bedGraph --counts --scaffolds \
--multicore 28 \
/gscratch/srlab/strigg/analyses/20190415_10K/*deduplicated.bam \
-o /gscratch/srlab/strigg/analyses/20190415_10K/ \
--samtools /gscratch/srlab/programs/samtools-1.9/samtools \
2> /gscratch/srlab/strigg/analyses/20190415_10K/bme.err

#create bismark reports for individual samlpes
/gscratch/srlab/programs/Bismark-0.19.0/bismark2report

#create bismark summary report for all samples
/gscratch/srlab/programs/Bismark-0.19.0/bismark2summary
