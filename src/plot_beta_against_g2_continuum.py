#!/usr/bin/env python3

import argparse

import matplotlib.pyplot as plt

from names import operator_names
from plots import save_or_show
from perturbation_theory import add_perturbative_lines
from read import read_all_fit_results


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("fit_filenames", nargs="+", metavar="beta_continuum_filename")
    parser.add_argument("--plot_filename", default=None)
    parser.add_argument("--plot_styles", default="styles/paperdraft.mplstyle")
    return parser.parse_args()


def group_data(beta_continuum):
    operators = set([datum["operator"] for datum in beta_continuum])
    return {
        operator: sorted(
            [datum for datum in beta_continuum if datum["operator"] == operator],
            key=lambda datum: datum["g_squared"],
        )
        for operator in operators
    }


def plot(beta_continuum):
    fig, ax = plt.subplots(layout="constrained", figsize=(3.5, 2.5))

    ax.set_xlabel(r"$g_{\mathrm{GF}}^2$")
    ax.set_ylabel(r"$\beta_{\mathrm{GF}}(g_{\mathrm{GF}}^2)$")

    for operator, op_subset in group_data(beta_continuum).items():
        g_squared, beta_lower, beta_upper = [], [], []
        for datum in op_subset:
            g_squared.append(datum["g_squared"])
            beta = datum["continuum_extrapolation"][0]
            beta.gamma_method()
            beta_lower.append(beta.value - beta.dvalue)
            beta_upper.append(beta.value + beta.dvalue)

        ax.fill_between(
            g_squared, beta_lower, beta_upper, label=operator_names[operator], alpha=0.3
        )

    _, xmax = ax.get_xlim()
    add_perturbative_lines(ax, 0, xmax, "fun", 12, 3)
    ax.set_xlim(0, xmax)
    ax.set_ylim(-0.3, 0.7)

    ax.axhline(0, color="black")
    ax.legend(loc="best")

    return fig


def main():
    args = get_args()
    plt.style.use(args.plot_styles)
    beta_continuum = read_all_fit_results(args.fit_filenames)
    save_or_show(plot(beta_continuum), args.plot_filename)


if __name__ == "__main__":
    main()
