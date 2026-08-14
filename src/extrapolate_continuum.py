#!/usr/bin/env python3

import argparse

import pyerrors as pe

from extrapolate_infinite_volume import linear_fit
from fit_beta_against_g2 import interpolating_form
from provenance import describe_inputs
from read import read_all_fit_results


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_filenames", metavar="input_filename", nargs="+")
    parser.add_argument("--g_squared", type=float, required=True)
    parser.add_argument("--output_filename", default=None)
    return parser.parse_args()


def get_metadata(data, g_squared):
    description = "Continuum limit of beta function at fixed coupling."
    specific_keys = ["filename", "time"]
    consistent_keys = ["Nc", "operator"]
    return describe_inputs(
        data,
        description,
        specific_keys,
        consistent_keys,
        g_squared=g_squared,
        min_time=min(datum["time"] for datum in data),
        max_time=max(datum["time"] for datum in data),
    )


def fit(data, g_squared):
    x_values = [1 / datum["time"] for datum in data]
    beta_values = [
        interpolating_form(datum["beta_interpolation"], g_squared, datum["order"])
        for datum in data
    ]
    for beta in beta_values:
        beta.gamma_method()
    result = pe.fits.least_squares(x_values, beta_values, linear_fit, silent=True)
    return result.fit_parameters


def main():
    args = get_args()
    data = read_all_fit_results(args.input_filenames)
    result = fit(data, args.g_squared)
    if args.output_filename:
        pe.input.json.dump_dict_to_json(
            {"continuum_extrapolation": result},
            args.output_filename,
            description=get_metadata(data, args.g_squared),
        )
    else:
        for param in result:
            param.gamma_method()
        print(f"continuum beta(g^2 = {args.g_squared}): {result}")


if __name__ == "__main__":
    main()
