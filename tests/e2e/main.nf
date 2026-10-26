/*
 * End-to-end check for issue #3: two TES tasks on tesp-api + Pulsar.
 *
 * UPPER reads a staged local input file and writes a named output; COUNT consumes it. Outputs are named, never
 * globs: tesp-api rejects wildcard output paths (mirelaminkova/tesp-api#29). Every process names its container,
 * because nf-ga4gh refuses to submit a TES task without one (tesp-api runs it with Apptainer as docker://IMAGE).
 */

params.input  = "${projectDir}/data/input.txt"
params.outdir = 'results'

process UPPER {
    container 'ubuntu:22.04'

    input:
    path infile

    output:
    path 'upper.txt'

    script:
    """
    tr '[:lower:]' '[:upper:]' < ${infile} > upper.txt
    """
}

process COUNT {
    container 'ubuntu:22.04'
    publishDir params.outdir, mode: 'copy'

    input:
    path upper

    output:
    path 'result.txt'

    script:
    """
    { cat ${upper}; echo "lines=\$(wc -l < ${upper})"; } > result.txt
    """
}

workflow {
    UPPER(channel.fromPath(params.input, checkIfExists: true))
    COUNT(UPPER.out)

    COUNT.out
        .map { result ->
            def expected = 'HELLO TESP\nFROM NEXTFLOW\nlines=2\n'
            def text = result.text
            if( text != expected ) {
                error("result.txt has unexpected content: ${text.inspect()} (expected ${expected.inspect()})")
            }
            "E2E OK: ${result.name} has the expected content"
        }
        .view()
}
