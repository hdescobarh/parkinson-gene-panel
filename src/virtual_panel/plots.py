import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import pandas as pd
import seaborn as sns
from matplotlib_venn import venn2

from .panelapp_processors import PanelAppMerged


def plot_merged_venn_diagram(panel: PanelAppMerged, ax=None):
    merge_origin_counts = panel.df["_merge"].value_counts().to_dict()

    if ax is None:
        fig, ax = plt.subplots(figsize=(4, 4))

    venn_diagram = venn2(
        (
            merge_origin_counts["left_only"],
            merge_origin_counts["right_only"],
            merge_origin_counts["both"],
        ),
        (
            panel.suffix_left.removeprefix("_"),
            panel.suffix_right.removeprefix("_"),
        ),
        ("#029AC2", "#DF6D02"),
        0.9,
        ax=ax,
    )

    plt.title("GREEN Entities Across Panels", fontsize=14, fontweight="bold")

    for label in venn_diagram.set_labels:
        label.set_fontsize(14)
        label.set_fontweight("bold")

    for label in venn_diagram.subset_labels:
        if label:
            label.set_fontsize(16)

    return ax


def count_plot(
    data: pd.DataFrame,
    x: str,
    width: float = 8,
    height: float = 5,
    add_containers: bool = False,
    ax=None,
    ticks: None | int = None,
    palette=sns.hls_palette(3, h=0.6, l=0.5, s=0.9),  # noqa: E741
):
    if ax is None:
        fig, ax = plt.subplots(figsize=(width, height))

    sns.countplot(data=data, x=x, hue="Type", ax=ax, palette=palette)

    if add_containers:
        for container in ax.containers:
            ax.bar_label(container, label_type="edge", padding=2)  # type: ignore

    if ticks is not None:
        ax.yaxis.set_major_locator(ticker.MultipleLocator(ticks))

    return ax
