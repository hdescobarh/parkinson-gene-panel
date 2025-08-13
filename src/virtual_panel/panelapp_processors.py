from __future__ import annotations

import logging
import re
from dataclasses import dataclass, field, fields
from enum import Enum
from typing import Any, Optional

import pandas as pd
from pandas.api.types import CategoricalDtype

PanelAppEntityType = Enum(
    "PanelAppEntityType", [("GENE", "gene"), ("STR", "str"), ("CNV", "region")]
)
PanelAppGelStatus = Enum(
    "PanelAppGelStatus", [("GREEN", "3"), ("AMBER", "2"), ("RED", "1"), ("GRAY", "0")]
)

PANEL_BASE_DTYPES = {
    "Name": "string",
    "Type": CategoricalDtype(categories=[v.name for v in PanelAppEntityType]),
    "Status": CategoricalDtype(categories=[v.name for v in PanelAppGelStatus]),
    "GRCh38_chr": CategoricalDtype(
        categories=[str(i) for i in range(1, 23)] + ["X", "Y", "MT"], ordered=True
    ),
    "GRCh38_start": "Int64",
    "GRCh38_end": "Int64",
    "HGNC_ID": "string",
    "HGNC_symbol": "string",
    "Biotype": "string",
}


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


@dataclass
class GenomicCoordinates:
    chr: str
    start: int
    end: int
    reference: str = "GRCh38"


@dataclass
class PanelAppPanelMetadata:
    name: str
    id: str
    version: str
    version_created: str
    relevant_disorders: list[str]

    @classmethod
    def from_dict(cls, data: dict[str, Any]):
        valid_fields = [field.name for field in fields(cls)]
        filtered_data = {k: data[k] for k in valid_fields}
        return cls(**filtered_data)

    def __str__(self):
        name = f"{self.name} (v{self.version}, {self.version_created.split("T")[0]}).\n"
        relevant_disorders = "".join(
            f"\n\t- {item}." for item in self.relevant_disorders
        )
        return f"{name}\tRelevant disorders:{relevant_disorders}"


@dataclass
class PanelAppEntity:
    entity_name: str
    entity_type: PanelAppEntityType
    confidence_level: PanelAppGelStatus
    genomic_coordinates: GenomicCoordinates | None
    other_data: Optional[dict[str, str]]

    @classmethod
    def parse_single_entity(cls, data: dict[str, Any]):
        entity_name = data["entity_name"]
        entity_type = PanelAppEntityType(data["entity_type"])
        confidence_level = PanelAppGelStatus(data["confidence_level"])

        if entity_type in (PanelAppEntityType.GENE, PanelAppEntityType.STR):
            genomic_coordinates, other_data = cls.__parse_gene_data(
                data["gene_data"], entity_name
            )
        else:
            genomic_coordinates = GenomicCoordinates(
                data["chromosome"],
                data["grch38_coordinates"][0],
                data["grch38_coordinates"][1],
            )
            other_data = None
        return cls(
            entity_name, entity_type, confidence_level, genomic_coordinates, other_data
        )

    @classmethod
    def __parse_gene_data(
        cls, gene_data: dict[str, Any], entity_name: str
    ) -> tuple[GenomicCoordinates | None, dict[str, Any]]:

        other: dict[str, str] = {
            "hgnc_symbol": gene_data["hgnc_symbol"],
            "hgnc_id": gene_data["hgnc_id"],
            "biotype": gene_data["biotype"],
        }

        # I will add some protective steps given that the API
        # documentation is not clear about the structure of gene_data.

        # PanelApp v1 uses uses Ensembl/GENCODE annotation.
        # I have found some gen entities without annotation; for example,
        # ATXN8 in PanelApp Australia

        if not gene_data["ensembl_genes"]:
            logger.warning(
                f"Missing GRCh38 Ensembl coordinates in gene_data for {entity_name}."
            )
            return (None, other)

        annotation = gene_data["ensembl_genes"]["GRch38"]

        # Also there are entries with more than one Ensembl version; for example, in
        # Genomics England PanelApp SCO2 and CCDC39 for GRCh38 have Ensembl 90 and 107.
        ensembl_versions = list(annotation.keys())
        if len(ensembl_versions) > 1:
            msg_info = f"{entity_name}: {ensembl_versions}"
            message = (
                f"There are more than one Ensembl release annotation for {msg_info}."
            )
            logger.warning(message)
            ensembl_version = str(max([int(v) for v in ensembl_versions]))
        else:
            ensembl_version = ensembl_versions[0]  # Make it fails if empty

        # Parse gene location
        coordinates_parts = re.split(r"[:-]", annotation[ensembl_version]["location"])
        genomic_coordinates = GenomicCoordinates(
            coordinates_parts[0], int(coordinates_parts[1]), int(coordinates_parts[2])
        )
        other["annotation_source"] = f"Ensembl v.{ensembl_version}"
        return (genomic_coordinates, other)


