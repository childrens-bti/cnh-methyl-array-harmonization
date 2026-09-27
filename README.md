# cnh-methyl-array-harmonization

CWL tools and R scripts for preprocessing raw Illumina Infinium HumanMethylation
BeadArray IDAT files (450k, EPIC/EPICv1, EPICv2) into harmonized methylation
measurements — beta values, M values, copy-number values, and detection
p-values — using [minfi](https://bioconductor.org/packages/release/bioc/html/minfi.html).
When more than one array type is present, probes common to all of them are
intersected and merged into a single matrix per data type.

## Pipeline

| Step | Script | CWL tool | Purpose |
|---|---|---|---|
| 1 | [`scripts/00-unzip-and-sort.R`](scripts/00-unzip-and-sort.R) | [`tools/unzip_and_sort_files.cwl`](tools/unzip_and_sort_files.cwl) | Unzips IDAT files and sorts them into per-array-type directories (avoids `minfi` errors from mixed array types in one batch). |
| 2 | [`scripts/01-preprocess-illumina-arrays.R`](scripts/01-preprocess-illumina-arrays.R) | [`tools/preprocess_illumina_arrays.cwl`](tools/preprocess_illumina_arrays.cwl) | Reads a single array type's IDATs, drops samples with zero MAD in control probes, normalizes (`preprocessFunnorm` or `preprocessQuantile`), optionally filters SNP-associated probes, and writes beta/M/CN/detection-p-value matrices (`.parquet`) plus the QC-filtered `RGChannelSet` (`.qs2`). |
| 3 | [`scripts/02-merge-methyl-matrices.R`](scripts/02-merge-methyl-matrices.R) | [`tools/merge_methyl_matrices.cwl`](tools/merge_methyl_matrices.cwl) | When 2+ array types were processed, intersects common probes (mapping EPICv2's duplicate `_TC**` probe suffixes back to shared CpG IDs) and writes merged matrices. A no-op when only one array type is present. |

[`workflows/methylation-preprocessing.cwl`](workflows/methylation-preprocessing.cwl)
chains all three steps together, but per its own `doc` field it is **deprecated** —
run the tools individually instead.

## Usage

### Locally, via `run-preprocess-illumina-arrays.sh`

```bash
./run-preprocess-illumina-arrays.sh \
    --manifest_file  MANIFEST.tsv \
    --input_dir      /path/to/raw/idats \
    --output_dir     outputs/ \
    --output_prefix  my-cohort
```

- `--manifest_file` must contain `file_name` and `Bioassay_ID` columns (an
  optional `unzipped_file_name` column is used on reruns after the original
  `.gz` files have already been removed by gunzip).
- The script sorts IDATs by array type, preprocesses whichever of
  EPICv2/EPICv1/450k are present (skipping any that aren't), and merges the
  per-array outputs if more than one array type was found.
- Requires R (see [Docker](#docker) below for the pinned package set) with
  `optparse`, `tidyverse`, `R.utils`, `illuminaio`, `BiocParallel`, `minfi`,
  `qs2`, and `arrow` installed.

### Via CWL

Each tool in [`tools/`](tools/) can be run independently with `cwltool`
(installed via [`envs/cwl_env.yml`](envs/cwl_env.yml)):

```bash
conda env create -f envs/cwl_env.yml
conda activate cwl_env

cwltool tools/unzip_and_sort_files.cwl params/unzip_and_sort_files.yml
cwltool tools/preprocess_illumina_arrays.cwl params/preprocess_illumina_arrays.yml
cwltool tools/merge_methyl_matrices.cwl params/merge_methyl_matrices.yml
```

See [`params/`](params/) for example input YAML files.

## Docker

[`Dockerfile`](Dockerfile) builds an `rocker/r-ver:4.6.1`-based image with
`optparse`, `tidyverse`, `R.utils`, `qs2`, and `arrow` pinned to exact CRAN
versions, and `minfi`, `illuminaio`, and `BiocParallel` installed from
Bioconductor release 3.23 (the release matched to R 4.6). It's published to
Cavatica at:

```
pgc-images.sbgenomics.com/childrens-bti/methyl-harmonization-cwl:v0.1.0
```

The CWL tools currently reference pre-built
`pgc-images.sbgenomics.com/.../openpedcanverse` images rather than this one.

## Repository Structure

```
cnh-methyl-array-harmonization
├── tools/                   # CWL CommandLineTool definitions
├── scripts/                 # R scripts run by the CWL tools
├── workflows/                # Deprecated end-to-end CWL workflow
├── run-preprocess-illumina-arrays.sh  # Local (non-CWL) pipeline driver
├── Dockerfile
├── data/                    # Input data to run on
├── manifests/               # Manifest files (file_name/Bioassay_ID)
├── params/                  # Example CWL input parameter YAML files
├── outputs/                 # Workflow output files
├── envs/                    # Conda environment for local cwltool testing
├── README.md
├── LICENSE
└── .gitignore
```

## Maintainer

BTI Bioinformatics Core @ Children's National Hospital
