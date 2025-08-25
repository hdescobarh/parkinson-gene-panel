# Parkinson’s Disease Virtual Gene Panel

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](./LICENSE)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgreen.svg)](./LICENSE-CC)

```
# TODO: add language badges? Need to think what worths showing and not add noise...
```

## Description

A (hypothetical) clinical laboratory is struggling to maintain their overgrown set of static Targeted Gene Sequencing (TGS) panels and is moving to Whole Exome Sequencing (WES) based virtual gene panels. As part of this pilot, it is introducing a virtual panel for testing Parkinsonism (MONDO:0021095), with a focus in Parkinson's Disease (MONDO:0005180), including the rarer Early-Onset presentations (MONDO:0017279).

The laboratory requires, following the American College of Medical Genetics and Genomics (ACMG) guidelines, develop and validate the clinical test, this includes wet laboratory, bioinformatics pipeline and reporting.

An initial step is to define a reproducible workflow for generating the initial set of testing regions, which is necessary for the optimization and validation steps of the bioinformatics pipeline. I propose a semiautomatic workflow to merge, curate and generate bioinformatics pipeline ready-to-use files for Parkinson's Disease virtual gene panels. It generates ready-to-use files to be used in the virtual panel’s bioinformatics pipeline.

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