@dataclass
class PanelAppPanel:
    entities: dict[str, PanelAppEntity]
    metadata: PanelAppPanelMetadata
    df: pd.DataFrame = field(init=False)

    @classmethod
    def from_raw_panel(cls, raw_panel: dict[str, Any]) -> PanelAppPanel:
        metadata = PanelAppPanelMetadata.from_dict(raw_panel)

        parsed_entities: dict[str, PanelAppEntity] = dict()

        for entity_type in ["genes", "strs", "regions"]:
            for entry in raw_panel[entity_type]:

                entity = PanelAppEntity.parse_single_entity(entry)

                # AppPanel entity_names should be unique
                if entity.entity_name in parsed_entities:
                    logger.error(
                        f"Duplicated entity: {entity.entity_name}. Check the source."
                    )

                parsed_entities[entity.entity_name] = entity

        return cls(parsed_entities, metadata)

    def __post_init__(self):
        self.df = self.__fill_dataframe()

    def __fill_dataframe(self) -> pd.DataFrame:

        df = pd.DataFrame(
            [
                {
                    "Name": e.entity_name,
                    "Type": e.entity_type.name,
                    "Status": e.confidence_level.name,
                    "GRCh38_chr": (
                        e.genomic_coordinates.chr if e.genomic_coordinates else pd.NA
                    ),
                    "GRCh38_start": (
                        e.genomic_coordinates.start if e.genomic_coordinates else pd.NA
                    ),
                    "GRCh38_end": (
                        e.genomic_coordinates.end if e.genomic_coordinates else pd.NA
                    ),
                    "HGNC_ID": (
                        pd.NA
                        if e.other_data is None
                        else e.other_data.get("hgnc_id", pd.NA)
                    ),
                    "HGNC_symbol": (
                        pd.NA
                        if e.other_data is None
                        else e.other_data.get("hgnc_symbol", pd.NA)
                    ),
                    "Biotype": (
                        pd.NA
                        if e.other_data is None
                        else e.other_data.get("biotype", pd.NA)
                    ),
                }
                for e in self.entities.values()
            ]
        )

        df = df.astype(PANEL_BASE_DTYPES)

        return df


