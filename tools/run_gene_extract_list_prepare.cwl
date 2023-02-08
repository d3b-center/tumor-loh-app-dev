#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool
id: run_gene_extract_list_prepare
doc: collects info from bcftool and add gene, prepare list for bam-readcount tool
requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/d3b-bixu/loh:1.0.0
- class: ResourceRequirement
  coresMin: 1
  ramMin: 4000
- class: InitialWorkDirRequirement
  listing:
  - entryname: run_gene_extract_list_prepare.py
    entry:
      $include: ../scripts/run_gene_extract_list_prepare.py
  - entryname: format_parser.py
    entry:
      $include: ../scripts/format_parser.py
baseCommand: [ python3 ]
arguments:
- position: 1
  valueFrom: >-
    run_gene_extract_list_prepare.py	
  shellQuote: false      

inputs: 
  bs_id: { doc: provide sample id, type: string, inputBinding: { prefix: --sampleid, position: 2} }
  sample_vcf_file_tool: { doc: provide vcf file, type: File, inputBinding: { prefix: --input, position: 2 }  }
  tsv_file: { doc: tsv file from bcftool , type: File, inputBinding: { prefix: --tsv, position: 2 } }

outputs:
   output_file_1_tool:
    type: File
    outputBinding:
     glob: "bcftool_file.tsv"
    doc: output file with VAF and Lost VAF
   output_file_2_tool:
    type: File
    outputBinding:
     glob: "list_bam-readcount.tsv"
    doc: output list(of positions) that act as input to bam-readcount