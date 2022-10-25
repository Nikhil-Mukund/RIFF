# Latest

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