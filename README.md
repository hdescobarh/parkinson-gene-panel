# Parkinson’s Disease Virtual Gene Panel

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-lightgreen.svg)](./LICENSE)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgreen.svg)](./LICENSE-CC)
![Python](https://img.shields.io/badge/Python-3.13-4584B6?logo=python&logoColor=white)
![Make](https://img.shields.io/badge/Build-Makefile-4584B6?logo=gnu&logoColor=white)
![Docker](https://img.shields.io/badge/Container-Docker-4584B6?logo=docker&logoColor=white)
![Jupyter](https://img.shields.io/badge/Notebook-Jupyter-4584B6?logo=jupyter&logoColor=white)

## The problem

A clinical laboratory is struggling to keep up with its rapidly expanding collection of static Targeted Gene Sequencing (TGS) panels. These panels, designed to test for specific conditions, are becoming overwhelming and difficult to maintain. The lab wants to modernize its approach by transitioning to **Whole Exome Sequencing** (WES) based **virtual gene panels**. This new method allows them to create tailored gene list, use algorithms not available for TGS and modify the tested regions without the need of resequencing.

As part of this transition, the lab has chosen to start its pilot introducing a virtual panel for testing Parkinsonism (MONDO:0021095), with a focus in Parkinson's Disease (MONDO:0005180), including the rarer Early-Onset presentations (MONDO:0017279).

## Tailoring a solution

The laboratory requires, following the American College of Medical Genetics and Genomics (ACMG) guidelines, develop and validate this new clinical test, this includes wet laboratory, bioinformatics pipeline and reporting.

An **initial step** is to define a reproducible workflow for generating the initial set of testing regions, which is necessary for the optimization and validation steps of the bioinformatics pipeline. I propose a semiautomatic workflow to merge, curate and generate bioinformatics pipeline ready-to-use files for Parkinson's Disease virtual gene panels. It generates ready-to-use files to be used in the virtual panel’s bioinformatics pipeline.

## Methodology

## Results (v.0.1.x)

```
# TODO: I think it will be necessary to create a static assets directory. Results can change between releases..
```

## Usage

### Dependencies

This project is built for Linux and requires the GNU coreutils (e.g., cp, mkdir), **make**, and awk. If you run it locally, you will need additional dependencies, which you can list with ``make deps. Alternatively, you can build and run it inside a container. I provide make targets to build and deploy the Docker image, but experienced users may also use the Dockerfile to build a Singularity/Apptainer image.

```bash
make help # show options
```

### Linux local installation and setup

```bash
make init ENV=prod #change to ENV=dev for development environment.
make download-refseq
make jupyter
```

### Docker build and setup

```bash
make docker-build
make docker-serve
```

After serving, you can explore the notebook at http://localhost:8888/lab

## Limitations

- **Data and coordinates verification**: PanelApp data uses two distinct data sources for Copy Number Variant (CNV) and Short Tandem Repeat (STR) entities, which introduces a potential for inconsistency. CNV data is sourced from ClinVar, while STR data is produced and curated via a Genomics England bioinformatics pipeline. To mitigate unexpected behavior during clinical testing, additional curation steps are needed to ensure that the coordinates of all genomic regions are fully compatible with the GCF_000001405.40 GRCh38.p14 reference assembly. This ensures data from different sources can be accurately integrated and analyzed.

- **Reference genome dependence**: the current methodology is anchored to the GRCh38 reference genome, and the Genome Reference Consortium (GRC) has not announced any plans for a new major release in the near future. While the T2T-CHM13 reference genome has demonstrated improved performance in some genomic analyses, transitioning to it would be challenging for clinical laboratories. Such a transition would require substantial adaptation of existing bioinformatics pipelines and the use of _liftover_ tools to convert coordinates from databases based on GRCh38, which could introduce additional layers of uncertainty.

- **Software testing**: as a prototype, the current project lacks a comprehensive testing framework. The absence of proper unit and integration tests poses a risk to the reliability and reproducibility of the results.

## Author

**Hans Escobar**: [LinkedIn](https://linkedin.com/in/hansescobar) | [GitHub](https://github.com/hdescobarh)

## License

This repository uses a dual-license structure:

- **Source code** is licensed under the Apache License 2.0 (see [LICENSE](LICENSE)).
- **Non-code content**, including documentation, academic text, and original diagrams, is licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0) (see [LICENSE-CC](LICENSE-CC)).

⚠️ Cited material from third-party sources (e.g., quotations, excerpts, figures) is not covered by these licenses and remains under its original copyright.

## References

```
TODO: Generate with Zotero. Use APA.

TODO: Don't forget to include software citations: pandas, matplotlib,

```
