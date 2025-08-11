# Target Regions for a Parkinson’s Disease Virtual Gene Panel

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](./LICENSE)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgreen.svg)](./LICENSE-CC)

Hybrid Curation of Virtual Gene Panels for Parkinson's Disease

This project provides a series of Python scripts to partially automate the creation of virtual gene panels. The workflow is designed to be interactive, with Jupyter Notebooks serving as the primary interface for the user to:

Execute the automated steps (e.g., data collection and enrichment).

Perform critical manual tasks, such as reviewing data for conflicts and ensuring suitability for clinical interpretation.

The final result is a curated set of ready-to-use BED files.

## Use

### Local Linux

```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -e .
pip install -e .[dev]
nbdime config-git --enable
jupyter lab --notebook-dir="./notebooks" --ServerApp.token='' --ServerApp.password='' "./notebooks/parkinson_panel_gene_list.ipynb"
```

## License

This repository uses a dual-license structure:

- **Source code** is licensed under the Apache License 2.0 (see [LICENSE](LICENSE)).
- **Non-code content**, including documentation, academic text, and original diagrams, is licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0) (see [LICENSE-CC](LICENSE-CC)).

⚠️ Cited material from third-party sources (e.g., quotations, excerpts, figures) is not covered by these licenses and remains under its original copyright.
