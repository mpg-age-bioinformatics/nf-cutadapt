#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process get_images {
  stageInMode 'symlink'
  stageOutMode 'move'

  script:
    """

    if [[ "${params.containers}" == "singularity" ]] ; 

      then

        cd ${params.image_folder}

        if [[ ! -f cutadapt-4.5.sif ]] ;
          then
            singularity pull cutadapt-4.5.sif docker://index.docker.io/mpgagebioinformatics/cutadapt:4.5
        fi

    fi


    if [[ "${params.containers}" == "docker" ]] ; 

      then

        docker pull mpgagebioinformatics/cutadapt:4.5

    fi

    """

}

process fastqc {
  tag "${f}"
  stageInMode 'symlink'
  stageOutMode 'move'
  
  input:
    path f
    val cutadapt_output
  
  script:
    """
    mkdir -p /workdir/${cutadapt_output}
    cutadapt -j ${task.cpus} --length ${params.sgRNA_size} -g ${params.upstreamseq} -o /workdir/${cutadapt_output}/${f} ${f}
    """
}

workflow images {
  main:
    get_images()
}

workflow upload {
  if ( 'cutadapt_output' in params.keySet() ) {
    cutadapt_output="${params.cutadapt_output}"
  } else {
    cutadapt_output="cutadapt_output"
  }
  upload_paths(cutadapt_output)
}

workflow {
    if ( 'cutadapt_output' in params.keySet() ) {
      cutadapt_output="${params.cutadapt_output}"
    } else {
      cutadapt_output="cutadapt_output"
    }

    data = channel.fromPath( "${params.cutadapt_raw_data}/*fastq.gz" )
    data = data.filter{ ! file("$it".replace("${params.cutadapt_raw_data}", "${params.project_folder}/${cutadapt_output}/") ).exists() }
    fastqc( data, cutadapt_output )
}