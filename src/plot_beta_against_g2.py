#!/usr/bin/env python3

import argparse

import matplotlib.pyplot as plt
import numpy as np
import pyerrors as pe

from fit_beta_against_g2 import interpolating_form
from plots import PlotPropRegistry, errorbar_pyerrors, save_or_show
from perturbation_theory import add_perturbative_lines
from read import read_all_fit_results


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("fit_filenames", nargs="+", metavar="beta_fit_filename")
    parser.add_argument("--plot_filename", default=None)
    parser.add_argument("--plot_styles", default="styles/paperdraft.mplstyle")
    return parser.parse_args()


def split_errors(series):
    return [datum.value for datum in series], [datum.dvalue for datum in series]


def output_fits(fit_results, filename):
    pe.input.json.dump_dict_to_json(fit_results, filename)


def plot_fit(x_values, fit_result, ax, colour=None):
    scan_x = np.linspace(min(x_values), max(x_values), 1000)
    scan_y = interpolating_form(np.asarray(fit_result, dtype=float), scan_x)
    scan_errors = pe.fits.error_band(scan_x, interpolating_form, fit_result)
    ax.fill_between(
        scan_x, scan_y + scan_errors, scan_y - scan_errors, color=colour, alpha=0.2
    )


def plot(fit_results):
    fig, ax = plt.subplots(layout="constrained", figsize=(3.5, 2.5))
    colours = PlotPropRegistry.colours()

    ax.set_xlabel(r"$g_{\mathrm{GF}}^2(t; g_0^2)$")
    ax.set_ylabel(r"$\beta_{\mathrm{GF}}(t; g_0^2)$")

    for result in fit_results:
        data = read_all_fit_results(
            [source["filename"] for source in result["data_sources"]]
        )
        time = result["time"]
        gGF2 = [datum["gGF^2"][0] for datum in data]
        betaGF = [datum["betaGF"][0] for datum in data]
        errorbar_pyerrors(
            ax,
            gGF2,
            betaGF,
            label=f"$t / a^2 = {time}$",
            color=colours[result["time"]],
        )

        plot_fit(
            [value.value for value in gGF2],
            result["beta_interpolation"],
            ax,
            colour=colours[result["time"]],
        )

    _, xmax = ax.get_xlim()
    add_perturbative_lines(ax, 0, xmax, "fun", 12, 3)

    ax.set_xlim(0, xmax)
    ax.set_ylim(-2.4, 0.6)
    ax.legend(loc="best")

    return fig


def main():
    args = get_args()
    plt.style.use(args.plot_styles)
    fit_results = read_all_fit_results(args.fit_filenames)
    save_or_show(plot(fit_results), args.plot_filename)


if __name__ == "__main__":
    main()
