# Parkinson’s Disease Virtual Gene Panel

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-lightgreen.svg)](./LICENSE)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgreen.svg)](./LICENSE-CC)
![Python](https://img.shields.io/badge/Python-3.13-4584B6?logo=python&logoColor=white)
![Make](https://img.shields.io/badge/Build-Makefile-4584B6?logo=gnu&logoColor=white)
![Docker](https://img.shields.io/badge/Container-Docker-4584B6?logo=docker&logoColor=white)
![Jupyter](https://img.shields.io/badge/Notebook-Jupyter-4584B6?logo=jupyter&logoColor=white)

## The problem

A clinical laboratory is struggling to keep up with its rapidly expanding collection of static Targeted Gene Sequencing (TGS) panels. These panels, designed to test for specific conditions, are becoming overwhelming and difficult to maintain. To modernize its approach, the lab is transitioning to Whole Exome Sequencing (WES) based virtual gene panels. This new method allows them to create tailored gene lists, use algorithms not available for TGS, and modify the tested regions without the need for resequencing.

As part of this transition, the lab has chosen to start its pilot program by introducing a virtual panel for testing Parkinsonism (MONDO:0021095), with a focus on Parkinson's Disease (MONDO:0005180), including its rarer Early-Onset presentations (MONDO:0017279).

## Tailoring a solution

Following the guidelines of the American College of Medical Genetics and Genomics (ACMG), the laboratory requires the development and validation of this clinical test, covering everything from wet-lab procedures to reporting guidelines (Rehder et al., 2021). **The scope of this porfolio project is a early process in bioinformatics pipeline validation.**

I propose a semi-automatic workflow to merge, curate, and generate bioinformatics pipeline-ready files for a Parkinson's Disease virtual gene panel. The generated files are essential for the optimization and validation steps of the panel slice (Bean et al., 2020; SoRelle et al., 2024). After selecting the reference genome and annotation version (GRCh38.p14, GCF_000001405.40), specific BED files are needed to define Quality Assurance (QA) / Quality Control (QC) metric thresholds and to limit variant detection to the predefined set of regions.

This project does not aim to harmonize panels (Stark et al., 2021). Additionally, the gene set is not definitive; as part of the test validation process, it is subject to later refinements based on the criteria of medical professionals.

## Methodology overview

This project provides a reproducible workflow to generate a virtual gene panel for Parkinson's Disease. The process is broken down into three key phases, with detailed implementation provided in the project's Jupyter Notebooks.

1. PanelApp data retrieval and curation

- I sourced panels from PanelApp, an open-access knowledge database with expert-curated gene lists (Martin et al., 2019). I selected all available Parkinsonism panels from both the England and Australia PanelApp databases, locking the specific versions for reproducibility.

- The retrieved panels were filtered for clinical suitability based on expert assessments. They were then merged into a single consensus panel, and potential conflicts were evaluated. The entities were stratified based on their suitability status across the individual panels.

- All gene entities were reviewed to identify and manually curates any annotation issues.

2. Enrichment with NCBI RefSeq Annotations

- PanelApp is annotated with Ensembl/GENCODE, while key resources like ClinVar use NCBI Genome annotations. To avoid inconsistencies from mixed annotation systems, I replaced the original location data with annotations from NCBI RefSeq.

- The gene data was also enriched with strand information, and outdated data entries were curated during this process.

3. Generation of BED Files

- The curated data from the previous steps was used to generate well-formatted BED files containing only the genomic intervals for exons, STRs, and CNVs. These intervals are essential for downstream analysis.

- I used BEDOPS v2.4.41 (Neph et al., 2012) to validate the BED file format, merge any overlapping intervals, and ensure the coordinate systems were correct.

## Results (v.0.1.0)

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

- Bean, L., Funke, B., Carlston, C. M., Gannon, J. L., Kantarci, S., Krock, B. L., Zhang, S., & Bayrak-Toydemir, P. (2020). Diagnostic gene sequencing panels: From design to report—a technical standard of the American College of Medical Genetics and Genomics (ACMG). Genetics in Medicine, 22(3), 453–461. https://doi.org/10.1038/s41436-019-0666-z

- Martin, A. R., Williams, E., Foulger, R. E., Leigh, S., Daugherty, L. C., Niblock, O., Leong, I. U. S., Smith, K. R., Gerasimenko, O., Haraldsdottir, E., Thomas, E., Scott, R. H., Baple, E., Tucci, A., Brittain, H., De Burca, A., Ibañez, K., Kasperaviciute, D., Smedley, D., … McDonagh, E. M. (2019). PanelApp crowdsources expert knowledge to establish consensus diagnostic gene panels. Nature Genetics, 51(11), 1560–1565. https://doi.org/10.1038/s41588-019-0528-2

- Neph, S., Kuehn, M. S., Reynolds, A. P., Haugen, E., Thurman, R. E., Johnson, A. K., Rynes, E., Maurano, M. T., Vierstra, J., Thomas, S., Sandstrom, R., Humbert, R., & Stamatoyannopoulos, J. A. (2012). BEDOPS: High-performance genomic feature operations. Bioinformatics, 28(14), 1919–1920. https://doi.org/10.1093/bioinformatics/bts277

- Rehder, C., Bean, L. J. H., Bick, D., Chao, E., Chung, W., Das, S., O’Daniel, J., Rehm, H., Shashi, V., & Vincent, L. M. (2021). Next-generation sequencing for constitutional variants in the clinical laboratory, 2021 revision: A technical standard of the American College of Medical Genetics and Genomics (ACMG). Genetics in Medicine, 23(8), 1399–1415. https://doi.org/10.1038/s41436-021-01139-4

- SoRelle, J. A., Funke, B. H., Eno, C. C., Ji, J., Santani, A., Bayrak-Toydemir, P., Wachsmann, M., Wain, K. E., & Mao, R. (2024). Slice Testing—Considerations from Ordering to Reporting. The Journal of Molecular Diagnostics, 26(3), 159–167. https://doi.org/10.1016/j.jmoldx.2023.11.008

- Stark, Z., Foulger, R. E., Williams, E., Thompson, B. A., Patel, C., Lunke, S., Snow, C., Leong, I. U. S., Puzriakova, A., Daugherty, L. C., Leigh, S., Boustred, C., Niblock, O., Rueda-Martin, A., Gerasimenko, O., Savage, K., Bellamy, W., Lin, V. S. K., Valls, R., … McDonagh, E. M. (2021). Scaling national and international improvement in virtual gene panel curation via a collaborative approach to discordance resolution. The American Journal of Human Genetics, 108(9), 1551–1557. https://doi.org/10.1016/j.ajhg.2021.06.020