@dataclass
class PanelAppMerged:
    df: pd.DataFrame
    name_left: str
    name_right: str
    suffix_left: str
    suffix_right: str
    base_col_names: list[str]
    conflicts: dict[str, pd.DataFrame] = field(init=False)

    @classmethod
    def new(
        cls,
        panel1: PanelAppPanel,
        panel2: PanelAppPanel,
        panel1_name: str,
        panel2_name: str,
        panel1_suffix: str,
        panel2_suffix: str,
    ):
        merged_df = pd.merge(
            panel1.df,
            panel2.df,
            how="outer",
            on="Name",
            suffixes=[panel1_suffix, panel2_suffix],
            indicator=True,
            validate="one_to_one",
        )

        # Preserve only the entities with a 🟢 GREEN status
        # (i.e., suitable for clinical interpretation) in at least one panel.
        merged_df = merged_df[
            (
                (merged_df[f"Status{panel1_suffix}"] == "GREEN")
                | (merged_df[f"Status{panel2_suffix}"] == "GREEN")
            )
        ]

        base_col_names = [col_name for col_name in PANEL_BASE_DTYPES.keys()]

        return cls(
            merged_df,
            panel1_name,
            panel2_name,
            panel1_suffix,
            panel2_suffix,
            base_col_names,
        )

    def __post_init__(self):
        self.find_conflicts()

    def find_conflicts(self):
        self.conflicts = dict()

        logger.info("FIND CONFLICTS START.")

        for col_name in self.base_col_names:
            if col_name == "Name":
                continue

            logger.info(f"Checking conflicts for {col_name}...")

            col_conflicts = self.df[
                (self.df["_merge"] == "both")
                & (
                    self.df[f"{col_name}{self.suffix_left}"]
                    != self.df[f"{col_name}{self.suffix_right}"]
                )
            ]
            if col_conflicts.empty:
                logger.info("NOT found conflicts.")
                continue

            logger.warning(f"Conflicts found ({col_name}).")
            self.conflicts[col_name] = col_conflicts

        logger.info(
            f"Columns with conflicts: ({len(self.conflicts)}) {list(self.conflicts.keys())}"
        )
        logger.info("FIND CONFLICTS END.")

    def save_status_conflicts(
        self, dir: str, filename: str = "status_conflicts"
    ) -> pd.DataFrame | None:
        status_conflicts_df = self.conflicts.get("Status", None)

        if status_conflicts_df is None:
            logger.warning("There are not Status conflicts!")
            return None

        logger.info("Saving Status conflicts...")

        df = status_conflicts_df[
            [
                "Name",
                f"Status{self.suffix_left}",
                f"Status{self.suffix_right}",
            ]
        ].reset_index(drop=True)

        df.to_feather(f"{dir}/{filename}.feather")

        logger.info("Saving Status conflicts: Done!")
        return df

    def default_status_solve(self):

        consensus_col_name = "Status_Consensus"

        logger.info("Starting default Status conflict solving strategy...")
        self.df[consensus_col_name] = self.df.apply(
            lambda row, col_name_left, col_name_right: (
                "GREEN" if row[col_name_left] == row[col_name_right] else "MIXED"
            ),
            args=[
                f"Status{self.suffix_left}",
                f"Status{self.suffix_right}",
            ],
            axis=1,
        )

        self.df[consensus_col_name] = self.df[consensus_col_name].astype("category")
        logger.info("Default Status conflict solving strategy: End.")

    def make_consensus(
        self,
        custom_include: list[str] = ["Status_Consensus"],
        update_conflicts: bool = False,
    ) -> pd.DataFrame:
        if update_conflicts:
            logger.info("Updating conflicts...")
            self.find_conflicts()

        logger.info("MAKE CONSENSUS START.")

        # Merge in a single base col_name fields without conflicts
        logger.info("Copying unconflicted...")
        consensus_col_names = ["Name"] + custom_include

        for col_name in self.base_col_names:
            if col_name == "Name" or col_name in self.conflicts.keys():
                continue

            consensus_col_names.append(col_name)

            self.df[col_name] = self.df.apply(
                self.__unconflicted_consensus,
                axis=1,
                args=[
                    f"{col_name}{self.suffix_left}",
                    f"{col_name}{self.suffix_right}",
                ],
            ).astype(PANEL_BASE_DTYPES.get(col_name, "object"))

        logger.info("Adding new columns...")

        origin_left = self.suffix_left.removeprefix("_")
        origin_right = self.suffix_right.removeprefix("_")
        self.df["Origin"] = self.df.apply(
            self.__set_origin, axis=1, args=[origin_left, origin_right]
        ).astype(
            CategoricalDtype(
                [
                    origin_left,
                    "Both",
                    origin_right,
                ],
                ordered=True,
            )
        )
        consensus_col_names.append("Origin")

        logger.info("Creating consensus DataFrame...")
        consensus_panel_df = self.df[consensus_col_names].reset_index(drop=True).copy()

        logger.info("MAKE CONSENSUS END.")
        return consensus_panel_df

    def __unconflicted_consensus(
        self, row: pd.Series, col_name_left: str, col_name_right: str
    ):
        if row["_merge"] == "right_only":
            return row[col_name_right]
        else:
            return row[col_name_left]

    def __set_origin(self, row: pd.Series, origin_left: str, origin_right: str):
        if row["_merge"] == "right_only":
            return origin_right
        elif row["_merge"] == "left_only":
            return origin_left
        else:
            return "Both"
