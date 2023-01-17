#!/bin/sh

bcftools +fill-tags $1 -o tmp.VAF.vcf.gz -- -t FORMAT/VAF

bcftools query -f '%gnomad_3_1_1_AF\t%CHROM\t%POS\t%END\t%REF\t%ALT\t[%AD]\t[%DP]\t[%VAF]\n' tmp.VAF.vcf.gz > tmp_file.tsv

rm tmp.VAF.vcf.gz
