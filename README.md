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

## File structure

```
# TODO: define what files worth include.

# TODO: add with `tree --gitignore --dirsfirst .`
```

## Releases

```
# TODO: Define versioning
# TODO: Explain clearly the release files
# TODO: Add link to release page
```

## For developers

```
# TODO: explain the use of make for orchestration, automation and as a reproducibility layer.

# TODO: maybe add a warning about fixing the Python build environment as another reproducibility layer.

# TODO: probably I will need to mention why using a virtual environment in a container it is a good practice.
```

### Dependencies

```
# TODO: Explain OS dependencies: make, python, jq, wget, md5sum and the use of  `make deps`

# TODO: Define how describe Python dependencies: Python version, pyproject.toml, requirements.txt. What are the use, what are locked.

```

### Linux local installation and setup

```bash
make init
make download-refseq
```

### Docker installation and setup

```
# TODO: Pending evaluating if include Docker.
```

## Limitations

- Only tested on Linux.

```
# TODO: pending tests (?).

# TODO: mention that in a real lab setting it would be better to deploy an internal DB instead of parsing multiple times annotation files.

# TODO: mention the problem of reproducibility with Docker (?) (depending on third-party images repositories, friction with IDEs, management of keys and Git)
```

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
