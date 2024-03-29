#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool
id: run_readcount_parser
label: tumor_tool
doc: run bam-readcountparser the bam-readcount output and extract inner join between data from vcf (germline) and cram/bam file (tumor)
requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/d3b-bixu/loh:1.0.1
- class: InlineJavascriptRequirement  
- class: ResourceRequirement
  coresMin: ${ return inputs.minCore }
  ramMin: ${ return inputs.ram * 1000 } 
- class: InitialWorkDirRequirement
  listing:
   - entryname: run_readcount_parse.py
     entry:
      $include: ../scripts/run_readcount_parse.py
   - entryname: tmp_list
     entry: $(inputs.list_dir)
     writable: true
   - entryname: loh_functions.py
     entry:
      $include: ../scripts/loh_functions.py
      
baseCommand: [ python3 ]
arguments:
- position: 1
  valueFrom: >-
    run_readcount_parse.py
  shellQuote: false      

inputs: 
  participant_id: { doc: provide participant id for this run, type: string, inputBinding: { prefix: --participant_id, position: 2} }
  germline_file: { doc: provide germline output, type: File, inputBinding: { prefix: --tsv, position: 2 } }
  list_dir: { doc: directory with regions stored as lists to run within bam/crams using bamreadcount , type: Directory, inputBinding: { prefix: --list_dir, position: 2 } }
  minDepth: { doc: provide minDepth to consider for tumor reads, type: int, default: 1, inputBinding: { prefix: --minDepth, position: 2} } 
  reference: { doc: provide reference, type: File, secondaryFiles: [ .fai ], inputBinding: { prefix: --reference, position: 2} } 
  patientbamcrams: { doc: provide one or more patient bam/cram files, type: 'File[]', secondaryFiles: [ { pattern: ".crai", required: false } ,{ pattern: ".bai",required: false } ], inputBinding: { prefix: --patientbamcrams, position: 2} } 
  peddy:  { doc: provide patient peddy file, type: 'File?', inputBinding: { prefix: --peddy, position: 2} } 
  bamcramsampleID:  { doc: provide unique identifers (in the same order) for cram/bam files provided under patientbamcrams tag. Default is sample ID from bam/cram files, type: 'string[]?', inputBinding: { prefix: --bamcramsampleID, position: 2} } 
  ram: { doc: Provide ram based on the vcf and crams inputs, type: 'int?', default: 14} 
  minCore: {type: 'int?', default: 14, doc: "No of cores"}
outputs:
   loh_output_file_tool:
    type: File
    outputBinding:
     glob: $(inputs.participant_id)*loh.out.tsv
    doc: output file required from LOH app
   log_output:
    type: File
    outputBinding:
     glob: "*loh.log"
    doc: output file required from LOH app 
