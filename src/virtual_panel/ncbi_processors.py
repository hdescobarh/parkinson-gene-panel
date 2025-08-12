import logging
from typing import Any

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


class NcbiDatasetsParser:

    @classmethod
    def gene_id_response(cls, query: list[str], ncbi_response: dict[str, Any]):
        output: dict[str, str | None] = {key.strip(): None for key in query}
        missing: dict[str, str | None] = output.copy()

        for current in ncbi_response["reports"]:

            if len(current["query"]) != 1:
                logger.error(
                    f"Expected one query by report, got {len(current["query"])}: {current["query"]}"
                )

            queried_symbol: str = current["query"][0]
            output[queried_symbol] = current["gene"]["gene_id"]
            del missing[queried_symbol]

        if missing:
            logger.warning(f"The response has {len(missing)} symbols.")

        return (output, {symbol for symbol in missing})
