#!/usr/bin/env python3

import argparse

import matplotlib.pyplot as plt

from fit_beta_against_g2 import interpolating_form
from names import operator_names
from plots import PlotPropRegistry, errorbar_pyerrors, legend, save_or_show
from plot_infinite_volume_extrapolation import plot_fit
from read import read_all_fit_results


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("fit_filenames", metavar="fit_filename", nargs="+")
    parser.add_argument("--unfit_filenames", metavar="unfit_filename", nargs="+")
    parser.add_argument("--tick_times", metavar="tick_time", type=float, nargs="+")
    parser.add_argument("--plot_styles", default="styles/paperdraft.mplstyle")
    parser.add_argument("--output_filename", default=None)
    return parser.parse_args()


def plot_single(ax, fit, use_fit, colours, markers):
    colour = colours[fit["g_squared"]]
    marker = markers[fit["operator"]]
    point_data = read_all_fit_results(
        [source["filename"] for source in fit["data_sources"]]
    )
    spacings = [1 / datum["time"] for datum in point_data]
    beta_values = [
        interpolating_form(
            datum["beta_interpolation"], fit["g_squared"], n=datum["order"]
        )
        for datum in point_data
    ]
    for value in beta_values:
        value.gamma_method()
    errorbar_pyerrors(
        ax,
        spacings,
        beta_values,
        color=colour,
        marker=marker,
        fillstyle="full" if use_fit else "none",
    )

    _, xmax = ax.get_xlim()
    if use_fit:
        plot_fit(ax, fit["continuum_extrapolation"], xmax, colour=colour)


def plot(fit_data, unfit_data, tick_times=[]):
    fig, ax = plt.subplots(layout="constrained", figsize=(3.5, 5))
    markers = PlotPropRegistry(["^", "o"])
    colours = PlotPropRegistry.colours()

    ax.set_xlim(0, 1.03 / (min(tick_times) if tick_times else None))

    for fit in fit_data:
        plot_single(ax, fit, use_fit=True, colours=colours, markers=markers)

    for unfit in unfit_data:
        plot_single(ax, unfit, use_fit=False, colours=colours, markers=markers)

    xtick_positions = [0] + [1 / time for time in tick_times]
    xtick_labels = ["0"] + [f"$1/{time:g}$" for time in tick_times]
    ax.set_xticks(xtick_positions, xtick_labels)
    ax.grid(axis="x")

    ax.set_xlabel(r"$a^2/t$")
    ax.set_ylabel(r"$\beta_{\mathrm{GF}}(t;g_0^2)$")

    ax.add_artist(
        legend(
            ax,
            colours,
            attr="colour",
            mapping=lambda g2: f"$g_{{\\mathrm{{GF}}}}^2 = {g2}$",
            columns=1,
            position="lower left",
        )
    )
    legend(
        ax,
        markers,
        attr="marker",
        mapping=operator_names.get,
        columns=2,
        position="upper right",
    )

    return fig


def main():
    args = get_args()
    plt.style.use(args.plot_styles)

    fit_data = read_all_fit_results(args.fit_filenames)
    unfit_data = read_all_fit_results(args.unfit_filenames)
    save_or_show(plot(fit_data, unfit_data, args.tick_times), args.output_filename)


if __name__ == "__main__":
    main()
