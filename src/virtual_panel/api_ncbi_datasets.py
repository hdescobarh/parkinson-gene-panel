import logging
from typing import Any

import httpx

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

NCBI_DATASET_BASE_URL = "https://api.ncbi.nlm.nih.gov/datasets/v2"


class NcbiClient:

    @classmethod
    def refseq_gene_id_from_symbol(
        cls, symbols: list[str], page_token: str | None = None
    ) -> dict[str, Any] | None:

        if len(symbols) > 1000:
            logger.warning(
                "List longer than maximum page_size. "
                + "To retrieve the next page recall with the response page_token"
            )

        params = {
            "returned_content": "IDS_ONLY",
            "page_size": min(
                1000, len(symbols) + 1
            ),  # +1 to avoid getting tokens for empty pages
        }

        if page_token:
            params["page_token"] = page_token

        response = httpx.get(
            f"{NCBI_DATASET_BASE_URL.removesuffix("/")}/gene/symbol/"
            + f"{",".join(symbols)}/taxon/9606",
            params=params,
        )

        match response.status_code:
            case 200:
                return response.json()
            case _:
                response.raise_for_status()
