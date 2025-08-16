import logging
import re

import pandas as pd

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# put in module ncbi_reference_processors

# Uncompressed GFF can be quite large.
# This is a small sacrifice of readability by performance.
# https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md
RawAnnotationsType = list[
    tuple[
        str,  # col9 (under NCBI's custom tag "gene"): gene symbol
        str,  # col1: chromosome
        str,  # col4: start (1-based)
        str,  # col5: end (inclusive)
        str,  # col7: strand
    ]
]
RAW_ANNOTATIONS_COL_NAMES = ["HGNC_symbol", "RefSeq-Accn", "Start", "End", "Strand"]
RAW_ANNOTATIONS_COL_DTYPES = ["string", "string", "Int64", "Int64", "string"]


class Gff3Handler:

    _include_symbols: dict[str, list[int]]

    _type: re.Pattern = re.compile(r"(gene|exon)")

    # Include ONLY valid HGNC symbols. Accordingly to HGNC Guidelines,
    # symbols contain only uppercase Latin letters and Arabic numerals,
    # no punctuation, some groups may have hyphens.
    _stable_hgnc: re.Pattern = re.compile(r"[A-Z0-9-]+")

    # Relax the condition to include Corfs placeholder symbols.
    _any_hgnc: re.Pattern = re.compile(r"gene=([orfA-Z0-9-]+)")

    def __init__(
        self,
        symbols: set[str],
    ) -> None:

        include_symbols = {key: [0, 0] for key in symbols}

        for s in include_symbols:
            if not self._stable_hgnc.fullmatch(s):
                logger.warning(
                    f"Symbol {s} may not be a valid stable HGNC symbol."
                    + "Check if it is a place holder or a non-HGNC symbol."
                )

        self._include_symbols = include_symbols

    def _parse_line(self, line: str):

        # skip GFF directives
        if line.startswith("#"):
            return None
        # Skip ALTs and PATCHES. All the chromosomes primary assembly
        # RefSeq accessions start with NC_0
        elif not line.startswith("NC_0"):
            return None

        columns = line.split("\t")
        if len(columns) != 9:
            message = f"GFF3 files are nine-column files, found {len(columns)}."
            logger.error(message)
            raise RuntimeError(message)

        # filter out non exon or gene types
        if not re.fullmatch(self._type, columns[2]):
            return None

        # Recover gene tag value
        gene_match = self._any_hgnc.search(columns[8])
        if gene_match:
            gene_symbol: str = gene_match.group(1)
        else:
            message = (
                "Unexpected format in attributes. "
                + "All gene and exon type lines must have 'gene' field in attributes. "
                + f"Are you sure this is an NCBI Datasets Genome GFF file? Line:\n{line}\n"
            )
            logger.warning(message)
            raise RuntimeError(message)

        # Filter in listed genes
        if gene_symbol not in self._include_symbols:
            return None
        else:
            return (
                columns[2],  # sequence type
                (
                    gene_symbol,  # gene symbol
                    columns[0],  # chromosome
                    columns[3],  # sequence start (1-based)
                    columns[4],  # sequence end (inclusive)
                    columns[6],  # strand
                ),
            )

    def parse(self, gff_path: str, output_path: str) -> pd.DataFrame:

        gene_annotations: RawAnnotationsType = list()

        with open(gff_path, "rt") as gff, open(output_path, "w") as out_file:

            for line in gff:
                if (result := self._parse_line(line)) is None:
                    continue
                sequence_type, fields = result

                match sequence_type:
                    case "gene":
                        self._include_symbols[fields[0]][0] += 1
                        gene_annotations.append(fields)
                    case "exon":
                        # chrom start end
                        self._include_symbols[fields[0]][1] += 1
                        out_file.write(f"{fields[1]}\t{fields[2]}\t{fields[3]}\n")
                    case _:
                        raise AssertionError(f"Unexpected sequence type ({fields[0]}).")

                out_file.writelines("\t".join((*(fields), "\n")))

        return self._gene_annotations_df(gene_annotations)

    # For a given symbol, the number of lines with the feature exon is not
    # equivallent to the number of exons. A given exon sequence can be child of multiple
    # transcripts and appear multiple times
    def get_metrics(self) -> pd.DataFrame:
        df = pd.DataFrame.from_dict(
            self._include_symbols,
            orient="index",
            columns=["gene_lines", "exon_lines"],
            dtype="Int16",
        )
        return df

    def _gene_annotations_df(
        self, gene_annotations: RawAnnotationsType
    ) -> pd.DataFrame:

        df = pd.DataFrame(
            gene_annotations,
            columns=RAW_ANNOTATIONS_COL_NAMES,
        ).astype(
            {
                key: value
                for key, value in zip(
                    RAW_ANNOTATIONS_COL_NAMES, RAW_ANNOTATIONS_COL_DTYPES
                )
            }
        )
        return df
