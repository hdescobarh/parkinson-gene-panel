from dataclasses import dataclass
from enum import Enum

import httpx

PANELAPP_ENGLAND_API_BASE = "https://panelapp.genomicsengland.co.uk/api/v1/"
PANELAPP_AUSTRALIA_API_BASE = "https://panelapp-aus.org/api/v1/"


PanelAppHealthSystem = Enum("PanelAppHealthSystem", [("ENGLAND", 1), ("AUSTRALIA", 2)])


@dataclass
class PanelAppPanelId:
    healthcare_system: PanelAppHealthSystem
    id: str
    version: str

    def __str__(self):
        return f"PA-{self.healthcare_system.name}_{self.id}_v{self.version}"


@dataclass
class PanelAppClient:
    healthcare_system: PanelAppHealthSystem

    def __post_init__(self):
        match self.healthcare_system:
            case PanelAppHealthSystem.ENGLAND:
                self.base_url = PANELAPP_ENGLAND_API_BASE
            case PanelAppHealthSystem.AUSTRALIA:
                self.base_url = PANELAPP_AUSTRALIA_API_BASE
            case _:
                raise ValueError("Invalid PanelAppHealthSystem variant.")

    def get_single_panel(self, panel: PanelAppPanelId):
        response = httpx.get(
            f"{self.base_url.strip("/")}/panels/{panel.id}/",
            params={"version": panel.version},
        )
        match response.status_code:
            case 200:
                return response.json()
            case _:
                response.raise_for_status()
