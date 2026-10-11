# AAA comparison — MATLAB R2026b, 11 October 2026

System Identification AAA is available starting in **R2026a**. RIFF now uses it
for routine 5 on supported releases, with `tfest` and AAA checked by default.
Keep both: these measurements do not support replacing N4SID with AAA everywhere.
The older RF implementation remains available explicitly as `AAA_BACKEND='rf'`.
The current RIFF release targets R2026b; use the earlier major release for R2023b.

## Method

Run from the repository root:

```matlab
addpath('benchmarks');
results = compare_aaa_backends(fullfile(tempdir,'riff_aaa_benchmark'));
```

This script requires System Identification and RF Toolboxes on R2026a+.
It evaluates all five bundled text sweeps, removing invalid/zero-frequency
samples, keeping at most 600 evenly indexed samples, and withholding every fifth
frequency. Models train on the other 80%. It searches pole limits 4, 8 and 12;
SysID methods use equal and inverse-magnitude weighting. Each method's order
and weighting are selected using **training** GOF only.

Models are continuous-time and stable, with no explicit delay and no RIFF
smoothing, frequency-window optimization, or resonance damping. An apparent
high-frequency phase-slope delay is printed for diagnosis; it is not fitted.
The SysID AAA comparison includes both 0 and 20 requested refinement iterations.
These produced identical selected models in this run; RIFF uses 0 for direct AAA.
`tfest` uses its existing N4SID initialization with up to 20 iterations.
RF AAA is tested separately with its default and relative metrics, rather than
randomly choosing between them as the old RIFF objective did.

The score below is RIFF's existing 50/50 normalized log-magnitude and wrapped-phase
score, evaluated on held-out frequencies. Higher is better; 100 is exact. Negative
scores are possible and indicate poor agreement under this metric. Phase-wrap
jumps can dominate it. A complex-response NRMSE is also recorded in the CSV and
can rank the algorithms differently.

## Held-out RIFF GOF (%)

| Measurement | SysID AAA | tfest / N4SID | RF AAA default | RF AAA relative |
|---|---:|---:|---:|---:|
| damped_transmission.txt | -3.41 | -1.53 | -5.49 | -131.27 |
| isolated_one_over_plant.txt | 20.74 | 81.16 | 45.42 | 14.77 |
| isolated_transmission.txt | 7.64 | -3.23 | -8.45 | -60.29 |
| sample_TF.txt | -9.05 | 1.90 | -10.36 | -111.67 |
| sample_TF2.txt | -7.32 | -22.89 | -119.96 | -187.28 |

All 120 estimates completed without errors and returned stable models. SysID AAA
beats tfest on 2/5 sweeps and RF AAA's default metric on 4/5 under this score.
Neither backend is uniformly better. Several broadband fits are poor for every
method, so these results justify an additional default candidate, not a claim
that AAA solves all of these measurements.

Interleaved frequencies are not independent measurement repeats. This small
benchmark does not establish out-of-band accuracy or statistical significance.
The pole cap, data thinning and absence of frequency-window search also differ
from a full interactive RIFF run. Timings are individual estimator calls, not
whole app fits; JIT/startup and caching affect them. Raw measurements and all
selected-model scores, orders, timings and errors are in the adjacent CSV files.

## Sources

- [ssestOptions: AAA introduced in R2026a](https://in.mathworks.com/help/ident/ref/ssestoptions.html)
- [ssest: AAA order may exceed nx by one](https://in.mathworks.com/help/ident/ref/ssest.html)
- [MathWorks AAA identification example](https://in.mathworks.com/help/ident/ug/estimate-siso-state-space-model-using-aaa-algorithm.html)
- [RF Toolbox rational](https://www.mathworks.com/help/rf/ref/rational.html)
