# GNU Make re-implementation of [hp_pv](https://github.com/edbennett/hp_pv) analysis workflow

This repo is part of a project examining and evaluating different workflow managers by re-factoring a Lattice simulation analysis workflow. This repo contains the re-implementation in [`GNU Make`](https://www.gnu.org/software/make/) of [this workflow](https://github.com/edbennett/hp_pv), written in `snakemake`.

The open source [data](https://zenodo.org/records/10719052) used in this workflow was originally released as part of [this paper](https://arxiv.org/abs/2402.18038) by Peterson and Hasenfratz.
## Requirements
- [pixi](https://pixi.prefix.dev/latest/installation)
- [Git](https://github.com/git-guides/install-git)
- [LaTeX](https://tug.org/texlive/)
- [GNU Make](https://www.gnu.org/software/make/)

It is highly unlikely your linux distro does not come with GNU Make included. 

`doit`, `pyerrors`, `matplotlib` and the other required packages will be installed by `pixi` when you first execute `pixi run`.

## Setup

Clone this repo and `cd` into it
```
git clone https://github.com/gray95/make_hp_pv.git && cd make_hp_pv
```

## Running

```
pixi run make -j<N>
```

With `N=6` this workflow takes ~18 mins to run end-to-end on an AMD Ryzen 5 5600. On a laptop with an Intel i7-8565U it takes ?? mins.

The plots produced by the workflow are placed in `assets/`

### Useful commands
Dry run
```
pixi run make -n
```
If you want to run the workflow from scratch the Makefile has a target for cleaning up the directory
```
pixi run make clean
```

### Notes


### To-Do
- [x] implement all recipes to reproduce workflow 
- [x] confirm wflow runs end-to-end.
- [ ] check reproducible over different machines/OSes.
- [ ] investigate portable Makefiles (posix compliance etc.)
