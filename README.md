# RIFF: Robust IIR Fitting & Filtering

- Description: Generate robust IIR filter models to match the measured transfer functions.

- Developed to aid the design of control & calibration filters at gravitational wave (GW) observatories.

- Useful for time domain subtraction of the noise sources that linearly couple to the GW strain data.

- Input Data: Text-files/Workspace Variables:{F,TF},{FRD Models}/ HP-Agilent-Keysight Spectrum Analyzer Measurements

- To launch the application, open **RIFF.mlapp**

- For command-line use, checkout **fitTF.m**

- Compatibility: MATLAB R2020b+

## Fit a text-file
![Alt text](/tutorials/RIFF-tutorial-1.gif)

## Fit workspace variables 
![Alt text](/tutorials/RIFF-tutorial-2.gif)

## Fit Hp/Agilent/Keysight Spectrum Analyzer Measurements (SDF .DAT Format)
![Alt text](/tutorials/RIFF-tutorial-3.gif)

- To use the BADS optimizer, install it from [BADS-GitHub](https://github.com/lacerbi/bads) and add the folder to the search path.
