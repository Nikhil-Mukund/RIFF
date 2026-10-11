# Release notes

## v4.0.1 — Measurement joining and refreshed demos (11 October 2026)

- Fix joining SDF measurements taken over different frequency bands: reversed
  file order and unequal overlap grids no longer cause dimension errors.
- Resample onto a shared Hz grid, average complex responses in overlaps,
  remove duplicate/invalid samples, and omit unmeasured gaps.
- Keep the merge implementation inside fitTF.m. Add fitTF('combine',...) for
  SDF files or decoded F/TF structures and route SDF_DATASETS through it.
  Retain combineTFs as a compatible wrapper; fix its three-argument call.
- Avoid global warning/font changes and fragile internal-axes indexing.
- Replace the legacy GIF collection with three compact MP4 walkthroughs of
  fitting, multi-band SDF joining, and Verify/manual pole-zero refinement.
  Include captions, thumbnail links, and reproducible capture/encoding scripts.
- Show v4.0.1 without truncating the app title; correct About compatibility
  to R2026b+. Keep the default app window size in recordings.
- Add ten joining regression cases, including a real multi-file preview and
  an AAA fit through SDF_DATASETS. Test pole dragging at the default window size.
- Preserve the published v4.0 and v3.0 tags and assets.

## v4.0 — Stable release for MATLAB R2026b+ (11 October 2026)

- Package version 4.0.0; show RIFF v4.0 on the app panel.
- Enable System Identification AAA and N4SID-initialized tfest by default.
  RF Toolbox is optional; retain the explicit RF backend for comparison.
- Embed native Bode charts with zoom, pan, data tips, and responsive sizing.
  Disable the extra figure window by default; retain standalone exports.
- Keep all new runtime behavior in fitTF.m for both GUI and command-line use.
- Add optional interactive pole/zero refinement with linked responses,
  conjugate-aware dragging, constraints, per-trial drafts/reset, and exports.
- Synchronize Verify plots and model parameters, including intermediate trials.
- Fix app startup/refresh with empty folders or a single measurement file.
- Distribute a reproducible .mltbx installer with R2026b as the minimum release,
  shared command-line paths, Apps-gallery registration, and bundled examples.
- Refresh the README, add an editor screenshot, document API/migration, and
  include AAA benchmarks and regression tests. All 51 release regression cases
  passed on MATLAB R2026b (macOS) before packaging.
- Preserve the published v3.0 release for R2023b users. Later MATLAB releases
  are allowed by package metadata; validation was performed on R2026b.

### Development validation history

## 11th Oct 2026 — all new runtime logic in fitTF

- Move Verify, model parameter formatting, and the complete pole/zero editor
  into fitTF.m; remove the separate runtime helper files and editor class.
- Route app Verify through fitTF, preserving selected parameters and trial drafts.
- Expose fitTF('edit',FIT) for command-line editing and the same interactive
  editor with 'Interactive',true. Share root/gain edits, constraints, reset,
  scoring, and workspace/MAT export with the embedded app editor.
- Expose fitTF('verify',FIT,index) and fitTF('parameters',model,label).
- Retain the original utils dependencies; no new helper files are needed.
- Validation: all 47 R2026b cases pass (full suite plus focused editor rerun),
  covering isolated command-line use, standalone editing, app dragging/Verify,
  AAA, and exports.

## 11th Oct 2026 — command-line core and R2026b focus

- Consolidate AAA estimation and backend selection as local functions in fitTF.m.
  Keep the app as a GUI frontend and expose shared estimator defaults through
  fitTF('defaults'), without starting a fit or changing the path/graphics state.
- Default both interfaces to tfest + SysID AAA. Make command-line uncertainty
  estimation opt-in so it no longer silently overrides an AAA selection.
- Target R2026b for the current release. R2023b users should use the earlier
  major release; RF AAA remains an explicit comparison option in the new core.
- Exercise the public fitTF API with vectors, FRD objects, files, weights,
  warm starts, opt-in covariance, and an isolated core without GUI/AAA helpers.
- Validation: 29 R2026b core and plotting integration tests pass, including
  standalone plotting from the isolated core and app fitting/Verify/exports.

## 11th Oct 2026 — System Identification AAA

- Use ssest AAA on R2026a+ with RIFF frequency weights and direct estimation.
  Keep RF rational as an explicit backend and fallback on older releases.
- Default new app sessions to tfest + AAA on R2026a+; retain legacy defaults
  on older releases. RF Toolbox is optional for the modern default selection.
- Respect the requested maximum pole count, including conjugate-pair overshoot.
  Reject failed AAA estimates instead of accepting a dummy transfer function.
- Fix nonconsecutive routine selections, preserve routine IDs in saved results
  and warm starts, and record the AAA backend. Make RF evaluation deterministic.
- Compare 120 estimates on five bundled sweeps with held-out frequencies.
  Keep tfest alongside AAA because neither wins on every measurement.
- Validation: all 34 R2026b regression cases and all 20 applicable R2023b
  cases pass, including app fitting, plotting, manual editing and exports.

## 11th Oct 2026 — manual model refinement

- Turn off the separate figure window by default in the app.
- Fix Verify so the model-parameter tab follows the selected trial, including
  its gain and delay. Index 0 returns to the best fit; retain the fit result
  instead of replacing the app's stored result with an empty array.
- Add a Pole/zero editor with a live Bode comparison, draggable roots, numeric
  root/gain fields, conjugate-pair handling, and optional root constraints.
- Keep manual edits separately for the best fit and each intermediate trial,
  with reset for the selected fit and separate workspace/MAT exports.
- Test real mouse dragging, model updates, trial switching, reset, constraints,
  original-fit preservation, exports, and the default window setting.
- Validate 23 R2026b cases across the full suite and focused follow-up checks,
  including real Fit-to-Verify transitions and removal of stale export metadata.
  All 11 applicable R2023b cases pass; native editing requires R2024b or newer.

## 11th Oct 2026 — interactive app plots

- Embed live Bode charts in the app on R2024b and newer, with MATLAB chart
  interactions. Keep the R2023b image display fallback.
- Use a separate Model parameters tab for scrollable pole/zero, gain, and delay
  values without covering the response curves.
- Keep optional separate windows and FIG/PNG exports; release hidden figures
  created for app exports.
- Add regression coverage for chart updates, zoom limits, resizing, and switching
  between Bode plots and the existing time-domain image display.
- Validation: 13 tests pass on R2026b and all 9 applicable tests pass on R2023b.

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