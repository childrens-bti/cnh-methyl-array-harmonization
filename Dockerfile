FROM rocker/r-ver:4.6.1

LABEL maintainer="BTI Bioinformatics Core @ Children's National Hospital"

ENV DEBIAN_FRONTEND=noninteractive \
    ARROW_R_DEV=false \
    NOT_CRAN=true

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff5-dev \
    libuv1-dev \
    zlib1g-dev \
    cmake \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('remotes', 'BiocManager'), repos = 'https://cloud.r-project.org')"

# CRAN packages used by the preprocessing/merge scripts, pinned to exact versions
RUN R -e "remotes::install_version('optparse', version = '1.8.2', repos = 'https://cloud.r-project.org')" \
    && R -e "remotes::install_version('tidyverse', version = '2.0.0', repos = 'https://cloud.r-project.org')" \
    && R -e "remotes::install_version('R.utils', version = '2.13.0', repos = 'https://cloud.r-project.org')" \
    && R -e "remotes::install_version('qs2', version = '0.3.1', repos = 'https://cloud.r-project.org')" \
    && R -e "remotes::install_version('arrow', version = '25.0.1', repos = 'https://cloud.r-project.org')"

# Bioconductor packages used by the preprocessing/merge scripts, pinned to the
# Bioconductor release matched to R 4.6 (see https://bioconductor.org/config.yaml)
RUN R -e "BiocManager::install(version = '3.23', update = FALSE, ask = FALSE)" \
    && R -e "BiocManager::install(c('minfi', 'illuminaio', 'BiocParallel'), version = '3.23', update = FALSE, ask = FALSE)"

WORKDIR /workflow

COPY scripts/ scripts/

ENTRYPOINT ["Rscript"]
