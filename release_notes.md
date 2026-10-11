# Latest

## 11th Oct 2026 — source plotting compatibility fixes

- Fix the R2026b preview failure caused by accessing `Position` on a Bode chart
  label and enabling legacy exploration controls.
- Replace multi-output legends and positional indexing of hidden graphics with
  shared plotting code for previews, intermediate fits, final fits, and reduced
  models. Preserve compatibility with the R2023b response-plot implementation.
- Only sample uncertainty for identified models with covariance data; arbitrary
  `UserData` no longer triggers `rsample`.
- Keep preview frequency limits in the selected display units and avoid invalid
  magnitude limits when the measured response includes zeros.
- Initialize legacy plots before hiding them so saved plots contain their curves.
- Replace legacy INI argument-count checks with `narginchk`.
- Skip redundant utility-path updates when launched as an installed add-on.
- Use unique temporary images for embedded previews and explicit figure handles
  for exports. Restore warning settings after objective evaluations.
- All nine plotting regression tests pass on MATLAB R2023b and R2026b.
- Add `tests/fitTFPlotTest.m` and instructions for running the source checkout.
  The existing packaged installer has not been rebuilt.

## 25th Oct 2022

- Fixed Multi-file upload functionality
- Preview figure now persists (when FIG_HANDLE_VISIBILTY==1)

# Older Updates

-      6th May 2019: Initial Commit
-      1st June 2019: Modifed "CUSTOM_WEIGHT"
-      2nd June 2019: Now auto damps unphysical resonances
-      6th June 2019: Now fits time series data
-     20th June 2019: Multiple trials with different initializations
-     24th Sep 2019:  Model order reduction
-     21th Oct 2019, Added invfreqs method
-     22th Oct 2019, Modified residual (now includes cohWeight)
-     22th Oct 2019, Added iterative GUESSing
-     25th Oct 2019, modified make_plot function (now also displays previous best result)
-     14th May 2020:  Enforce Uncertainity Estimation (+plot ZPK values).
-     19th May 2020:  Attain a desired level of goodness-of-fit.
-     27th June 2020: Add Noise Floor Estimation
-     14th July 2020: Added option to provide bodeoptions
-     15th July 2020: Added minreal to provide model order reduction
-                     Options to specify desired model order reduction
-     7th Aug 2020:  Option to read from configuration file.
-    17th Aug 2020: Major Update:
-                       -Better model order reduction (constrained wrt GOF)
-                       -Plotting improved
-    29th Oct 2020:  Auto-Decrease the number of freq samples to 1000 samples
-    23rd Feb 2021:  Added-> Fill missing values (NaNs) in processed TF  with interpolated values
-
-    28th Apr 2022:  -> Added minimum-phase state-space model fitting using log-Chebyshev magnitude design
-                    -> Supports possible SysID with IODelay