#!/usr/bin/env python3

import argparse

import pyerrors as pe
import scipy.interpolate
import uncertainties

from provenance import describe_inputs
from read import read_all_fit_results


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_filenames", metavar="input_filename", nargs="+")
    parser.add_argument("--output_filename", default=None)
    return parser.parse_args()


def interpolating_form(a, x):
    # Eq. (11) of 2402.18038
    return a[0] / 2 + (x - a[1])


def get_g_squared_beta(data):
    g_squared, beta_centre, beta_upper, beta_lower = [], [], [], []
    for datum in sorted(data, key=lambda datum: datum["g_squared"]):
        g_squared.append(datum["g_squared"])
        beta = datum["continuum_extrapolation"][0]
        beta.gamma_method()
        beta_centre.append(beta.value)
        beta_upper.append(beta.value + beta.dvalue)
        beta_lower.append(beta.value - beta.dvalue)
    return g_squared, beta_centre, beta_upper, beta_lower


def fit_single(g_squared, beta):
    spline = scipy.interpolate.PchipInterpolator(g_squared, beta)
    result = spline.roots(extrapolate=False)
    if len(result) != 1:
        raise ValueError(f"Obtained {len(result)} roots.")
    g_star_squared = result[0]

    # Eq. (11) of 2402.18038
    return g_star_squared, 2 * spline(g_star_squared, nu=1)


def get_ufloat(centre, upper, lower):
    return uncertainties.ufloat(centre, abs(upper - lower) / 2)


def fit(data):
    g_squared, beta_centre, beta_upper, beta_lower = get_g_squared_beta(data)
    g_star_2_centre, gamma_star_centre = fit_single(g_squared, beta_centre)
    g_star_2_upper, gamma_star_upper = fit_single(g_squared, beta_upper)
    g_star_2_lower, gamma_star_lower = fit_single(g_squared, beta_lower)

    g_star_squared = get_ufloat(g_star_2_centre, g_star_2_upper, g_star_2_lower)
    gamma_star = get_ufloat(gamma_star_centre, gamma_star_upper, gamma_star_lower)

    return g_star_squared, gamma_star


def get_metadata(data):
    description = "Estimate of fixed point and anomalous dimension at fixed point."
    specific_keys = ["filename", "g_squared"]
    consistent_keys = ["min_time", "max_time", "operator"]
    return describe_inputs(data, description, specific_keys, consistent_keys)


def main():
    args = get_args()
    data = read_all_fit_results(args.input_filenames)
    g_star_squared, gamma_star = fit(data)
    for datum in data:
        datum["continuum_extrapolation"][0].gamma_method()
    if args.output_filename:
        pe.input.json.dump_dict_to_json(
            {
                "value_g_star_squared": g_star_squared.nominal_value,
                "value_gamma_star": gamma_star.nominal_value,
                "uncertainty_g_star_squared": g_star_squared.std_dev,
                "uncertainty_gamma_star": gamma_star.std_dev,
            },
            args.output_filename,
            description=get_metadata(data),
        )
    else:
        print(f"g_{{GF*}}^2 interpolation: {g_star_squared}")
        print(f"gamma*: {gamma_star}")


if __name__ == "__main__":
    main()
