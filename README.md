# RIFF: Robust IIR Fitting & Filtering

- **Generate robust IIR Zero-Pole-Gain filter models to match the measured transfer functions.**
            
- **What's New!**

      - Simplied SysID via guided workflow.
      - Improved fitting algorithm 
      - Option to generate MINIMUM_PHASE models without any right-half plane zeros.
      - Option to account for input-output delays 
      - One click install

![Alt text](/tutorials/RIFF_ScreenShot.png)


- **Compatibility**

            -   MATLAB R2022a+
           

- **Other Features**

      - Uses the chosen optimizer to find the best parameters (see below) that maximizes the goodness of fit.
                        - filter order
                        - fitting algorithm
                        - weighting filter 
                        - Frequency limits
                        
      - System identification is done using 
                        - Subspace identification (N4SID)
                        - Vector fitting 
                        - Complex-curve fitting algorithms
                        
      - Calculates the associated uncertainties & the full covariance matrix.

      
      - Options to estimate the noise floor & dampen sharp resonances via smoothing the complex transfer function.

- **To Install** 

            - Click & install using the mlappinstall file 

- **To Launch App** 
              
            - Launch from the Apps toolbar
            - Or type RIFF from the command line


- **Input data format**

      - Text-files (.txt,.csv) 
                  - Valid formats: {f a b}, {w a b}, {f a ib}, {w a ib}, {f a+ib}, {w a+ib}
                  
      - Workspace Variables 
                  - {Frequency,Complex TransferFunction}
                  - {Frequency Response Data (FRD) Model}
                  
      - HP-Agilent-Keysight Spectrum Analyzer measurements
                 - {SDF .DAT files}
                 
      - Input & Output time series and their sampling frequencies
      
      - LISA Technology Package Data Analysis (LTPDA) Analysis Object (AO)

- **Output**

         - FIT_RESULT Structure containing 
                   - Identified ZPK with the associated uncertainties  (FIT_RESULT.ZPK)
                   - Goodness of fit (FIT_RESULT.gof)
                   - Full covariance matrix. (FIT_RESULT.ZPK.parameterCovarianceMatrix)
                   - Results from the intermediate stages (FIT_RESULT.intermediate)
                   - FRD model & filtered transfer functions
                   - Optimization details (FIT_RESULT.options.Optimization)
                   - LIGO FOTON Compatible Second-Order-Section filters (when saved to file)                   



- **For command-line use (+finer control)**

            - use fitTF.m

            
- **Developed to aid** 

      - Design of control & calibration filters at gravitational wave (GW) observatories.
      
      - Design of feedforward & feedback filters for platform stabilization & seismic noise isolation.
      
      - Time domain subtraction of the noise sources that linearly/bi-linearly couple to the GW strain data.
      
      
- Related Publication <br /> &ensp;<br /> &ensp; **Bilinear noise subtraction at the GEO 600 observatory** <br /> &ensp; 
   [*N. Mukund et al.*  &ensp; Phys. Rev. D 101 102006, May 2020](https://doi.org/10.1103/PhysRevD.101.102006)
   


- **License**

     [RIFF](https://github.com/Nikhil-Mukund/RIFF) is released under the terms of the [GNU General Public License v3.0.](https://github.com/Nikhil-Mukund/RIFF/blob/main/LICENSE)

# How to use RIFF WorkFlow

## Fit a text-file measurement 
![Alt text](/tutorials/damped_transmission_FMINCON.gif)

## Improve Fit using Bayesian Adaptive Direct Search 
![Alt text](/tutorials/damped_transmission_BADS.gif)

## Account for possible Input-Output Delay
![Alt text](/tutorials/SysID_with_IOdelay.gif)


## Fit Multiple HP/Agilent/Keysight Spectrum Analyzer Measurements (SDF .DAT Format)
### Use a Minimim Phase Design
![Alt text](/tutorials/Keysight_Multiple_SDF_Files_MinPhase.gif)

## Implement Higher Order Fitting for systems with complex TFs
![Alt text](/tutorials/Higher_Order_Fit.gif)

## Fit workspace variables 
### Note: tutorial was made using an older app version 
![Alt text](/tutorials/RIFF-tutorial-2.gif)

## Filter TimeSeries using the modeled the transfer function
### Note: tutorial was made using an older app version 
![Alt text](/tutorials/RIFF-tutorial-4.gif)




- **Acknowledgements**

     > Evgeny Pr (2021). [INI Config](https://www.mathworks.com/matlabcentral/fileexchange/24992-ini-config), MATLAB Central File Exchange. Retrieved February 12, 2021.
     
     > Acerbi, L. & Ma, W. J. (2017). [Practical Bayesian Optimization for Model Fitting with Bayesian Adaptive Direct Search](https://proceedings.neurips.cc/paper/2017/hash/df0aab058ce179e4f7ab135ed4e641a9-Abstract.html) In Advances in Neural Information Processing Systems 30, pages 1834-1844. [arXiv preprint](https://arxiv.org/abs/1705.04405)
      
    > Martin Hewitson et al. [LTPDA Toolbox V3.0.13](https://www.lisamission.org/ltpda/)
    
    > Justin Dinale (2021). [SDF Importer](https://www.mathworks.com/matlabcentral/fileexchange/67513-sdf-importer), MATLAB Central File Exchange. Retrieved February 12, 2021.
    
- **Notes**     

     > To use the Bayesian Adaptive Direct Search (BADS) optimizer, install it from [BADS-GitHub](https://github.com/lacerbi/bads) and add the folder to MATLAB search path. The app will automatically try to install it from the web, if it's not available.
     
- **Alternatives**

     > [Vectfit MATLAB](https://www.sintef.no/projectweb/vectfit/)
     
     > [Vectfit Python](https://github.com/PhilReinhold/vectfit_python)
     
     > [FDIDENT MATLAB](https://www.mathworks.com/products/connections/product_detail/product_35570.html)
     
     > [IIRrational Python](https://lee-mcculler.docs.ligo.org/iirrational/)
