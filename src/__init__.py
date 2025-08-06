__version__ = "0.1.0"
__author__ = "Hans Escobar"
__contact__ = {
    "email": "hansescobar@proton.me",
    "github": "https://github.com/hdescobarh",
    "linkedin": "https://linkedin.com/in/hansescobar",
}


from .api_client import PanelAppClient, PanelAppHealthSystem, PanelAppPanelId
from .panelapp_processors import (
    PanelAppEntity,
    PanelAppEntityType,
    PanelAppGelStatus,
    PanelAppMerged,
    PanelAppPanel,
    PanelAppPanelMetadata,
)

__all__ = [
    "PanelAppHealthSystem",
    "PanelAppPanelId",
    "PanelAppClient",
    "PanelAppEntityType",
    "PanelAppGelStatus",
    "PanelAppPanelMetadata",
    "PanelAppEntity",
    "PanelAppPanel",
    "PanelAppMerged",
]
