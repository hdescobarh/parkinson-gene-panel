from __future__ import annotations

import logging
import re
from dataclasses import dataclass, fields
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

logger = logging.getLogger(__name__)
logger.setLevel(logging.WARNING)


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

    def into_dataframe(self) -> pd.DataFrame:

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
                }
                for e in self.entities.values()
            ]
        )

        type_dtype = CategoricalDtype(categories=[v.name for v in PanelAppEntityType])
        status_dtype = CategoricalDtype(categories=[v.name for v in PanelAppGelStatus])

        df = df.astype(
            {
                "Name": "string",
                "Type": type_dtype,
                "Status": status_dtype,
                "GRCh38_chr": "string",
                "GRCh38_start": "Int64",
                "GRCh38_end": "Int64",
                "HGNC_ID": "string",
                "HGNC_symbol": "string",
            }
        )

        return df
