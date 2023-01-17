#!/usr/bin/env python3

import argparse
import subprocess
import pandas as pd
import pysam as pys
import format_parser as ob

# coding=utf8
# Initialize parser
parser = argparse.ArgumentParser()

# Adding optional argument
parser.add_argument(
    "-i", "--input", help="provide sample vcf file in gz format")

parser.add_argument(
    "-t", "--tsv", help="provide bcftools output in tsv format")

parser.add_argument(
    "-c", "--cram", help="provide cram/bam file for the sample")

parser.add_argument(
    "-r", "--ref", help="provide human reference in fasta format")

parser.add_argument("-id", "--sampleid", help="provide sample ID")

parser.add_argument("-o", "--output", help="output file name in tsv format")

# Read arguments from command line
args = parser.parse_args()


def get_VAF_pos(cram_bam_path, chrom, pos, ref, alt, reference=None):
    """ Return percent of reads match with alt and total number of reads found
        Args:
            cram_bam_path (str): path to CRAM or BAM file
            chrom (str): locus chromosome name
            pos (int): 1-based locus coordinate
            reference: path to reference FASTA, required for CRAM
                (default None)
        Raises:
            IOError if CRAM provided without reference
                    if cram_path has neither cram nor bam extension
        Return:
            The percent of reads that match the given alt (as a float)
            The total reads found at that position (int)

    """
    if len(ref) > 1 or len(alt) > 1:  # excluding indels
        return ("Indels are ignored at the moment", "Indels are ignored")
    if cram_bam_path.endswith('cram'):
        if not reference:
            raise IOError('Must provide reference with CRAM')
        cram_bam = pys.AlignmentFile(
            cram_bam_path, 'rc', reference_filename=reference)
    elif cram_bam_path.endswith('bam'):
        cram_bam = pys.AlignmentFile(cram_bam_path, 'rb')
    else:
        raise IOError(
            'File provided to "cram" argument must have .cram or .bam extension')

    mapq = []
    mq0 = 0
    aligned_reads = cram_bam.fetch(chrom, pos-1, pos, multiple_iterators=False)
    total_reads = 0
    count_required = 0
    for read in aligned_reads:
        start = read.pos  # read start position
        diff = pos-start  # difference between start and pos
        seq = read.query_sequence
        if len(seq) > diff:
            if seq[diff-1] == alt:
                count_required = count_required+1
            total_reads += 1
    if total_reads == 0:
        return ("No read found", "0")
    else:
        return (round(count_required/total_reads, 4), total_reads)


# extract gene list from vcf file
gene = ob.read_vcf_gene_list(args.input)
del gene[-1]  # last element in the list is end of the file which is not required

# read tsv file from bcftools
dataframe = pd.read_csv(args.tsv, sep='\t')

# set up pandas dataframe
dataframe.columns = ["popmax", "chr", "start", "stop", "ref",
                     "alt", "ref,alt depth", "Germline_depth", "Germline_VAF"]
dataframe['gene'] = gene

# remove entries with . as popmax
dataframe = dataframe[dataframe.popmax != "."]
dataframe['popmax'] = dataframe['popmax'].astype(float)

# set criteria for rare variant
dataframe = dataframe[dataframe.popmax < 0.01]
dataframe = dataframe.drop(['popmax'], axis=1)  # not required anymore

list_VAF = []
list_total_reads = []

# run the for loop to calculate lost VAF
for index, row in dataframe.iterrows():
    # print(row['chr'], row['start'])
    vaf, total_reads = get_VAF_pos(
        args.cram, row['chr'], row['start'], row['ref'], row['alt'], args.ref)
    list_VAF.append(vaf)
    list_total_reads.append(total_reads)
dataframe["Tumor_VAF"] = list_VAF
dataframe["Tumor_depth"] = list_total_reads
dataframe["BS_ID"] = args.sampleid

# split columns
dataframe[['ref_depth', 'alt_depth']] = dataframe['ref,alt depth'].str.split(
    ',', 1, expand=True)

# reorder the columns
dataframe = dataframe[["BS_ID", "gene", "chr", "start", "stop", "ref", 'ref_depth', 'alt',
                       'alt_depth', 'Germline_depth', 'Tumor_depth', 'Germline_VAF', 'Tumor_VAF']]

# output_file in tsv format
output_file_name = args.output
if not(output_file_name.endswith('tsv')):
    output_file_name = output_file_name+".tsv"

dataframe.to_csv(output_file_name, sep="\t", index=False)
