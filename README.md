# RIFF: Robust IIR Fitting & Filtering

- **Generate robust IIR Zero-Pole-Gain filter models to match the measured transfer functions.**

- Developed to aid 

        - Design of control & calibration filters at gravitational wave (GW) observatories.
        - Design of feedforward & feedback filters for platform stabilization & seismic noise isolation.
        - Time domain subtraction of the noise sources that linearly couple to the GW strain data.

- Input data format

      - Text-files (.txt,.csv) 
                  - Valid formats: {f a b}, {w a b}, {f a ib}, {w a ib}, {f a+ib}, {w a+ib}
                  
      - Workspace Variables: 
                  - {Frequency,TransferFunction}
                  - {Frequency Response Data (FRD) Model}
                  
      - HP-Agilent-Keysight Spectrum Analyzer Measurements
                 - {SDF .DAT files}

- To launch the application, open **RIFF.mlapp**

- For command-line use, use **fitTF.m**

- Compatibility: MATLAB R2020b+

- Related Publication: <br /> &ensp; **Bilinear noise subtraction at the GEO 600 observatory** <br /> &ensp; 
   [Phys. Rev. D 101 102006](https://doi.org/10.1103/PhysRevD.101.102006)

# How to use

## Fit a text-file
![Alt text](/tutorials/RIFF-tutorial-1.gif)

## Fit workspace variables 
![Alt text](/tutorials/RIFF-tutorial-2.gif)

## Fit Hp/Agilent/Keysight Spectrum Analyzer Measurements (SDF .DAT Format)
![Alt text](/tutorials/RIFF-tutorial-3.gif)

- To use the Bayesian Adaptive Direct Search (BADS) optimizer, install it from [BADS-GitHub](https://github.com/lacerbi/bads) and add the folder to MATLAB search path.
