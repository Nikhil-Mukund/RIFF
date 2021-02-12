# RIFF: Robust IIR Fitting & Filtering

- **Generate robust IIR Zero-Pole-Gain filter models to match the measured transfer functions.**

- Developed to aid 

      - Design of control & calibration filters at gravitational wave (GW) observatories.
      
      - Design of feedforward & feedback filters for platform stabilization & seismic noise isolation.
      
      - Time domain subtraction of the noise sources that linearly/bi-linearly couple to the GW strain data.
      
- Features

      - Uses available optimizers to find the best parameters that maximizes the goodness of fit.
                        - filter order
                        - fitting algorithm
                        - weighting filter 
                        - Frequency limits
                        
      - System identification is done using 
                        - Subspace identification (N4SID)
                        - Vector fitting 
                        - Complex-curve fitting algorithms.
                        
      - Calculates the associated uncertainties & the full covariance matrix.
      
      - Options to estimate the noise floor & dampen sharp resonances via smoothing the complex transfer function.

- Input data format

      - Text-files (.txt,.csv) 
                  - Valid formats: {f a b}, {w a b}, {f a ib}, {w a ib}, {f a+ib}, {w a+ib}
                  
      - Workspace Variables 
                  - {Frequency,Complex TransferFunction}
                  - {Frequency Response Data (FRD) Model}
                  
      - HP-Agilent-Keysight Spectrum Analyzer Measurements
                 - {SDF .DAT files}
                 
      - Input & Output time series and their sampling frequencies
      
      - LISA Technology Package Data Analysis (LTPDA) Analysis Object (AO)

- Output

         - FIT_RESULT Structure containing 
                   - Identified ZPK with the associated uncertainties  (FIT_RESULT.ZPK)
                   - Goodness of fit (FIT_RESULT.gof)
                   - Full covariance matrix. (FIT_RESULT.ZPK.parameterCovarianceMatrix)
                   - Results from the intermediate stages (FIT_RESULT.intermediate)
                   - FRD model & filtered transfer functions
                   - Optimization details (FIT_RESULT.options.Optimization)
                   - LIGO FOTON Compatible Second-Order-Section filters (when saved to file)                   

- To launch the application, open **RIFF.mlapp**

- For command-line use, use **fitTF.m**

- Compatibility: MATLAB R2020b+

- Related Publication: <br /> &ensp; **Bilinear noise subtraction at the GEO 600 observatory** <br /> &ensp; 
   [*N. Mukund et al.* Phys. Rev. D 101 102006, May 2020](https://doi.org/10.1103/PhysRevD.101.102006)

# How to use

## Fit a text-file
![Alt text](/tutorials/RIFF-tutorial-1.gif)

## Fit workspace variables 
![Alt text](/tutorials/RIFF-tutorial-2.gif)

## Fit HP/Agilent/Keysight Spectrum Analyzer Measurements (SDF .DAT Format)
![Alt text](/tutorials/RIFF-tutorial-3.gif)

- To use the Bayesian Adaptive Direct Search (BADS) optimizer, install it from [BADS-GitHub](https://github.com/lacerbi/bads) and add the folder to MATLAB search path.
