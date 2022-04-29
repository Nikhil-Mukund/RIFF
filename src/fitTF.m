%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% fitTF.m
%
% DESCRIPTION: Fits a stable transfer function to match the measured
% response. Accepts inputs in multiple format (see below). Makes use of
% optimization techniques to find the best suited fitting routine, filter order and
% weighting filter. Best fit model is the one which has the lowest
% normalized root mean square error with respect to the measured response.
% Specifying the primary parameters in general results in better fit.
% Do check the examples and the description provided below for more details.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUTS: (any order) [Provide parameter name in quotes, followed by the variable value]
%                     OR provide cofiguration file
%                     Order of precedence:
%                       "Params in Quotes" > "Config File Params" > "Default Params"
%
%
%    [FORMAT 1]
%        "F"  :frequency in Hz
%        "TF" :measured transfer function (a+ib form)
%
%    [FORMAT 2]
%        "FNAME"  :File to be used for fitting (.csv, .txt, .dat)
%        "FORMAT" :[ Default = 'w a ib'] Options: 'w a ib','w a+ib','w a b',
%        'f a ib', 'f a+ib', 'f a b' and similarly comma seperated like
%        'w,a,ib'....
%                  where w (or f) is frequency in rad/s (or Hz)
%                       a & b are the real and imaginary parts of the transfer function
%
%    [FORMAT 3]
%        "FRD"  : Frequency Response Data model with frequency unit in rad/s
%
%    [FORMAT 4]
%        "AO"  : Transfer Function using LTPDA Analysis Object (AO) format
%
%    [FORMAT 5]
%        "TS1" : Input Time Series Data
%        "TS2" : Output Time Series Data
%        "FS1" : TS1 Sampling rate
%        "FS2" : TS2 Sampling rate
%     (specify bandwidth via "BW". See  additional arguments.)
%
%    [FORMAT 6]
%        "SDF_DATASETS" : HP/Agilent/Keysight SDF .DAT files as a cell/string array
%         (also specify the final "SDF_DATASET_FREQ_RESO". See  additional arguments.)
%
%    [PRIMARY PARAMETERS FOR IMPROVED FITTING]
%       "F_INITIAL"     [ Default = min(ff)     ] Starting Freq. for fitting
%       "F_FINAL"       [ Default = max(ff)     ] Ending Freq. for fitting
%       "OPTIMIZER"   [ Default = 'SURROGATE'] Optimizer to use (Options: 'SURROGATE','PATTERSEARCH', 'FMINCON' )
%       "SMOOTH_LEVEL"  [ Default = 0           ] Smooth the frequenc response [options: 0-6]
%       "NUM_TRIALS"    [Default  = 10          ] Number of trials with different initializations
%       "CUSTOM_WEIGHT" [ Default = NIL         ] Either provide a Weight vector like Coherence info (same size as freq.) or give string arguments such as 'f>320, f<340' (separated by comma)
%       "USE_PARALLEL"  [ Default = 0           ] Use Parallel Pool for optimization speedup
%       "ATTAIN_GOF"    [ Default = 0           ] Set this to 1 to attan a desired GOF (set MAX_POLES to a low value (say 2) with higher NUM_TRIALS )
%       "DESIRED_GOF"   [ Default = 50          ] Desired goodness of fit (in %), activated when ATTAIN_GOF = 1
%  "POLE_UPDATE_TRIAL"  [     Default = 5       ] Increase MAX_POLE every Nth Trial (Used when ATTAIN_GOF = 1 )
%     "FIT_NOISE_FLOOR" [     Default = 0       ] Fit transfer function noise floor
%        "ROUTINE"      [ Default =  1:3        ] Fit Routine:  1="rationalfit", 2="tfest", 3="invfreqs
%  "DESIRED_MODEL_ORDER"[ Default = []          ] Request desired model order
%  "ENFORCE_STABILITY"  [ Default = 1           ] Enforce poles to be on the left half plane
% "ESTIMATE_UNCERTAINITY" [ Default = 0         ] Determine uncertainity on esimated parameters
% "INCLUDE_IODELAY"     [ Default = 0           ] Account for possible Input-Output Delay during SysID
%
%    [PLOTTING & SAVING PARAMETERS]
%       "PLOT_TOGGLE"   [ Default = 1           ] Enable Bode Plotting
%   "INTERMEDIATE_PLOT" [Default  = 0           ] Create intermediate plots
%       "DISPLAY_ZPK"   [Default =  0           ] Display ZPK parameters while plotting.
%       "SAVE_TOGGLE"   [ Default = 0;          ] Save results
%       "SAVEAS"        [ Default = datetime    ] Ouput folder name
%       "SAVETO"        [ Default = "./Saved_Models"] Ouput folder path
%
%
%    [OTHER PARAMETERS]
%       "MIN_POLES"     [ Default = 6;          ] Min Poles to use
%       "MAX_POLES"     [ Default = 18;         ] Max Poles to use
%       "FUNC_EVAL"     [ Default = 100;        ] Number of surrogate function evaluations
%       "GUESS"         [ Default = NIL         ] Pass results from the previous run,  FIT.Options.Optimization.results
%       "FREQ_WIN_LOW"  [ Default = 3;         ] Freq. width to search across Fmin
%       "FREQ_WIN_UP"   [ Default = 3;         ] Freq. width to search across Fmax
%       "FOTON_FS"      [ Default = 65536      ] FOTON Sampling Freq. (Only relevant for GW Detectors)
%       "FS1"           [ Default = 16384       ] % Time Series Sampling frequency
%     "DAMP_RESONANCES" [ Default = 1           ] Enable damping of unphysical resonances
%       "RESO_DAMP_FAC" [ Default = 100         ] Damp unphysical resonances by this factor
%      "TS_SCHEME"      [ Default = "tfestimate"] Method to estimate tf from time series.  Options: 'tfestimate' or 'tfe2' written by Brian Lantz (Stanford)
%       "BW"            [ Default = 0.1         ] Bandwidth needed for TF estimation from timeseries inputs (for TS_SCHEME = 1)
%       "ALPHA"         [ Default = 4           ] (fup/f)^ALPHA: Power law suppression for frequencies outside band of interest
%       "PZTOL"         [ Default = 1e-4        ] Delete zeros & poles at are closer to each other than PZTOL value
%       "NFE_BW"        [ Default = 16          ] BandWidth (Hz) for noise floor estimate
%       "NFE_OL"        [ Default = 0.8         ] Outlier threshold (0-1) for noise floor estimate
%       "BODEOPTIONS"   [Default = bodeoptions  ] Options for constructing bode plots
%       "EXTRA_INFO"    [ Default = NIL         ] Pass additional useful info as a structure. Example: measured coherence
% "OPTIMIZER_DISPLAY_LEVEL" [Default = 'off'    ] Options {'none','off','iter','final'}
%       "READ_CONFIG"   [ Default = 0           ]    Read configuration file
%       "CONFIG_FILE"   [ Default = 'fitTF_config.ini']  Configuration file name
% "SDF_DATASET_FREQ_RESO"[ Default = 0.1        ] Final freq. reso for the combined HP/Agilent/Keysight SDF files
%
% OUTPUT:
%       FIT: Structure containing the results of fitting routine (ZPK model,Measured & modeled reponses, goodness of fit, Optimization details...etc)
%
%       Note:
%       Call without any output will display the FIT results within the
%       command line. This include ZPK, related uncertainities & the
%       overall goodness of fit (%).
%
% EXAMPLE:
%
% (1) Using frequency & complex response
%
%      FIT =  fitTF('F',f,'TF');
%      FIT =  fitTF('F',f,'TF',TF,'F_INITIAL',305,'F_FINAL',335,'MAX_POLES',18,'FUNC_EVAL',200,'USE_PARALLEL',0,'OPTIMIZER','SURROGATE','SMOOTH_LEVEL',1,'SAVE_TOGGLE',1);
%
% (2) Using measurement datafiles
%
%      FIT =  fitTF('FNAME','./measured_response.csv','FORMAT','w a ib');
%      FIT =  fitTF('FNAME','./measured_response.csv','FORMAT','w a ib','F_INITIAL',0.1,'F_FINAL',1.2,'MAX_POLES',20,'FUNC_EVAL',100,'USE_PARALLEL',1,'OPTIMIZER','SURROGATE','SMOOTH_LEVEL',0,'SAVE_TOGGLE',0);
%
%      FIT =  fitTF('FNAME',"./measured_TFs/sample_TF.txt");
%      FIT =  fitTF('FNAME',"./measured_TFs/sample_TF.txt","FORMAT","f,a,b","FUNC_EVAL",100,"F_FINAL",7,"F_INITIAL",5e-2,'SMOOTH_LEVEL',3,"OPTIMIZER","FMINCON","MAX_POLES",18,'CUSTOM_WEIGHT',"f > 1,f < 5 ");
%
% (3) Using frequency response data (FRD) object
%
%      FIT =  fitTF('FRD',FRD_MODEL,'F_INITIAL',0.1,'F_FINAL',8);
%      FIT =  fitTF('FRD',FRD_MODEL,'F_INITIAL',0.1,'F_FINAL',8,'MAX_POLES',20,'FUNC_EVAL',10,'USE_PARALLEL',1,'OPTIMIZER','SURROGATE','SMOOTH_LEVEL',3,'SAVE_TOGGLE',1,'SAVEAS','Sample_TF3');
%
% (4) Using LTPDA Analysis Object
%
%      FIT =  fitTF("AO",LTPDA_AO);
%
% (5) Using input & output time series
%
%      FIT =  fitTF("TS1",x,"TS2",y,'FS1',16384,'FS2',256,"BW",0.1,'F_FINAL',5);
%
% (6) Estimate uncertainity & Display ZPK within the plot
%      FIT = fitTF('FRD',FRD,'F_INITIAL',0.1,'F_FINAL',9e3,'OPTIMIZER','FMINCON','NUM_TRIALS',10,'INTERMEDIATE_PLOT',1,'PZTOL',1e-4,'MAX_POLES',2,'ESTIMATE_UNCERTAINITY',1,'DISPLAY_ZPK',1);
%
% (7) Attain a desired level of goodness-of-fit
%     FIT = fitTF('FRD',FRD,'F_INITIAL',0.1,'F_FINAL',9e3,'OPTIMIZER','FMINCON','NUM_TRIALS',20,'INTERMEDIATE_PLOT',1,'PZTOL',1e-4,'MAX_POLES',1,'ESTIMATE_UNCERTAINITY',1,'DISPLAY_ZPK',1,'ATTAIN_GOF',1,'DESIRED_GOF',60);
%
% (8) Reduce FIT to the desired model order
%     FIT = fitTF('FRD',FRD,'INTERMEDIATE_PLOT',1,'OPTIMIZER','FMINCON','NUM_TRIALS',5,'F_INITIAL',1e-2,'F_FINAL',8e3,'MAX_POLES',5, "DESIRED_MODEL_ORDER",1);
%
% (9) Provide parameter values using config file
%     FIT = fitTF('READ_CONFIG',1,'CONFIG_FILE','fitTF_config.ini','FRD',FRD)
%
% AUTHOR:
%       Nikhil Mukund (AEI Hannover)
%       nikhil.mukund@aei.mpg.de
%
% LAST MODIFIED:
%      6th May 2019: Initial Commit
%      1st June 2019: Modifed "CUSTOM_WEIGHT"
%      2nd June 2019: Now auto damps unphysical resonances
%      6th June 2019: Now fits time series data
%     20th June 2019: Multiple trials with different initializations
%     24th Sep 2019:  Model order reduction
%     21th Oct 2019, Added invfreqs method
%     22th Oct 2019, Modified residual (now includes cohWeight)
%     22th Oct 2019, Added iterative GUESSing
%     25th Oct 2019, modified make_plot function (now also displays previous best result)
%     14th May 2020:  Enforce Uncertainity Estimation (+plot ZPK values).
%     19th May 2020:  Attain a desired level of goodness-of-fit.
%     27th June 2020: Add Noise Floor Estimation
%     14th July 2020: Added option to provide bodeoptions
%     15th July 2020: Added minreal to provide model order reduction
%                     Options to specify desired model order reduction
%     7th Aug 2020:  Option to read from configuration file.
%    17th Aug 2020: Major Update:
%                       -Better model order reduction (constrained wrt GOF)
%                       -Plotting improved
%    29th Oct 2020:  Auto-Decrease the number of freq samples to 1000 samples
%    23rd Feb 2021:  Added-> Fill missing values (NaNs) in processed TF  with interpolated values
%
%    28th Apr 2022:  -> Added minimum-phase state-space model fitting using log-Chebyshev magnitude design
%                    -> Supports possible SysID with IODelay 
% COMPATIBILITY: MATLAB R2018b+
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TO DO:
%   -RELAX STABILITY CRITERION (Currently stability is enforced)
%                 - RHS poles from ENFORCE_STABILITY=0 is currenlty ignored.
%   -REMOVE PZTOL: No londer used for model order redution
%   -Toggle to separately control fit percentage wrt mag and/or phase.
%   -Add option to specify the number of freq samples used in FRD interp (1e3)
%   -This line sometimes throws an error >> VALUE = getcov(modelSYS,'FACTORS','free');
%   -Check IODelay behavior when ESTIMATE_UNCERTAINITY &DESIRED_MODEL_ORDER flags are ON
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[FIT] =  fitTF(varargin)

tic;
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('Starting transfer function estimation...')

format long g

% add path
try addpath('./utils');catch;end

if isempty(varargin)
    disp('No input arguments provided, check the description given below...')
    eval('help fitTF.m')
    return
end

% Declare persistent variables
clear cohWeight NUM_ZEROS
persistent cohWeight NUM_ZEROS

% Default Parameters
PLOT_TOGGLE  = 1;       % Enable Bode Plotting
SAVE_TOGGLE  = 0;       % Save results
USE_PARALLEL  = false;   % Use Parallel Pool for Surrogate Optimization
MIN_POLES    = 1;       % Min Poles to use
MAX_POLES    = 18;      % Max Poles to use
FREQ_WIN_LOW  = 3;     % Freq. width to search across Fmin
FREQ_WIN_UP   = 3;     % Freq. width to search across Fmax
FUNC_EVAL    =  20;    % Number of surrogate function evaluations
OPTIMIZER    = 'FMINCON'; % Optimizer to use (Options: 'SURROGATE','PATTERSEARCH','FMINCON' )
SMOOTH_LEVEL = 0;         % Smooth the frequency response
FOTON_FS     = 65536;     % Sampling frequency for the foton filter
FS1          = 16384;     % Time Series Sampling frequency
BW           = 0.1;       % Bandwidth needed for TF estimation (for timeseries inputs)
DAMP_RESONANCES = 1;     % Enable damping of unphysical resonances
SAVETO        = "./Saved_Models" ; % Output folder path
TS_SCHEME     = "tfestimate";        % Method to estimate tf from time series
RESO_DAMP_FAC = 100;      % Damp unphysical resonances by this this factor
NUM_TRIALS    = 10;       % Number of trials with different initializations
ALPHA        = 4;         %  (fcorner/f)^ALPHA: Power law suppression for frequencies outside band of interest
INTERMEDIATE_PLOT = 0;    % Make intermediate bode plots
PZTOL          = sqrt(eps);    % Delete zeros & poles at are closer to each other than the PZTOL value
ROUTINE        = 1:2;     % Fit Routine:  1="rationalfit", 2="invfreqs", 3="tfest"
ESTIMATE_UNCERTAINITY = 1; % Estimate uncertainity associated with the ZPK parameters.
INCLUDE_IODELAY = 0;       % Account for possible Input-Output Delay during SysID
DISPLAY_ZPK = 1 ;          % Display ZPK parameters while plotting.
ATTAIN_GOF  = 0 ;         % Set this to 1 to attan a desired GOF (set MAX_POLES to a low value with higher NUM_TRIALS )
DESIRED_GOF = 90;         % Desired goodness of fit (in %) ( used when ATTAIN_GOF = 1 )
POLE_UPDATE_TRIAL = 5;    % Increase MAX_POLE every Nth Trial (Used when ATTAIN_GOF = 1 )
FIT_NOISE_FLOOR   = 0;    % Fit TF noise floor (also check NFE_PARAMS)
NFE_BW       = 16;        % Noise floor bandwidth (Hz)
NFE_OL       = 0.8;       % Noise floor outlier threhold (0-1)
DESIRED_MODEL_ORDER = [] ; % Reduce model to this order using BALRED function
% Configuration file Params
READ_CONFIG = 0;    % Read configuration file
CONFIG_FILE = 'fitTF_config.ini'; % Configuration file name
ENFORCE_STABILITY = 1; % Enforce poles to be on the left half plane
INTERP_FRD   = 1;      % Auto-Decrease the number of samples to 1000 samples
ENFORCE_MINIMUM_PHASE = 0; % Prevents Right-Half Plane Zeros
SMOOTH_WIN_LEN = 100;% Moving Mean Window length (only used when SMOOTH_LEVEL==7)
INTERP_FRD_THRESH = 1e4; % Downsample FRD if samples higher than this value
FIT_WEIGHT_FROM_PHASE_SMOOTHNESS = 0; % 

% Other Default Params
WtMin = 1;
WtMax = 4;
F_INITIAL_toggle = 0;
F_FINAL_toggle = 0;
EXTRA_INFO = [];
OPTIMIZER_DISPLAY_LEVEL = 'off';
% for use with MATLAB TFestimate APP
APP  = struct();
MATLAB_APP_TOGGLE = 0;
FIG_HANDLE_VISIBILITY = 1; % Display FIGURE
INPUT_DATA_FORMAT = 'TextFile';%
EXPORT_TO_WORKSPACE = 0; % export fitTF result from APP to workspace
EXPORT_VARIABLE_NAME = 'FIT_RESULT'; % export fitTF from APP result to workspace
PREVIEW_BODEPLOT_TOGGLE=0; % Used to preview bodeplot from the App
SDF_DATASET_FREQ_RESO = 0.1; % Used to determine the final SDF interpolation freq reso
%--------------------------------------------------------------------------

% [FIGURE HANDLE OPTIONS]
clear FIG_HANDLE;
% persistent FIG_GCF
FIG_HANDLE.NAME    = 'System Identification';
FIG_HANDLE.UNITS = 'Normalized';
FIG_HANDLE.OUTERPOSITION = [0.04, 0.04, 0.9, 0.9];
FIG_HANDLE.PAPERORIENTATION = 'PORTRAIT';  %  PORTRAIT or LANDSCAPE
% FIG_GCF = figure(FIG_HANDLE,'Visible','off');







% Default Bode Parameters
BO = bodeoptions;
BO.FreqUnits='Hz';
BO.PhaseWrapping='on';
BO.PhaseMatching='off';
BO.Grid = 'on';

% Check for User provided CONFIGURATION FILE
for k= 1:2:length(varargin)
    switch (varargin{k})
        case {'READ_CONFIG'}
            READ_CONFIG =  varargin{k+1};
        case {'CONFIG_FILE'}
            CONFIG_FILE =  varargin{k+1};
    end
end
% Read from config file
if READ_CONFIG == 1
    if ~exist('IniConfig.m','file')
        fprintf('IniConfig.m is needed to parse the configuration file.\n')
        fprintf('Download it from https://www.mathworks.com/matlabcentral/fileexchange/24992-ini-config \n')
        fprintf('Proceeding with default parameter values... \n')
    else
        fprintf('Reading from configration file... \n')
        ini = IniConfig();
        ini.ReadFile(CONFIG_FILE);
        sections = ini.GetSections();
        [config_keys, ~] = ini.GetKeys(sections{1});
        config_values = ini.GetValues(sections{1}, config_keys);
        isNumeric = cellfun(@(x)isnumeric(x),config_values);
        for ijk = 1:numel(isNumeric)
            if isNumeric(ijk)==1
                sprintf('%s = %s',config_keys{ijk},num2str(config_values{ijk}));
                evalc(sprintf('%s = %s',config_keys{ijk},num2str(config_values{ijk})));
            else
                evalc(sprintf('%s = %s',config_keys{ijk}, config_values{ijk} ));
            end
        end
    end
    
end

% Check for User provided parameters
for k= 1:2:length(varargin)
    switch (varargin{k})
        case {'FNAME'}
            FNAME = varargin{k+1};
        case {'FORMAT'}
            FORMAT = varargin{k+1};
        case {'F'}
            f = varargin{k+1};
        case {'TF'}
            TF = varargin{k+1};
        case {'FRD'}
            FRD = varargin{k+1};
        case {'SDF_DATASETS'}
            SDF_DATASETS = varargin{k+1};
        case {'AO'}
            AO = varargin{k+1};
        case {'TS1'}
            TS1 = varargin{k+1};
        case {'TS2'}
            TS2 = varargin{k+1};
        case {'FS1'}
            FS1 = double(varargin{k+1});
        case {'FS2'}
            FS2 = double(varargin{k+1});
        case {'BW'}
            BW = double(varargin{k+1});
        case {'INTERP_FRD'}
            INTERP_FRD = double(varargin{k+1});
        case {'SDF_DATASET_FREQ_RESO'}
            SDF_DATASET_FREQ_RESO = double(varargin{k+1});
        case {'PLOT_TOGGLE'}
            PLOT_TOGGLE = varargin{k+1};
        case {'SAVE_TOGGLE'}
            SAVE_TOGGLE = varargin{k+1};
        case {'F_INITIAL'}
            F_INITIAL = double(varargin{k+1});
            F_INITIAL_toggle = 1;
        case {'F_FINAL'}
            F_FINAL = double(varargin{k+1});
            F_FINAL_toggle = 1;
        case {'MIN_POLES'}
            MIN_POLES = double(varargin{k+1});
        case {'MAX_POLES'}
            MAX_POLES = double(varargin{k+1});
        case {'NUM_ZEROS'}
            NUM_ZEROS = double(varargin{k+1});
        case {'FREQ_WIN_LOW'}
            FREQ_WIN_LOW = double(varargin{k+1});
        case {'FREQ_WIN_UP'}
            FREQ_WIN_UP = double(varargin{k+1});
        case {'FUNC_EVAL'}
            FUNC_EVAL = double(varargin{k+1});
        case {'USE_PARALLEL'}
            USE_PARALLEL = varargin{k+1};
        case {'ENFORCE_MINIMUM_PHASE'}
            ENFORCE_MINIMUM_PHASE = varargin{k+1};            
        case {'OPTIMIZER'}
            OPTIMIZER = upper(varargin{k+1});
        case {'SMOOTH_LEVEL'}
            SMOOTH_LEVEL = double(varargin{k+1});
        case {'SAVEAS'}
            SAVEAS = varargin{k+1};
            SAVE_TOGGLE = 1; % Auto Set SAVE_TOGGLE to 1
        case {'SAVETO'}
            SAVETO = string(varargin{k+1});
        case {'GUESS'}
            GUESS = varargin{k+1};
        case {'DAMP_RESONANCES'}
            DAMP_RESONANCES = varargin{k+1};
        case {'FOTON_FS'}
            FOTON_FS = varargin{k+1};
        case {'TS_SCHEME'}
            TS_SCHEME = lower(string(varargin{k+1}));
        case {'PZTOL'}
            PZTOL = varargin{k+1};
        case {'BODEOPTIONS'}
            BO = varargin{k+1};
        case {lower('ROUTINE')}
            ROUTINE = varargin{k+1};
        case {'ALPHA'}
            ALPHA = varargin{k+1};
        case {'RESO_DAMP_FAC'}
            RESO_DAMP_FAC = varargin{k+1};
        case {'NUM_TRIALS'}
            NUM_TRIALS = round(varargin{k+1});
        case {'INTERMEDIATE_PLOT'}
            INTERMEDIATE_PLOT = round(varargin{k+1});
        case {'ESTIMATE_UNCERTAINITY'}
            ESTIMATE_UNCERTAINITY = round(varargin{k+1});
        case {'DISPLAY_ZPK'}
            DISPLAY_ZPK = round(varargin{k+1});
        case {'ENFORCE_STABILITY'}
            ENFORCE_STABILITY = round(varargin{k+1});
        case {'OPTIMIZER_DISPLAY_LEVEL'}
            OPTIMIZER_DISPLAY_LEVEL = varargin{k+1};
        case {'ATTAIN_GOF'}
            ATTAIN_GOF =  varargin{k+1};
        case {'FIT_NOISE_FLOOR'}
            FIT_NOISE_FLOOR =  varargin{k+1};
        case {'NFE_BW'}
            NFE_BW =  varargin{k+1};
        case {'NFE_OL'}
            NFE_OL =  varargin{k+1};
        case {'DESIRED_GOF'}
            DESIRED_GOF = varargin{k+1};
        case {'POLE_UPDATE_TRIAL'}
            POLE_UPDATE_TRIAL = varargin{k+1};
        case {'APP'}
            APP = varargin{k+1};
            MATLAB_APP_TOGGLE = 1;
        case {'FIG_HANDLE_VISIBILITY'}
            FIG_HANDLE_VISIBILITY = varargin{k+1};
        case {'EXPORT_TO_WORKSPACE'}
            EXPORT_TO_WORKSPACE = varargin{k+1};
        case {'EXPORT_VARIABLE_NAME'}
            EXPORT_VARIABLE_NAME = varargin{k+1};
        case {'INPUT_DATA_FORMAT'}
            INPUT_DATA_FORMAT = varargin{k+1};
        case {'PREVIEW_BODEPLOT_TOGGLE'}
            PREVIEW_BODEPLOT_TOGGLE = varargin{k+1};
        case {'CUSTOM_WEIGHT'}
            disp('Using user specified weighting function...')
            if ~(ischar(varargin{k+1}) || isstring(varargin{k+1}))
                cohWeight = abs(varargin{k+1});
            else
                VIDX  = k+1;
            end
            WtMax = 5;
            WtMin = 5;
        case {lower('EXTRA_INFO')}
            EXTRA_INFO = varargin{k+1};
        case {'DESIRED_MODEL_ORDER'}
            DESIRED_MODEL_ORDER = double(varargin{k+1});
            ROUTINE  = 1:2;
        case {'INCLUDE_IODELAY'}   
            INCLUDE_IODELAY = varargin{k+1};
    end
end

% Load variables set using the MATLAB APP to fitTF.m workspace
% Compatibility 2020b+
if MATLAB_APP_TOGGLE == 1
    fprintf('Loading variables set using the MATLAB APP \n')
    FIELDS = fields(APP);
    % Loop and evaluate
    if ~isempty(FIELDS)
        for ijk = 1:numel(FIELDS)
            % USE NUMERIC/TEXT VALUE FROM APP
            if contains(class(APP.(FIELDS{ijk})),'EditField')
                if ~contains(FIELDS{ijk},'Label')
                    feval(@()assignin('caller', extractBefore(FIELDS{ijk},{'Edit'}),APP.(FIELDS{ijk}).Value));
                end
                %             % USE NUMERIC/TEXT VALUE FROM TextArea
                %             elseif contains(class(APP.(FIELDS{ijk})),'TextArea')
                %                 if ~contains(FIELDS{ijk},'Label')
                %                     feval(@()assignin('caller', extractBefore(FIELDS{ijk},{'TextArea'}),APP.(FIELDS{ijk}).Value{1}));
                %                 end
                
                % USE CheckBox VALUE FROM APP
            elseif contains(class(APP.(FIELDS{ijk})),'CheckBox')
                if ~contains(FIELDS{ijk},'Label')
                    feval(@()assignin('caller', extractBefore(FIELDS{ijk},{'CheckBox'}),APP.(FIELDS{ijk}).Value));
                end
                % USE DropDown VALUE FROM APP
            elseif contains(class(APP.(FIELDS{ijk})),'DropDown')
                if ~contains(FIELDS{ijk},'Label')
                    feval(@()assignin('caller', extractBefore(FIELDS{ijk},{'DropDown'}),APP.(FIELDS{ijk}).Value));
                end
                % USE Slider VALUE FROM APP
            elseif contains(class(APP.(FIELDS{ijk})),'Slider')
                if ~contains(FIELDS{ijk},'Label')
                    feval(@()assignin('caller', extractBefore(FIELDS{ijk},{'Slider'}),APP.(FIELDS{ijk}).Value));
                end
            end
        end
    end
end



if MATLAB_APP_TOGGLE == 1
    FIG_TEMP = figure('Renderer', 'painters', 'Position', [0 0 0.1 0.1]);
end

FIG_HANDLE_VISIBILITY_ORIG = FIG_HANDLE_VISIBILITY;

% Check if Surrogate Optimizer exists (require R2018b & above)
% Else switch to patternsearch or fmincon
if exist('surrogateopt','file') ~= 2
    disp('Surrogate Optimizer does not exist (require R2018b & above)');
    disp('Switching to PatterSearch optimizer')
    if exist('patternsearch','file') == 2
        OPTIMIZER  = 'PATTERNSEARCH';
    else
        disp('Pattern Search Optimizer does not exist (requires global optimization toolbox');
        disp('Switching to FMINCON optimizer')
        if exist('fmincon','file') == 2
            OPTIMIZER  = 'FMINCON';
        else
            disp('FMINCON Search Optimizer does not exist (requires optimization toolbox');
            disp('Exiting...')
            return
        end
    end
    
end


% Read file
if exist('FNAME','var')
    disp('Attempting to read file...')
    FILE = readtable(FNAME,'ReadVariableNames',0);
    
    
    
    % Get Frequency & TF from the loaded file by checking the format
    if exist('FORMAT','var')
        if strcmpi(FORMAT,'f a+ib') || strcmpi(FORMAT,'f,a+ib')
            f = FILE.Var1;
            TF = FILE.Var2;
        elseif strcmpi(FORMAT,'w a+ib') || strcmpi(FORMAT,'w,a+ib')
            f = FILE.Var1/2/pi;
            TF = FILE.Var2;
        elseif strcmpi(FORMAT,'f a b') || strcmpi(FORMAT,'f,a,b')
            f = FILE.Var1;
            TF = FILE.Var2 + 1i*FILE.Var3;
        elseif strcmpi(FORMAT,'w a b') || strcmpi(FORMAT,'w,a,b')
            f = FILE.Var1/2/pi;
            TF = FILE.Var2 + 1i*FILE.Var3;
        elseif strcmpi(FORMAT,'f a ib') || strcmpi(FORMAT,'f,a,ib')
            f = FILE.Var1;
            TF = FILE.Var2 + FILE.Var3;
        elseif strcmpi(FORMAT,'w a ib') || strcmpi(FORMAT,'w,a,ib')
            f = FILE.Var1/2/pi;
            TF = FILE.Var2 + FILE.Var3;
        end
    else
        disp("No file 'FORMAT' provided.")
        try
            disp("Specify: 'w a ib','w a+ib','w a b','f a ib', 'f a+ib', 'f a b' ")
            disp("Assuming 'FORMAT' as 'w a ib'  ")
            f = FILE.Var1/2/pi;
            TF = FILE.Var2 + 1i*FILE.Var3;
        catch exception
            disp(getReport(exception))
            disp("Assuming 'w a+ib' format ")
            f = FILE.Var1/2/pi;
            TF = FILE.Var2;
        end
    end
    
    
    % to prevent errors arising from f(1)==0
    if f(1)==0
        fprintf('Zeroth frequency term removed to prevent unexpected behavior.\n')
        f(1) = [];
        TF(1)= [];
    end
end

if exist('FRD','var')
    disp('Analysing FRD model...')
    [MM,PP,WW] = bode(FRD);
    f      = squeeze(WW)/2/pi;
    MAG      = squeeze(MM);
    PHS      = squeeze(PP);
    TF       = MAG.*exp(1i*PHS*pi/180);
end

if exist('SDF_DATASETS','var')
    disp('Analysing HP/Agilent/KeySight SDF .DAT files...')
    [TF,f,~,~,~] = combineTFs(SDF_DATASETS,SDF_DATASET_FREQ_RESO,BO,0);
end

if exist('AO','var')
    disp('Analysing Analysis Object (AO)...')
    f = AO.data.x;
    TF = AO.data.y;
end

if exist('TS1','var') && exist('TS2','var')
    if ~exist('FS2','var') && exist('FS1','var')
        FS2 = FS1;
    end
    % Match sampling rates
    [TS1,TS2,FS] = vectorMatch(TS1,FS1,TS2,FS2);
    
    % Do some checks on BW & NFFT
    NFFT = FS/BW;
    if ~exist('BW','var')
        NFFT = min(FS,numel(TS1));
    end
    if numel(TS1) < FS
        NFFT = numel(TS1);
    end
    if NFFT > numel(TS1)
        NFFT = numel(TS1);
    end
    
    
    
    % Get Transfer Function
    disp('Estimating transfer function from time series data...')
    if strcmp(TS_SCHEME, "tfestimate")
         
    
        [TF,f] = tfestimate(TS1,TS2,hanning(NFFT),NFFT/2,NFFT,FS);
        disp('Estimating magnitude squared coherence...')
        [cohWeight] = mscohere(TS1,TS2,hanning(NFFT),NFFT/2,NFFT,FS);
    
    end
    
    
end


% Convert to Single Column
f = f(:);
TF = TF(:);

% Create a copy of the original
TF_orig = TF;
f_orig  = f;




% Stress on user specific freq. regions
if exist('VIDX','var')
    fprintf('Modifying weighting, making use of input argument %d ...\n',VIDX);
    coh_str = varargin{VIDX};
    coh_cell = strsplit(coh_str,',');
    cohWeight = ones(size(f));
    for ijk = 1:numel(coh_cell)
        cohWeight = cohWeight.*eval(coh_cell{ijk});
    end
end


if F_INITIAL_toggle ~= 1
    F_INITIAL = f(2);
end

if F_FINAL_toggle ~= 1
    F_FINAL = f(end);
end


% Auto-Decrease the number of samples to 1000 samples
if INTERP_FRD
    % Only decrease if freq span > 100 Hz.
    if (F_FINAL - F_INITIAL) > 100
        if numel(f) > INTERP_FRD_THRESH
        fprintf('Auto-Decreasing the number of samples to 1000 samples from %d samples\n',numel(f))
        FRD_temp = frd(TF,2*pi*f);
        freq_rs = logspace(log10(min(f+eps)),log10(max(f)),1000);
        FRD_temp_rs = interp(FRD_temp,2*pi*freq_rs);
        TF = squeeze(FRD_temp_rs.ResponseData);
        f = freq_rs(:);
        else
           fprintf('Freq samples: %d. INTERP_FRD sample threshold: %d\n',numel(f),INTERP_FRD_THRESH)
        end
    end
end

% Do some sanity checks
if F_INITIAL > F_FINAL
    disp('F_INITIAL > F_FINAL, Swapping values')
    [F_FINAL , F_INITIAL] = deal(F_INITIAL,F_FINAL);
elseif F_INITIAL == F_FINAL
    disp('F_INITIAL = F_FINAL, Doubling F_FINAL ')
    F_FINAL = 2*F_FINAL;
end




% Set Freq bound for  Optimizer
if F_INITIAL < FREQ_WIN_LOW
    FREQ_WIN_LOW = F_INITIAL/4;
end

if F_FINAL <= FREQ_WIN_UP
    FREQ_WIN_UP = F_FINAL/4;
end

while F_INITIAL + FREQ_WIN_LOW >= F_FINAL - FREQ_WIN_UP
    FREQ_WIN_LOW = FREQ_WIN_LOW/4;
    FREQ_WIN_UP = FREQ_WIN_UP/2;
end

% Currently only tfestimate can estimate uncertainity
if ESTIMATE_UNCERTAINITY == 1
    fprintf('Uncertainity estimation requested. FIT_ROUTINE set to tfestimate. \n')
    ROUTINE(1)  = 2;
    ROUTINE(end) = 2;
end


% Currently only tfestimate include un-stable models
if ENFORCE_STABILITY ~= 1
    fprintf('ENFORCE_STABILITY set to 0. FIT_ROUTINE set to tfestimate. \n')
    ROUTINE(1)  = 2;
    ROUTINE(end) = 2;
end

% Added by NM on 28th April 2022
% Switch ROUTINE to fitmagfrd if ENFORCE_MINIMUM_PHASE flag is On
if ENFORCE_MINIMUM_PHASE==1
    fprintf('ENFORCE_MINIMUM_PHASE set to 1. FIT_ROUTINE set to fitfrdmag. \n')
    ROUTINE = 4;
end
% Added by NM on 28th April 2022
if INCLUDE_IODELAY == 1
    fprintf('INCLUDE_IODELAY set to 1. FIT_ROUTINE set to tfestimate. \n')
    ROUTINE = 2;
end


lb = [MIN_POLES,F_INITIAL-FREQ_WIN_LOW,F_FINAL-FREQ_WIN_UP, ROUTINE(1),WtMin];
ub = [MAX_POLES,F_INITIAL+FREQ_WIN_LOW,F_FINAL+FREQ_WIN_UP, ROUTINE(end),WtMax];


% Estimate Noise Floor
if FIT_NOISE_FLOOR == 1
    fprintf('Estimating noise floor...\n')
    mxx = dv_nfest( abs(TF), NFE_BW, NFE_OL);
    pxx = dv_nfest( angle(TF), NFE_BW, NFE_OL);
    TF = mxx.*exp(1i*pxx);
end



% % Truncate TF
% alpha = ALPHA;
% Flow = F_INITIAL;
% Fup  = F_FINAL;
% TF(f > Fup) = TF(f > Fup) .* (Fup ./ f(f > Fup)) .^alpha;
% TF(f < Flow) = TF(f < Flow) .* (f(f < Flow) ./ Flow) .^alpha;


% Smooth Frequency Response
if SMOOTH_LEVEL == 1
    disp('Smoothing frequency response via Local regression using weighted linear least squares and a 2nd degree polynomial model')
    TF  = smooth(TF,'rloess');
elseif SMOOTH_LEVEL == 2
    disp('Smoothing frequency response via Cublic Spline Smoothing');
    TF = csaps(f,TF,0.9999,f);
elseif SMOOTH_LEVEL == 3
    disp('Extreme Smoothing frequency response via Cublic Spline Smoothing');
    TF = csaps(f,TF,0.5,f);
elseif SMOOTH_LEVEL == 4
    disp('Extreme^2 Smoothing frequency response via Cublic Spline Smoothing');
    TF = csaps(f,TF,0.005,f);
elseif SMOOTH_LEVEL == 5
    disp('Smoothing frequency response via logMovingAverage Smoothing');
    
    try
        TF_ini = TF;
        TF = logAverager(TF, 1-1e-2);
    catch exception
        disp(getReport(exception))
    end
    
    try
        TF = mov_avg(TF);
    catch exception
        disp(getReport(exception))
    end
    
    if isnan(sum(TF)) || sum(TF)==0 || sum(TF)==Inf
        disp('Error in logMovingAverage smoothing, no smoothing applied...')
        TF = TF_ini;
    end
    
elseif SMOOTH_LEVEL == 6
    disp('Smoothing frequency response via filloutliers technique');
    fillMethod = 'makima';
    threshold = [1 99];
    zoutR = filloutliers(real(TF),fillMethod,'percentiles',threshold) ;
    zoutI = filloutliers(imag(TF),fillMethod,'percentiles',threshold);
    TF = zoutR + 1i*zoutI;
    
elseif SMOOTH_LEVEL == 7
    if SMOOTH_WIN_LEN > 0
        FRD=frd(movmean(TF,round(SMOOTH_WIN_LEN)),2*pi*f);
        TF = squeeze(FRD.ResponseData);
        f = FRD.Frequency/2/pi;
    end
end


% Fill missing values (NaN) with interpolated values
TF = fillmissing(TF,'spline');



% Initialize cohWeight if empty
if isempty(cohWeight)
    fprintf('Using uniform coherence weights.\n')
end

if FIT_WEIGHT_FROM_PHASE_SMOOTHNESS==1
    try
        fprintf('Using coherence weightage based on Phase-SmoothNess\n')
        PHSE = angle(TF);
        cohWeight = normalize([0; smooth(1-abs(filloutliers(diff(PHSE),'spline')))],'range');    catch EXPN
        disp(getReport(EXPN))
        fprintf('Using uniform coherence weights.\n')
        cohWeight = ones(size(TF));
    end
end


if PREVIEW_BODEPLOT_TOGGLE==1
    preview_bodeplot(BO,FIG_HANDLE,frd(TF_orig,2*pi*f_orig),frd(TF,2*pi*f),APP);
    FIT=[];
    close(FIG_TEMP);
else
    
    
    % Define cost function
    rf = @(Params)fitTF_costFunc(f,TF,Params); % objective
    
    gof = -inf;
    gof_reduced_order_best = -inf;
    
    
    for trial = 1:NUM_TRIALS
        
        % Check if StopExecutionButton State changed within the App
        if MATLAB_APP_TOGGLE == 1
            if APP.StopExecutionButton.Value==1
                return;
            end
        end
        
        
        fprintf('Executing trial %d of %d \n',trial,NUM_TRIALS)
        
        % Initial Guess
        if ~exist('GUESS','var')
            %x0 = 0.5*(lb+ub); % Start
            x0 = lb + (ub-lb).*rand(size(lb));
            disp('Using random initial guess....')
        else
            if (isstring(GUESS) || ischar(GUESS))
                if strcmpi(GUESS,'iterative')
                    if trial > 1
                        disp('Using best solution from previous iteration as initital GUESS')
                        % add some randomness to x0_best
                        x0 =  x0_best + x0_best.*randn(size(x0_best))*0;
                    else
                        x0 = lb + (ub-lb).*rand(size(lb));
                    end
                end
            else
                disp('using user provided GUESS value as starting point...')
                x0 = GUESS;
            end
        end
        
        
        % Fit a rational function (Vector Fitting with Surrogate Optimization)
        
        if strcmp(OPTIMIZER,'SURROGATE')
            % Optimization Options
            opts = optimoptions('surrogateopt','PlotFcn',[]);
            opts.MaxFunctionEvaluations = FUNC_EVAL;
            opts.UseParallel            = USE_PARALLEL;
            opts.Display                = OPTIMIZER_DISPLAY_LEVEL;
            
            disp('Performing surrogate optimization...')
            [xsur,~,~,~] = surrogateopt(rf,lb,ub,opts);
            disp('Performing additional local minima search using PATTERNSEARCH Search')
            if ~exist('xsur','var')
                xsur = x0;
            end
            [xsur]       = patternsearch(rf,xsur,[],[],[],[],lb,ub,[],opts);
            
        elseif strcmp(OPTIMIZER,'PSO')
            % Optimization Options
            opts = optimoptions('particleswarm','SwarmSize',200,'HybridFcn',@fmincon,'PlotFcn',[]);
            opts.MaxIterations = FUNC_EVAL;
            opts.UseParallel            = USE_PARALLEL;
            opts.Display                =  OPTIMIZER_DISPLAY_LEVEL;
            
            disp('Performing particle swarm optimization...')
            [xsur]       = particleswarm(rf,length(lb),lb,ub,opts);
            disp('Performing additional local minima search using Pattern Search')
            [xsur]       = patternsearch(rf,xsur,[],[],[],[],lb,ub,[],opts);
            
            
        elseif strcmp(OPTIMIZER,'PATTERNSEARCH')
            % Optimization Options
            opts = optimoptions('patternsearch','PlotFcn',[]);
            opts.MaxFunctionEvaluations = FUNC_EVAL;
            opts.UseParallel            = USE_PARALLEL;
            opts.Display                =  OPTIMIZER_DISPLAY_LEVEL;
            
            disp('Performing pattern search optimization...')
            [xsur]       = patternsearch(rf,x0,[],[],[],[],lb,ub,[],opts);
            
        elseif strcmp(OPTIMIZER,'FMINCON')
            % Optimization Options
            opts = optimoptions('fmincon','PlotFcn',[]);
            opts.MaxFunctionEvaluations = FUNC_EVAL;
            opts.UseParallel            = USE_PARALLEL;
            opts.Display                =  OPTIMIZER_DISPLAY_LEVEL;
            
            disp('Performing fmincon search optimization...')
            [xsur]       = fmincon(rf,x0,[],[],[],[],lb,ub,[],opts);
            
        elseif strcmp(OPTIMIZER,'BADS')
            
            % Install BADS if it doesn't exist
            if ~exist('bads','file')
                fprintf('Installing BADS optimizer...\n')
                outfilename = websave('bads.zip','https://github.com/lacerbi/bads/archive/master.zip');
                unzip(outfilename,'bads');
                addpath('bads/bads-master/')
            end
            
            % Optimization Options
            opts = bads;
            opts.MaxFunEvals = FUNC_EVAL;
            opts.UseParallel            = USE_PARALLEL;
            opts.Display                =  OPTIMIZER_DISPLAY_LEVEL;
            
            disp('Performing BADS (Bayesian ADaptive Search) optimization...')
            [xsur]       = bads(rf,x0,lb,ub,[],[],[],opts);
        end
        
        
        
        % Get Bestfit Model
        [~,modelSYS] = fitTF_costFunc(f,TF,xsur);
        [z,p,k] = zpkdata(modelSYS,'v');
        IODelay = modelSYS.IODelay;
        
        
        if ESTIMATE_UNCERTAINITY ~= 1
            % Damp unphysical resonances
            reso_thesh = 1e-4;
            p = cplxpair(p);
            RIDX = logical((abs(real(p)) < reso_thesh).*(abs(imag(p))>0)) ;
            
            try
                if ~isempty(RIDX)
                    %disp('Modeled response likely to have unphysical resonances...')
                    if DAMP_RESONANCES
                        %disp('Damping unphysical resonances....')
                        reso_p = cplxpair(p(RIDX));
                        reso_p = reso_p(1:floor(numel(reso_p)/2));
                        for klm = 1:2:numel(reso_p)
                            reso_p(klm) = imag(reso_p(klm))/RESO_DAMP_FAC   + 1i*imag(reso_p(klm));
                            reso_p(klm+1) = imag(reso_p(klm))/RESO_DAMP_FAC - 1i*imag(reso_p(klm));
                        end
                        p(RIDX) = reso_p;
                        modelSYS = zpk(z,p,k);
                    end
                end
            catch exception
                disp(getReport(exception))
            end
        end
        
        % Select region to fit
        ID = logical(f >= xsur(2)).*logical(f <= xsur(3));
        % ID = ones(size(ff));
        
        TF_trun    = TF(logical(ID));
        ff_trun    = f(logical(ID));
        % Generate FRD Model
        SYS_orig   = frd(TF_orig,f_orig*2*pi);
        SYS        = frd(TF,f*2*pi);
        trunSYS    = frd(TF_trun,ff_trun*2*pi);
        
        
        
        % Use MINREAL to cancel zeros & poles
        if ESTIMATE_UNCERTAINITY ~= 1
            try
                modelSYS = minreal(zpk(z,p,k),PZTOL);
            catch exception
                disp(getReport(exception))
            end
        end
        
        MODEL_ORDER = order(modelSYS);
        % Reduce model to the desired order using BALRED
        if ~isempty(DESIRED_MODEL_ORDER) && ESTIMATE_UNCERTAINITY ~= 1
            try
                modelSYS_temp = balred(zpk(z,p,k),DESIRED_MODEL_ORDER);
                [~,gof_trial_temp] = compareSYS(trunSYS,modelSYS_temp);
                if gof_trial_temp >= DESIRED_GOF
                    fprintf('Model order reduced from %d to the desired order(=%d)\n',MODEL_ORDER,DESIRED_MODEL_ORDER)
                    fprintf('GOF of Reduced Order higher than the Desired GOF(=%0.2f %s) \n',DESIRED_GOF,'%');
                    modelSYS = modelSYS_temp;
                    if gof_trial_temp > gof_reduced_order_best
                        modelSYS_best_reducedOrder = modelSYS_temp;
                        gof_reduced_order_best = gof_trial_temp;
                    end
                end
            catch exception
                disp(getReport(exception));
            end
            
        end
        
        % extract ZPK from the model
        [z,p,k,~,zcov,pcov,kcov] = zpkdata(modelSYS);
        
        
        z = cell2mat(z);
        p = cell2mat(p);
        
        z_sigma =  unpack_zpk_covariance_matrix(z,zcov);
        p_sigma =  unpack_zpk_covariance_matrix(p,pcov);
        k_sigma = sqrt(kcov);
        
        
        % Goodness of fit btw measured & modeled response
        %[~,gof_trial,~] = compare(trunSYS,modelSYS);
        [~,gof_trial] = compareSYS(trunSYS,modelSYS);
        fprintf('Trial %d -> goodness of fit (gof) = %0.2f %s\n',trial,gof_trial,'%')
        fprintf('Previous best goodness of fit (gof) = %0.2f %s\n',gof,'%')
        
        
        
        % this criterion was added to prevent some errors
        if ~(sum(real(p) > 0) > 0) && ENFORCE_STABILITY==1 && ENFORCE_MINIMUM_PHASE==0
            
            % Use PZCANCEL [NOT USED]
            %[z_ro,p_ro,k_ro] = pzcancel(z,p,k,PZTOL);
            %modelSYS_reducedOrder = zpk(z_ro,p_ro,k_ro);
            
            FIT.intermediate(trial).ZPK.z = z;
            FIT.intermediate(trial).ZPK.p = p;
            FIT.intermediate(trial).ZPK.k = k;
            FIT.intermediate(trial).ZPK.z_sigma = z_sigma;
            FIT.intermediate(trial).ZPK.p_sigma = p_sigma;
            FIT.intermediate(trial).ZPK.k_sigma = k_sigma;
            FIT.intermediate(trial).IODelay = IODelay;
            FIT.intermediate(trial).GOF = gof_trial;
            FIT.intermediate(trial).ORDER = order(modelSYS);
            FIT.intermediate(trial).FRD_Model.modeled = modelSYS;
            %FIT.intermediate(trial).FRD_Model.modeled_reducedOrder = modelSYS_reducedOrder;
            
            % parameterCovarianceMatrix
            if ESTIMATE_UNCERTAINITY==1
                if isfield(modelSYS.UserData,'CovarianceMatrix')
                    FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = modelSYS.UserData.CovarianceMatrix;
                else
                    FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = [];
                end
            else
                FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = [];
            end
            
            
            if gof_trial > gof
                fprintf('Better solution (gof = %0.2f %s) obtained. Updating best fit parameters...\n',gof_trial,'%')
                x0_best      = x0;
                xsur_best    = xsur;
                z_best       = z;
                p_best       = p;
                k_best       = k;
                IODelay_best = IODelay;
                z_best_sigma       = z_sigma;
                p_best_sigma       = p_sigma;
                k_best_sigma       = k_sigma;
                modelSYS_best = modelSYS;
                %modelSYS_best_reducedOrder = modelSYS_reducedOrder;
                gof          = gof_trial;
                best_trial   = trial;
                % accept if model order is less but has the same GOF
            elseif gof_trial == gof
                if order(modelSYS) < order(modelSYS_best)
                    fprintf(' Solution with similar gof (= %0.2f %s) but with a reduced order(=%d) obtained. Updating best fit parameters...\n',gof_trial,'%',order(modelSYS))
                    x0_best      = x0;
                    xsur_best    = xsur;
                    z_best       = z;
                    p_best       = p;
                    k_best       = k;
                    IODelay_best = IODelay;
                    z_best_sigma       = z_sigma;
                    p_best_sigma       = p_sigma;
                    k_best_sigma       = k_sigma;
                    modelSYS_best = modelSYS;
                    %modelSYS_best_reducedOrder = modelSYS_reducedOrder;
                    gof          = gof_trial;
                    best_trial   = trial;
                end
            end
            if INTERMEDIATE_PLOT
                FIG_HANDLE_VISIBILITY=0;
                BO.XLim = [xsur(2)/2 , 2*xsur(3)];
                BO.Title.String = sprintf('Bode Plot --> Trial No: %d of %d \n Goodness Of Fit (GOF): %0.2f %s (Best GOF: %0.2f %s)',trial,NUM_TRIALS,gof_trial,'%',gof,'%');
                BO.Title.FontSize = 15;
                make_plot(BO,SYS_orig,SYS,trunSYS,modelSYS, modelSYS_best);
            end
            FIG_HANDLE_VISIBILITY=FIG_HANDLE_VISIBILITY_ORIG;
            
        elseif  ENFORCE_STABILITY~=1
            
            % Use PZCANCEL [NOT USED]
            %[z_ro,p_ro,k_ro] = pzcancel(z,p,k,PZTOL);
            %modelSYS_reducedOrder = zpk(z_ro,p_ro,k_ro);
            FIT.intermediate(trial).ZPK.z = z;
            FIT.intermediate(trial).ZPK.p = p;
            FIT.intermediate(trial).ZPK.k = k;
            FIT.intermediate(trial).ZPK.z_sigma = z_sigma;
            FIT.intermediate(trial).ZPK.p_sigma = p_sigma;
            FIT.intermediate(trial).ZPK.k_sigma = k_sigma;
            FIT.intermediate(trial).IODelay = IODelay;
            FIT.intermediate(trial).GOF = gof_trial;
            FIT.intermediate(trial).ORDER = order(modelSYS);
            FIT.intermediate(trial).FRD_Model.modeled = modelSYS;
            %FIT.intermediate(trial).FRD_Model.modeled_reducedOrder = modelSYS_reducedOrder;
            
            % parameterCovarianceMatrix
            if ESTIMATE_UNCERTAINITY==1
                if isfield(modelSYS.UserData,'CovarianceMatrix')
                    FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = modelSYS.UserData.CovarianceMatrix;
                else
                    FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = [];
                end
            else
                FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = [];
            end
            
            if gof_trial > gof
                fprintf('Better solution (gof = %0.2f %s) obtained. Updating best fit parameters...\n',gof_trial,'%')
                x0_best      = x0;
                xsur_best    = xsur;
                z_best       = z;
                p_best       = p;
                k_best       = k;
                IODelay_best = IODelay;                
                z_best_sigma       = z_sigma;
                p_best_sigma       = p_sigma;
                k_best_sigma       = k_sigma;
                modelSYS_best = modelSYS;
                %modelSYS_best_reducedOrder = modelSYS_reducedOrder;
                gof          = gof_trial;
                best_trial   = trial;
                % accept if model order is less but has the same GOF
            elseif gof_trial == gof
                if order(modelSYS) < order(modelSYS_best)
                    fprintf(' Solution with similar gof (= %0.2f %s) but with a reduced order(=%d) obtained. Updating best fit parameters...\n',gof_trial,'%',order(modelSYS))
                    x0_best      = x0;
                    xsur_best    = xsur;
                    z_best       = z;
                    p_best       = p;
                    k_best       = k;
                    IODelay_best = IODelay;                    
                    z_best_sigma       = z_sigma;
                    p_best_sigma       = p_sigma;
                    k_best_sigma       = k_sigma;
                    modelSYS_best = modelSYS;
                    %modelSYS_best_reducedOrder = modelSYS_reducedOrder;
                    gof          = gof_trial;
                    best_trial   = trial;
                end
            end
            if INTERMEDIATE_PLOT
                FIG_HANDLE_VISIBILITY=0;
                BO.XLim = [xsur(2)/2 , 2*xsur(3)];
                BO.Title.String = sprintf('Bode Plot --> Trial No: %d of %d \n Goodness Of Fit (GOF): %0.2f %s (Best GOF: %0.2f %s)',trial,NUM_TRIALS,gof_trial,'%',gof,'%');
                BO.Title.FontSize = 15;
                make_plot(BO,SYS_orig,SYS,trunSYS,modelSYS, modelSYS_best);
            end
            FIG_HANDLE_VISIBILITY=FIG_HANDLE_VISIBILITY_ORIG;
            
            
        elseif ~(sum(real(p) > 0) > 0) && ENFORCE_STABILITY==1 && ENFORCE_MINIMUM_PHASE==1
            
            % Proceed only if no +ve Zeros are present (MINIMUM PHASE SYSTEMS)
            if ~sum(real(z) > 0 ) > 0 %~sum(z(imag(z)==0) > 0 ) > 0
                
                
                
                % Use PZCANCEL [NOT USED]
                %[z_ro,p_ro,k_ro] = pzcancel(z,p,k,PZTOL);
                %modelSYS_reducedOrder = zpk(z_ro,p_ro,k_ro);
                
                FIT.intermediate(trial).ZPK.z = z;
                FIT.intermediate(trial).ZPK.p = p;
                FIT.intermediate(trial).ZPK.k = k;
                FIT.intermediate(trial).ZPK.z_sigma = z_sigma;
                FIT.intermediate(trial).ZPK.p_sigma = p_sigma;
                FIT.intermediate(trial).ZPK.k_sigma = k_sigma;
                FIT.intermediate(trial).IODelay = IODelay;               
                FIT.intermediate(trial).GOF = gof_trial;
                FIT.intermediate(trial).ORDER = order(modelSYS);
                FIT.intermediate(trial).FRD_Model.modeled = modelSYS;
                %FIT.intermediate(trial).FRD_Model.modeled_reducedOrder = modelSYS_reducedOrder;
                
                % parameterCovarianceMatrix
                if ESTIMATE_UNCERTAINITY==1
                    if isfield(modelSYS.UserData,'CovarianceMatrix')
                        FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = modelSYS.UserData.CovarianceMatrix;
                    else
                        FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = [];
                    end
                else
                    FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = [];
                end
                
                
                if gof_trial > gof
                    fprintf('Better solution (gof = %0.2f %s) obtained. Updating best fit parameters...\n',gof_trial,'%')
                    x0_best      = x0;
                    xsur_best    = xsur;
                    z_best       = z;
                    p_best       = p;
                    k_best       = k;
                    IODelay_best = IODelay;
                    z_best_sigma       = z_sigma;
                    p_best_sigma       = p_sigma;
                    k_best_sigma       = k_sigma;
                    modelSYS_best = modelSYS;
                    %modelSYS_best_reducedOrder = modelSYS_reducedOrder;
                    gof          = gof_trial;
                    best_trial   = trial;
                    % accept if model order is less but has the same GOF
                elseif gof_trial == gof
                    if order(modelSYS) < order(modelSYS_best)
                        fprintf(' Solution with similar gof (= %0.2f %s) but with a reduced order(=%d) obtained. Updating best fit parameters...\n',gof_trial,'%',order(modelSYS))
                        x0_best      = x0;
                        xsur_best    = xsur;
                        z_best       = z;
                        p_best       = p;
                        k_best       = k;
                        IODelay_best = IODelay;                       
                        z_best_sigma       = z_sigma;
                        p_best_sigma       = p_sigma;
                        k_best_sigma       = k_sigma;
                        modelSYS_best = modelSYS;
                        %modelSYS_best_reducedOrder = modelSYS_reducedOrder;
                        gof          = gof_trial;
                        best_trial   = trial;
                    end
                end
                if INTERMEDIATE_PLOT
                    FIG_HANDLE_VISIBILITY=0;
                    BO.XLim = [xsur(2)/2 , 2*xsur(3)];
                    BO.Title.String = sprintf('Bode Plot --> Trial No: %d of %d \n Goodness Of Fit (GOF): %0.2f %s (Best GOF: %0.2f %s)',trial,NUM_TRIALS,gof_trial,'%',gof,'%');
                    BO.Title.FontSize = 15;
                    make_plot(BO,SYS_orig,SYS,trunSYS,modelSYS, modelSYS_best);
                end
                FIG_HANDLE_VISIBILITY=FIG_HANDLE_VISIBILITY_ORIG;
                
            elseif  ENFORCE_STABILITY~=1
                
                % Use PZCANCEL [NOT USED]
                %[z_ro,p_ro,k_ro] = pzcancel(z,p,k,PZTOL);
                %modelSYS_reducedOrder = zpk(z_ro,p_ro,k_ro);
                FIT.intermediate(trial).ZPK.z = z;
                FIT.intermediate(trial).ZPK.p = p;
                FIT.intermediate(trial).ZPK.k = k;
                FIT.intermediate(trial).ZPK.z_sigma = z_sigma;
                FIT.intermediate(trial).ZPK.p_sigma = p_sigma;
                FIT.intermediate(trial).ZPK.k_sigma = k_sigma;
                FIT.intermediate(trial).IODelay = IODelay;               
                FIT.intermediate(trial).GOF = gof_trial;
                FIT.intermediate(trial).ORDER = order(modelSYS);
                FIT.intermediate(trial).FRD_Model.modeled = modelSYS;
                %FIT.intermediate(trial).FRD_Model.modeled_reducedOrder = modelSYS_reducedOrder;
                
                % parameterCovarianceMatrix
                if ESTIMATE_UNCERTAINITY==1
                    if isfield(modelSYS.UserData,'CovarianceMatrix')
                        FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = modelSYS.UserData.CovarianceMatrix;
                    else
                        FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = [];
                    end
                else
                    FIT.intermediate(trial).ZPK.parameterCovarianceMatrix = [];
                end
                
                if gof_trial > gof
                    fprintf('Better solution (gof = %0.2f %s) obtained. Updating best fit parameters...\n',gof_trial,'%')
                    x0_best      = x0;
                    xsur_best    = xsur;
                    z_best       = z;
                    p_best       = p;
                    k_best       = k;
                    IODelay_best = IODelay;                    
                    z_best_sigma       = z_sigma;
                    p_best_sigma       = p_sigma;
                    k_best_sigma       = k_sigma;
                    modelSYS_best = modelSYS;
                    %modelSYS_best_reducedOrder = modelSYS_reducedOrder;
                    gof          = gof_trial;
                    best_trial   = trial;
                    % accept if model order is less but has the same GOF
                elseif gof_trial == gof
                    if order(modelSYS) < order(modelSYS_best)
                        fprintf(' Solution with similar gof (= %0.2f %s) but with a reduced order(=%d) obtained. Updating best fit parameters...\n',gof_trial,'%',order(modelSYS))
                        x0_best      = x0;
                        xsur_best    = xsur;
                        z_best       = z;
                        p_best       = p;
                        k_best       = k;
                        IODelay_best = IODelay;                     
                        z_best_sigma       = z_sigma;
                        p_best_sigma       = p_sigma;
                        k_best_sigma       = k_sigma;
                        modelSYS_best = modelSYS;
                        %modelSYS_best_reducedOrder = modelSYS_reducedOrder;
                        gof          = gof_trial;
                        best_trial   = trial;
                    end
                end
                if INTERMEDIATE_PLOT
                    FIG_HANDLE_VISIBILITY=0;
                    BO.XLim = [xsur(2)/2 , 2*xsur(3)];
                    BO.Title.String = sprintf('Bode Plot --> Trial No: %d of %d \n Goodness Of Fit (GOF): %0.2f %s (Best GOF: %0.2f %s)',trial,NUM_TRIALS,gof_trial,'%',gof,'%');
                    BO.Title.FontSize = 15;
                    make_plot(BO,SYS_orig,SYS,trunSYS,modelSYS, modelSYS_best);
                end
                FIG_HANDLE_VISIBILITY=FIG_HANDLE_VISIBILITY_ORIG;
                
                
            else
                fprintf('Trial %d has zeros with +ve real part -> NON_MINIMUM_PHASE -> skipping...  \n',trial)
            end
            
        else
            fprintf('Trial %d has poles with +ve real part -> UNSTABLE -> skipping...  \n',trial)
        end
        fprintf(' \n')
        
        % increase MAX_POLES if gof_trial is not increasing
        if ATTAIN_GOF == 1
            if mod(trial,POLE_UPDATE_TRIAL)==0
                if gof < DESIRED_GOF
                    fprintf('Current best GOF (%0.2f %s) less than the required GOF (%0.2f %s) \n',gof,'%',DESIRED_GOF,'%');
                    fprintf('Increasing the number of poles from %d to %d  \n',ub(1),ub(1)+1);
                    ub(1) = ub(1)+1;
                else
                    fprintf('Current best GOF (%0.2f %s) greater than the required GOF (%0.2f %s) \n',gof, '%',DESIRED_GOF,'%');
                    fprintf('Finishing execution...\n')
                    break;
                end
            end
        end
        
        
    end
    
    fprintf('Final goodness fo fit (focus region) = %0.3f %s\n',gof,'%')
    
    
    % Get current date & time
    fID = strrep(string(datetime),':','_');
    fID = strrep(fID,'-','_');
    fID = strrep(fID,' ','_');
    
    % Get Username
    fullname  = 'unknown';
    try
        if ispc
            [~, fullname] = system('hostname');
        else
            [~, fullname] = system('id -F');
        end
    catch exception
        disp(getReport(exception))
    end
    
    % Weight Filter options
    WtFilter = ["EQUAL","ABSOLUTE","INVERSE","INVERSE_SQUARE_ROOT","CUSTOM"];
    
    % Fit Routines
    Routines = ["rationalfit","tfest","invfreqs","fitmagfrd"];
    
    % Check if atleast one solution was found else return & disp status
    if ~exist('p_best','var')
        fprintf('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n')
        fprintf('Unable to find a solution with the given settings.\n')
        fprintf('Relax some of the specified settings. (Ex. Set INCLUDE_DELAY=0)\n')
        fprintf('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n')        
        FIT=[];
        close(FIG_TEMP);
        return
    end
    
    
    % Create FIT Structure [OUTPUT]
    FIT.ZPK.z = z_best;
    FIT.ZPK.p = p_best;
    FIT.ZPK.k = k_best;
    FIT.IODelay = IODelay_best;
    FIT.ZPK.z_sigma = z_best_sigma;
    FIT.ZPK.p_sigma = p_best_sigma;
    FIT.ZPK.k_sigma = k_best_sigma;
    
    % parameterCovarianceMatrix
    if ESTIMATE_UNCERTAINITY==1
        if isfield(modelSYS_best.UserData,'CovarianceMatrix')
            FIT.ZPK.parameterCovarianceMatrix = modelSYS_best.UserData.CovarianceMatrix;
        else
            FIT.ZPK.parameterCovarianceMatrix = [];
        end
    else
        FIT.ZPK.parameterCovarianceMatrix = [];
    end
    
    
    FIT.gof = gof;
    
    FIT.frequency.measured = f_orig;
    FIT.frequency.truncated = ff_trun;
    
    FIT.transferFunction.measured = TF_orig;
    FIT.transferFunction.measured_smoothed = TF;
    FIT.transferFunction.truncated = TF_trun;
    
    FIT.FRD_Model.measured_original = SYS_orig;
    FIT.FRD_Model.measured_smoothed = SYS;
    FIT.FRD_Model.truncated         = trunSYS;
    FIT.FRD_Model.modeled           = modelSYS_best;
    
    % add reduced order model
    [~,temp_p_3] = zpkdata(modelSYS_best,'v');
    
    if exist('modelSYS_best_reducedOrder','var')
        [~,temp_p_4] = zpkdata(modelSYS_best_reducedOrder,'v');
        if length(temp_p_4) < length(temp_p_3)
            fprintf('model order reduction possible from %d -> %d poles \n',length(modelSYS.P{:}), length(modelSYS_best_reducedOrder.P{:}))  ;
            FIT.FRD_Model.modeled_reducedOrder =  modelSYS_best_reducedOrder;
            
            [z_ro,p_ro,k_ro,z_ro_cov,p_ro_cov,k_ro_cov] = zpkdata(modelSYS_best_reducedOrder);
            
            FIT.ZPK_Reduced_Order.z = z_ro{:};
            FIT.ZPK_Reduced_Order.p = p_ro{:};
            FIT.ZPK_Reduced_Order.k = k_ro(1);
            FIT.ZPK_Reduced_Order.z_sigma = z_ro_cov;
            FIT.ZPK_Reduced_Order.p_sigma = p_ro_cov;
            FIT.ZPK_Reduced_Order.k_sigma = k_ro_cov;
            
        end
    end
    
    FIT.options.BodeOptions = BO;
    FIT.options.PLOT_TOGGLE = PLOT_TOGGLE;
    FIT.options.SAVE_TOGGLE = SAVE_TOGGLE;
    FIT.options.F_INITIAL = F_INITIAL;
    FIT.options.F_FINAL = F_FINAL;
    FIT.options.MIN_POLES = MIN_POLES;
    FIT.options.MAX_POLES = MAX_POLES;
    FIT.options.FREQ_WIN_LOW = FREQ_WIN_LOW;
    FIT.options.FREQ_WIN_UP = FREQ_WIN_UP;
    FIT.options.FUNC_EVAL = FUNC_EVAL;
    FIT.options.USE_PARALLEL = USE_PARALLEL;
    FIT.options.SMOOTH_LEVEL = SMOOTH_LEVEL;
    FIT.options.Optimization.OPTIMIZER = OPTIMIZER;
    FIT.options.Optimization.options = opts;
    FIT.options.Optimization.lb = lb;
    FIT.options.Optimization.ub = ub;
    FIT.options.Optimization.startingPoints = x0_best;
    FIT.options.Optimization.NUM_TRIALS  = NUM_TRIALS;
    FIT.options.Optimization.BEST_TRIAL  = best_trial;
    FIT.options.Optimization.results    = xsur_best;
    FIT.options.Optimization.Num_Poles  = round(xsur_best(1));
    FIT.options.Optimization.F_Start    = xsur_best(2);
    FIT.options.Optimization.F_Stop     = xsur_best(3);
    FIT.options.Optimization.FINAL_FIT_ROUTINE = Routines(round(xsur_best(4)));
    FIT.options.Optimization.FINAL_WEIGHTING_FILTER = WtFilter(round(xsur_best(5)));
    FIT.dateTime = fID;
    FIT.userName = string(fullname);
    
    % if strcmp(FIT.options.Optimization.FINAL_FIT_ROUTINE,"tfest")
    %     disp('Estimating model uncertainities...')
    %     [num,den,Ts,sdnum,sdden] = tfdata(FIT.FRD_Model.modeled);
    %     FIT.tfdata.num = cell2mat(num);
    %     FIT.tfdata.den = cell2mat(den);
    %     FIT.tfdata.Ts = Ts;
    %     FIT.tfdata.sdnum = cell2mat(sdnum);
    %     FIT.tfdata.sdden = cell2mat(sdden);
    % end
    
    % Add CUSTOM_WEIGHT to FIT (if provided)
    if WtMax == 5
        FIT.options.CUSTOM_WEIGHT = cohWeight;
    end
    
    % try
    % Save input command used to generate the results
    FIT_STR = repmat('"%s",',1,numel(varargin));
    FIT_STR(end) = [];
    VARARGIN = string(size(varargin));
    for iii = 1:numel(varargin)
        if (ischar(varargin{iii}) || isa(varargin{iii},'string'))
            if numel(string(varargin{iii}))>1
                VARARGIN(iii) = strjoin(varargin{iii});
            else
                VARARGIN(iii) = varargin{iii};
            end
        elseif isa(varargin{iii},'ao') || isa(varargin{iii},'zpk')
            VARARGIN(iii) = class(varargin{iii});
        else
            if numel(varargin{iii}) > 1
                VARARGIN(iii) = class(varargin{iii});
            else
                try
                    VARARGIN(iii) = varargin{iii};
                catch
                    VARARGIN(iii)  = 'val';
                end
            end
        end
    end
    FIT_STR = sprintf(FIT_STR,string(VARARGIN));
    FIT_STR = sprintf('FIT = fitTF(%s);',FIT_STR);
    FIT.inputCommand = FIT_STR;
    FIT.options.EXTRA_INFO = EXTRA_INFO;
    % catch exception
    %     disp(getReport(exception))
    % end
    
    
    
    
    BO.XLim = [FIT.options.Optimization.F_Start/2,FIT.options.Optimization.F_Stop*2];
    
    
    
    
    if PLOT_TOGGLE
        
        BO.Title.String = sprintf('Bode Plot');
        BO.Title.FontSize = 15;
        if exist('modelSYS_best_reducedOrder','var')
            make_plot(BO,SYS_orig,SYS,trunSYS,modelSYS_best,modelSYS_best,modelSYS_best_reducedOrder);
        else
            make_plot(BO,SYS_orig,SYS,trunSYS,modelSYS_best,modelSYS_best);
        end
        
        if SAVE_TOGGLE
            
            disp('Saving results...')
            
            if strcmp(SAVETO,'./Saved_Models')
                if ~exist('Saved_Models','dir')
                    mkdir('Saved_Models');
                end
            else
                mkdir(SAVETO);
            end
            
            if exist('SAVEAS','var')
                fID = string(SAVEAS)+"_"+string(fID);
            end
            
            FolderName = sprintf('%s/%s',SAVETO,fID);
            mkdir(FolderName)
            
            fileName = sprintf('%s/FIT.mat',FolderName);
            foton_sos_fileName = sprintf('%s/foton_sos_filter.txt',FolderName);
            foton_sos_fileName_reducedOrder = sprintf('%s/foton_sos_filter_reducedOrder.txt',FolderName);
            figName = sprintf('%s/bode_plot.fig',FolderName);
            imageName = sprintf('%s/bode_plot.png',FolderName);
            
            
            save(fileName,'FIT')
            savefig(gcf,figName)
            
            % Use exportgraphics function (if available)
            if exist('exportgraphics','file') == 6
                exportgraphics(gcf,imageName);
            else
                saveas(gcf,imageName)
            end
            
            % Save FOTON Compatible SOS Filter
            fprintf(' \n')
            disp("Generating FOTON Compatible SOS Filter...")
            try
                quack3andahalf_modified(zpk(FIT.ZPK.z,FIT.ZPK.p,FIT.ZPK.k),FOTON_FS,foton_sos_fileName);
                % Save reduced order model too
                if isfield(FIT.FRD_Model,'modeled_reducedOrder')
                    if length(FIT.FRD_Model.modeled_reducedOrder.P{:}) < length(FIT.FRD_Model.modeled.P{:})
                        fprintf(' \n')
                        disp("Generating Reduced Order FOTON Compatible SOS Filter...")
                        quack3andahalf_modified(zpk(FIT.FRD_Model.modeled_reducedOrder.Z{:},FIT.FRD_Model.modeled_reducedOrder.P{:},FIT.FRD_Model.modeled_reducedOrder.K(1)),FOTON_FS,foton_sos_fileName_reducedOrder);
                    end
                end
                fprintf('  \n')
                fprintf('Model & figure saved to %s \n',FolderName)
            catch exception
                disp(getReport(exception))
                disp("FOTON Compatible SOS filter not generated.")
            end
            
        end
    end
    
    % Check if system is stable or not
    if sum(real(FIT.ZPK.p) > 0) > 0
        beep
        disp('---------------------------------')
        disp('### *ALERT* ###')
        disp('Some of the poles have non-negative real part.')
        disp('Modelled system likely to be unstable.')
        disp('Try rerunning with/without changes to frequency limits & smoothing factor.')
        disp('### ******* ###')
        disp('---------------------------------')
    else
        disp('Execution complete.')
    end
    
    % CLEAR UP PERSISTENT VARIABLES
    clear FIG_HANDLE
    
    
    toc
    
    
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FIT Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    
    dispayStruct.z       = FIT.ZPK.z;
    dispayStruct.p       = FIT.ZPK.p;
    dispayStruct.k       = FIT.ZPK.k;
    dispayStruct.z_sigma = FIT.ZPK.z_sigma;
    dispayStruct.p_sigma = FIT.ZPK.p_sigma;
    dispayStruct.k_sigma = FIT.ZPK.k_sigma;
    dispayStruct.gof     = FIT.gof;
    celldisp(struct2cell(dispayStruct),'FIT results:[{1}->Zeros,{2}->Poles,{3}->Gain,{4}->z_sigma,{5}->p_sigma,{6}->k_sigma,{7}->GOF(%)] ');
    
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    
    % close temp fig
    if exist('FIG_TEMP','var')
        if ishandle(FIG_TEMP)
            close(FIG_TEMP);
        end
    end
    
    % include variables from APP to FIT structure
    FIT.APP = APP;

end

% Identify a dynamical sysID model to the given measurement
%
% Inputs:
%        ff: frequency in Hz
%        TF: measured transfer function (a+ib form)
%
% Outputs:
%       residual = 1 - (gof/100);
%       gof: goodness of fit btw measured & modeled response
%
% Author:
%       Nikhil Mukund (AEI Hannover)
%
% Last Modified:
%      1st May 2019
    function[residual,modelSYS] =  fitTF_costFunc(ff,TF,Params)
        
        
        
        
        % Disable warning
        warning('off','all');
        
        NUM_POLES = round(Params(1));
        F_INITIAL0 = Params(2);
        F_FINAL0   = Params(3);
        FIT_ROUTINE = round(Params(4));
        WEIGHT      = round(Params(5));
        
        % Select region to fit
        ID0 = logical(ff >= F_INITIAL0).*logical(ff <= F_FINAL0);
        
        TF_trun0    = TF(logical(ID0));
        ff_trun0    = ff(logical(ID0));
        
        
        
        % Generate FRD Model
        trunSYS0    = frd(TF_trun0,ff_trun0*2*pi);
        
        
        % Weighting Filter
        if WEIGHT == 1
            Wt = ones(size(TF_trun0));
        elseif WEIGHT == 2
            Wt = abs(TF_trun0);
        elseif WEIGHT == 3
            Wt = 1./abs(TF_trun0);
        elseif WEIGHT == 4
            Wt = 1./sqrt(abs(TF_trun0));
        elseif WEIGHT == 5
            Wt = cohWeight(logical(ID0));
        end
        
        % tfest options
        tfestOpt = tfestOptions(...
            'EnforceStability',ENFORCE_STABILITY,...
            'InitializeMethod','n4sid',...
            'WeightingFilter',Wt,...
            'Display','off',...
            'EstimateCovariance',1);
        
        
        
        if FIT_ROUTINE == 1
            
            % Fit a rational function (Vector Fitting)
            fit  =  rationalfit(ff_trun0,TF_trun0,'Npoles',NUM_POLES,'Weight',Wt);
            [b,a] = residue (fit.C,fit.A,fit.D);
            modelSYS = tf(real (b),a);
            
        elseif FIT_ROUTINE == 2

            if INCLUDE_IODELAY == 1
                iodelay_flag = NaN;
            else
                iodelay_flag = [];
            end
            
            % Fit using tfest
            if isempty(NUM_ZEROS)
                modelSYS = tfest(trunSYS0,NUM_POLES,NUM_POLES,iodelay_flag,tfestOpt);
            else
                % Use min(NUM_POLES,NUM_ZEROS) for NUM_ZEROS
                modelSYS = tfest(trunSYS0,NUM_POLES,min(NUM_POLES,NUM_ZEROS),iodelay_flag,tfestOpt);
            end
            
            % ESTIMATE_UNCERTAINITY
            [zz,pp,~] = zpkdata(modelSYS,'v');
            try
                VALUE = getcov(modelSYS,'FACTORS','free');
                
                np = length(VALUE.Free); % size of covariance matrix
                CovarianceMatrix = zeros(np);
                CovarianceMatrix(VALUE.Free, VALUE.Free) = VALUE.T*(VALUE.R'*VALUE.R)\(VALUE.T');
                sigmaCovMat = sqrt(diag(CovarianceMatrix));
                modelSYS.UserData.VALUE = VALUE;
                modelSYS.UserData.CovarianceMatrix = CovarianceMatrix;
                modelSYS.UserData.sigmaCovMat = sigmaCovMat;
                try
                    modelSYS.UserData.sigmaZ = sigmaCovMat(1:numel(zz));
                    modelSYS.UserData.sigmaP = sigmaCovMat(numel(zz)+1:numel(zz)+numel(pp));
                    modelSYS.UserData.sigmaK = sigmaCovMat(numel(zz)+numel(pp)+1:length(sigmaCovMat));
                catch EXCEPTION
                    disp(getReport(EXCEPTION))
                end
                
            catch EXCEPTION
                disp(getReport(EXCEPTION))
                fprintf('Unable to calculate the associated uncertainity. \n')
            end
            
        elseif FIT_ROUTINE == 3
            
            % Fit using invfreqs
            [b,a] = invfreqs(TF_trun0,ff_trun0*2*pi,NUM_POLES,NUM_POLES,Wt,1e3,1e-11);
            modelSYS = tf(real (b),a);

        elseif FIT_ROUTINE == 4
            
            % Fit using fitmagfrd using
            %   minimum-phase state-space model using log-Chebyshev magnitude design
            modelSYS = fitmagfrd(trunSYS0,NUM_POLES);

        end
        
        % Get MAG & PHS of measured system
        [MAG_o,PHS_o,W_o] = bode(trunSYS0);
        MAG_o = squeeze(MAG_o);
        PHS_o = squeeze(PHS_o);
        
        % Get MAG & PHS of modeled system
        [MAG_m,PHS_m] = bode(modelSYS,W_o);
        MAG_m = squeeze(MAG_m);
        PHS_m = squeeze(PHS_m);
        
        
        % Goodness of fit btw measured & modeled response
        compareArray = @(x,y) norm(x - y)./norm(x - mean(x));
        % A a weighting function
        %compareArray = @(x,y) norm((x - y).*cohWeight(logical(ID0))')./norm((x - mean(x)).*cohWeight(logical(ID0))');
        
        % Overall Residual
        [~,gof0,~] = compare(trunSYS0,modelSYS);
        residual_frd = 1 - (gof0/100);
        % Magnitude Residual
        residual_mag = compareArray(log10(MAG_o),log10(MAG_m));
        % Phase Residual
        residual_phs = compareArray(wrapTo180(PHS_o),wrapTo180(PHS_m));
        
        % Slightly more weightage to Phase
        residual = 0.0*residual_frd + 0.5*residual_mag + 0.5*residual_phs;
        
        
        
    end

    function [coe] = quack3andahalf_modified(gomo,Fs,filename,varargin)
        
        
        % Digital Filter Maker
        % This function takes as arguments, gomo, a matlab 'sys' object
        % and the sample frequency, Fs, at which to make coefs.
        % Other arguments (e.g., pre-warp frequency) are passed to bilinear.
        %
        % It returns the digital filter coefficients in the order
        % they go in the CDS standard filter modules.
        % i.e. LSC FE, ASC FE, DSC, MSC, PEPI (someday)
        %
        % Example 1 (low pass):
        % [z,p,k] = ellip(6,1,40,2*pi*35,'s');
        % goo = zpk(z,p,k);
        %
        % quack3(goo,2048)
        %
        % Example 2 (notch):
        %
        % f_notch = 60;
        % notch_Q = 30;
        % hole = twint(f_notch,notch_Q);
        % quack3(hole,2048,f_notch);
        %
        %
        % if nargin == 3
        %   f_prewarp = varargin{1};
        % elseif nargin == 4
        %   fname = varargin{2};
        %   f_prewarp = varargin{1};
        % end
        
        
        
        % Getting the ZPK data
        [ZZZ,PPP,KKK] = zpkdata(gomo,'v');
        
        % Bilinear transform from s to z plane
        [zd,pd,kd] = bilinear(ZZZ,PPP,KKK,Fs,varargin{:});
        
        % SOSing the digital zpk
        
        [sos,gs] = zp2sos(zd,pd,kd);
        
        [~,ca] = sos_shuffle(sos);
        
        coe = real([gs ca']);
        
        
        
        function format_foton(coe)
            % produce formatted output for Foton
            fprintf(1, '\n');
            fprintf(1, '\n');
            fprintf(1, '\n');
            fprintf(1,'sos(%15.30f,   [ ', coe(1));
            fprintf(1,'%18.30f; ', coe(2:5));
            for n = 6:4:length(coe)
                fprintf(1, '\n');
                fprintf(1, '%25c', ' ');
                fprintf(1, '%18.30f; ',coe(n:n+3));
            end
            fprintf(1, ' ],"o")\n');
        end
        %movefile(sprintf('%s.txt',char(filename)),'./junk');
        diary(sprintf('%s',char(filename)));
        % Use them to produce formatted output:
        n_blocks = ceil((length(coe)-1)/40);
        for block=1:n_blocks
            first_index = (block - 1)*40 + 2;
            last_index = min(first_index + 39, length(coe));
            if block==1
                gain = coe(1);
            else
                gain = 1;
            end
            %     format_txt([gain coe(first_index:last_index)]);
            format_foton([gain coe(first_index:last_index)]);
        end
        diary off
    end % function quack3


    function [g,ca] = sos_shuffle(sos, fname)
        
        %  SOS_SHUFFLE(SOS,'FNAME') reorganize digital filter coeffs.
        %  [G, CA] = SOS_SHUFFLE(SOS,'FNAME') re-organizes the coefficients
        %  of a cascaded, second order section IIR filter, from the
        %  order produced by a Matlab sos command, to the order
        %  used in real-time C realization (ala Embree). G is the
        %  overall gain factor, and CA is a column vector containing
        %  the filter coefficients in the order:
        %
        %        [a11 a21 b11 b21 a12 a22 b12 b22 ... ]
        %
        %  The b0i are all unity in this convention. If the optional
        %  filename fname is included, the coefficients are written
        %  to the file fname in the above order, delimited by commas,
        %  with the gain factor in the first element, using 15 digits.
        g = prod(sos(:,1));
        b = [sos(:,2)./sos(:,1), sos(:,3)./sos(:,1)];
        a = [sos(:,5), sos(:,6)];
        ab = [a b];
        abT = ab';
        ca = abT(:);
        if (nargin == 2)
            fid = fopen(fname,'w');
            fprintf(fid,'%15.14f',g);
            fprintf(fid,', %15.14f',ca);
            fclose(fid);
        end
    end


    function zOut = logAverager(z, smoothing)
        zMagnitudeSmooth = exp(filter(smoothing, [1 smoothing-1], log(abs(z))));
        zAngleSmooth = exp(filter(smoothing, [1 smoothing-1], log(angle(z))));
        zOut = zMagnitudeSmooth .* exp(1i .* zAngleSmooth);
    end

% Try moving average filter
    function zOut = mov_avg(z,windowSize)
        if nargin == 1
            windowSize = 10;
        end
        movF = ones(1, windowSize)/windowSize;
        zOut = filtfilt(movF, 1, z);
    end

    function [x, y, fs] = vectorMatch(x, xfs, y, yfs)
        
        if yfs > xfs
            y = resample(y, xfs, yfs);
            fs = xfs;
        end
        
        if xfs > yfs
            x = resample(x,yfs,xfs);
            fs = yfs;
        end
        
        if xfs == yfs
            fs = xfs;
        end
        
        % now check the vector lengths
        nx = length(x);
        ny = length(y);
        
        if nx > ny
            disp('!!! vectors are not equal lengths. Truncating x. !!!');
            x = x(1:ny);
        end
        if ny > nx
            disp('!!! vectors are not equal lengths. Truncating y. !!!');
            y = y(1:nx);
        end
        
    end



    function make_plot(BO,SYS_orig,SYS,trunSYS,modelSYS,modelSYS_best,modelSYS_best_reducedOrder)
        
        [~,temp_p] = zpkdata(modelSYS,'v');
        
        % FIG_GCF.Visible = 'off';
        %figure(FIG_GCF);
        FIG_GCF = figure(FIG_HANDLE,'Visible',FIG_HANDLE_VISIBILITY);
        
        
        if nargin < 7
            
            if isequal(modelSYS,modelSYS_best)
                BD = bodeplot(SYS_orig,SYS,trunSYS,modelSYS_best,BO);
            else
                BD = bodeplot(SYS_orig,SYS,trunSYS,modelSYS_best,modelSYS,BO);
            end
            
            % set ylim to within the original levels defined by SYS_orig
            YLIM = getoptions(BD,'YLim');
            [SS,LL] = bounds(abs(squeeze(SYS_orig.ResponseData)));
            YLIM(1)= {mag2db([SS,LL]) + [-5,+5]};   % mag2db with some margin
            YLIM(2)= {[-180,180]};
            setoptions(BD,'YLim',YLIM)
            
            [~,gof_tempo] = compareSYS(trunSYS,modelSYS);
            if isequal(modelSYS,modelSYS_best)
                
                if ~isempty(modelSYS.UserData)
                    [lgnd, hobj, ~, ~] = legend({'Measurement ( original )','Measurement ( processed )','Focus Region',sprintf('Best Fit with 1 Sigma Deviation ( Order: %d, GOF: %0.2f %s)',order(modelSYS),gof_tempo,'%')},'Location','Best');
                else
                    [lgnd, hobj, ~, ~] = legend({'Measurement ( original )','Measurement ( processed )','Focus Region',sprintf('Best Fit( Order: %d, GOF: %0.2f %s)',order(modelSYS),gof_tempo,'%')},'Location','Best');
                end
                
                % modify current best plot line style
                aX = findall(gcf,'type','line');
                aX(4).LineStyle='--';
                aX(12).LineStyle='--';
                aX(4).LineWidth=4;
                aX(12).LineWidth=4;
                
                % Set legend color
                if ~isempty(modelSYS.UserData)
                    % set bestfit legend color
                    hobj(11).Color = [0.466,0.674,0.188];
                end
                
                
            else
                [lgnd, hobj, ~, ~] = legend({'Measurement ( original )','Measurement ( processed )','Focus Region','Best Fit',sprintf('Modeled Response ( Order: %d, GOF: %0.2f %s)',order(modelSYS),gof_tempo,'%')},'Location','Best');
                
                % modify current best plot line style
                aX = findall(gcf,'type','line');
                aX(6).LineStyle='--';
                aX(16).LineStyle='--';
                aX(6).LineWidth=4;
                aX(16).LineWidth=4;
                
                % Set legend color
                if ~isempty(modelSYS.UserData)
                    % set bestfit legend color
                    hobj(11).Color = [0.466,0.674,0.188];
                end
                
            end
            
            
            
            lgnd.BoxFace.ColorType='truecoloralpha';
            lgnd.BoxFace.ColorData=uint8(255*[1 1 1 0.45]');
            lgnd.Box='off';
            
            % Set Axis Color
            AXES = findall(gcf,'type','axes');
            set(AXES(2),'color',[1,1,1]*0.9,'xminorgrid','off','xminorgrid','off');
            set(AXES(3),'color',[1,1,1]*0.9,'xminorgrid','off','yminorgrid','off');
            
            if ~isempty(modelSYS.UserData)
                hold on
                bodeplot(rsample(modelSYS,20)); %bodeplot(rsample(modelSYS,20),'c');
                hold off
                aX2 = findall(gcf,'type','line');
                %hard-coded:uncertainity analysis
                LineNumbers =  [2:2:40,54:2:90];
                for iou = LineNumbers
                    aX2(iou).LineWidth=0.1;
                    aX2(iou).LineStyle='--';
                    aX2(iou).Color = [110,163,163,100]/255;%paled aqua-marine
                end
                
                %update best fit line (hard-coded)
                aX2(44).LineStyle='-';
                aX2(44).LineWidth=2;
                aX2(44).Color = [0.466,0.674,0.188];
                aX2(92).LineStyle='-';
                aX2(92).LineWidth=2;
                aX2(92).Color = [0.466,0.674,0.188];
                
                % update legend (not working)
                lgnd.String = [lgnd.String, '1 Sigma Deviation'];
            end
        else
            [~,temp_p_2] = zpkdata(modelSYS_best_reducedOrder,'v');
            orderReducedToggle = length(temp_p_2) < length(temp_p);
            
            if orderReducedToggle == 1
                
                
                BD = bodeplot(SYS_orig,SYS,trunSYS,modelSYS,modelSYS_best_reducedOrder,BO);
                [~,gof_tempo] = compareSYS(trunSYS,modelSYS);
                [~,gof_tempo_reducedOrder] = compareSYS(trunSYS,modelSYS_best_reducedOrder);
                [lgnd, hobj, ~, ~] = legend({'Measurement ( original )','Measurement ( processed )','Focus Region',sprintf('Modeled Response ( Order: %d, GOF: %0.2f %s)',order(modelSYS),gof_tempo,'%'), sprintf('Modeled Response ( Reduced Order: %d, GOF: %0.2f %s )',order(modelSYS_best_reducedOrder),gof_tempo_reducedOrder,'%')},'Location','Best');
                % modify reducedOrder line style
                aX = findall(gcf,'type','line');
                aX(4).LineStyle='--';
                aX(14).LineStyle='--';
                
                % set ylim to within the original levels defined by SYS_orig
                YLIM = getoptions(BD,'YLim');
                [SS,LL] = bounds(abs(squeeze(SYS_orig.ResponseData)));
                YLIM(1)= {mag2db([SS,LL]) + [-5,+5]};   % mag2db with some margin
                YLIM(2)= {[-180,180]};
                setoptions(BD,'YLim',YLIM)
                
                lgnd.BoxFace.ColorType='truecoloralpha';
                lgnd.BoxFace.ColorData=uint8(255*[1 1 1 0.45]');
                lgnd.Box='off';
                
            else
                BD = bodeplot(SYS_orig,SYS,trunSYS,modelSYS,BO);
                [~,gof_tempo] = compareSYS(trunSYS,modelSYS);
                % set ylim to within the original levels defined by SYS_orig
                YLIM = getoptions(BD,'YLim');
                [SS,LL] = bounds(abs(squeeze(SYS_orig.ResponseData)));
                YLIM(1)= {mag2db([SS,LL]) + [-5,+5]};   % mag2db with some margin
                YLIM(2)= {[-180,180]};
                setoptions(BD,'YLim',YLIM)
                [lgnd, hobj, ~, ~] = legend({'Measurement ( original )','Measurement ( processed )','Focus Region',sprintf('Modeled Response ( Order: %d, GOF: %0.2f %s)',order(modelSYS),gof_tempo,'%')},'Location','Best');
                % modify reducedOrder line style
                aX = findall(gcf,'type','line');
                aX(4).LineStyle='--';
                aX(12).LineStyle='--';
                
                lgnd.BoxFace.ColorType='truecoloralpha';
                lgnd.BoxFace.ColorData=uint8(255*[1 1 1 0.45]');
                lgnd.Box='off';
                
                
                % Set Axis Color
                AXES = findall(gcf,'type','axes');
                set(AXES(2),'color',[1,1,1]*0.9,'xminorgrid','off','xminorgrid','off');
                set(AXES(3),'color',[1,1,1]*0.9,'xminorgrid','off','yminorgrid','off');
                
                if ~isempty(modelSYS.UserData)
                    hold on
                    bodeplot(rsample(modelSYS,20));
                    hold off
                    aX2 = findall(gcf,'type','line');
                    %hard-coded:uncertainity analysis
                    LineNumbers =  [2:2:42,54:2:90];
                    for iou = LineNumbers
                        aX2(iou).LineWidth=0.1;
                        aX2(iou).LineStyle='--';
                        aX2(iou).Color = [110,163,163,100]/255;%paled aqua-marine
                    end
                    
                    
                    %update best fit line (hard-coded)
                    aX2(44).LineStyle='-';
                    aX2(44).LineWidth=2;
                    aX2(44).Color = [0.466,0.674,0.188];
                    aX2(92).LineStyle='-';
                    aX2(92).LineWidth=2;
                    aX2(92).Color = [0.466,0.674,0.188];
                    
                    % update legend (not working)
                    lgnd.String = [lgnd.String, '1 Sigma Deviation'];
                end
            end
            
            
        end
        set(findall(gcf,'-property','FontSize'),'FontSize',15)
        set(findall(gcf,'type','line'),'linewidth',2)
        
        
        
        % Add ToolbarExplorationButtons (for versions >= R2018b)
        try
            if datetime(version('-date')) > datetime('05-Aug-2018')
                addToolbarExplorationButtons(gcf)
            end
        catch
        end
        % change x-label location a bit!
        %     vec_pos = get(get(gca, 'XLabel'), 'Position');
        %     set(get(gca, 'XLabel'), 'Position', vec_pos + [ -2.5 0 0]);
        xlh  = get(gca, 'XLabel');
        xlh.Position(1) = xlh.Position(1) - abs(xlh.Position(1) * 0.5);
        
        
        % Change Legend linewidth
        hl = findobj(hobj,'type','line');
        set(hl,'LineWidth',2);
        ht = findobj(hobj,'type','text');
        set(ht,'FontSize',12);
        
        
        if DISPLAY_ZPK == 1
            % Create String for showing ZPK parameters
            if isfield(FIT,'ZPK')
                ZPK = FIT.ZPK;
                finalIODelay = FIT.IODelay;
                if isempty(ZPK.z)
                    Str = ["Full Order" "P" string(ZPK.p)' "K" num2str(ZPK.k,'%g') "Delay" num2str(finalIODelay,'%g')];
                else
                    Str = ["Full Order" "Z" string(ZPK.z)' "P" string(ZPK.p)' "K" num2str(ZPK.k,'%g') "Delay" num2str(finalIODelay,'%g')];
                end
                
                % Add Reduced Order
                if isfield(FIT,'ZPK_Reduced_Order')
                    ZPK = FIT.ZPK_Reduced_Order;
                    finalIODelay = FIT.IODelay;
                    if isempty(ZPK.z)
                        Str = [Str " " " " "Reduced Order" "P" string(ZPK.p)' "K" num2str(ZPK.k,'%g') "Delay" num2str(finalIODelay,'%g')];
                    else
                        Str = [Str " " " " "Reduced Order" "Z" string(ZPK.z)' "P" string(ZPK.p)' "K" num2str(ZPK.k,'%g') "Delay" num2str(finalIODelay,'%g')];
                    end
                end
                
            elseif isfield(FIT,'intermediate')
                ZPK = FIT.intermediate(end).ZPK;
                intmIODelay = FIT.intermediate(end).IODelay;
                %ZPK.z = round(ZPK.z,4);
                %ZPK.p = round(ZPK.p,4);
                %ZPK.k = round(ZPK.k,4);
                
                if isempty(ZPK.z)
                    Str = ["Full Order" "P" string(ZPK.p)' "K" num2str(ZPK.k,'%g') "Delay" num2str(intmIODelay,'%g')];
                else
                    Str = ["Full Order" "Z" string(ZPK.z)' "P" string(ZPK.p)' "K" num2str(ZPK.k,'%g') "Delay" num2str(intmIODelay,'%g')];
                end
            else
                fprintf('Plotting error. Try setting "DISPLAY_ZPK" to 0. Existing. \n')
                return;
            end
            
            %FUTURE_ADDITION (INCLUDE UNCERTAINITY IN PLOTS)
            %             if ESTIMATE_UNCERTAINITY == 1
            %                 un = squeeze(real((FIT.ZPK.zcov).^0.5)); un = un(1,:); un = round(un,3);
            %                 zun = un;
            %                 un = squeeze(real((FIT.ZPK.pcov.^0.5))); un = un(1,:); un = round(un,3);
            %                 pun = un;
            %             end
            
            
            % Add ZPK text annotation to plot
            delete(findall(gcf,'type','annotation'));
            txtAnno = annotation('textbox');
            txtAnno.String = Str;
            txtAnno.FontSize = 8;
            txtAnno.FontWeight = 'normal';
            txtAnno.LineStyle = 'None';
            txtAnno.Position = [0.905 0.905 0.16  -0.23];
            %txtAnno.BackgroundColor = [1 1 1]*0.9;
            drawnow;
        end
        
        %Code to display image preview inside the App
        if MATLAB_APP_TOGGLE == 1
            figure(FIG_GCF);
            saveas(FIG_GCF,'temp.png');
            IMG = imread('temp.png');
            imshow(IMG,'Parent',APP.UIAxes);
            figure(APP.UIFigure);
            % retain the final result figure
            if ~isfield(FIT,'ZPK')
             delete(FIG_GCF);
            end
        end
        
    end



    function [residual,GOF] = compareSYS(observedSYS,modelSYS)
        % Get MAG & PHS of measured system
        [MAG_o,PHS_o,W_o] = bode(observedSYS);
        MAG_o = squeeze(MAG_o);
        PHS_o = squeeze(PHS_o);
        
        % Get MAG & PHS of modeled system
        [MAG_m,PHS_m] = bode(modelSYS,W_o);
        MAG_m = squeeze(MAG_m);
        PHS_m = squeeze(PHS_m);
        
        
        % Goodness of fit btw measured & modeled response
        compareArray = @(x,y) norm(x - y)./norm(x - mean(x));
        
        % Overall Residual
        [~,gof0,~] = compare(observedSYS,modelSYS);
        residual_frd = 1 - (gof0/100);
        
        % Magnitude Residual
        residual_mag = compareArray(log10(MAG_o),log10(MAG_m));
        % Phase Residual
        residual_phs = compareArray(wrapTo180(PHS_o),wrapTo180(PHS_m));
        % Slightly more weightage to Phase
        residual = 0.0*residual_frd + 0.5*residual_mag + 0.5*residual_phs;
        
        GOF = 100*(1 - residual);
    end

    function nxx = dv_nfest(xx, bw, ol)
        % DV_NFEST make a noise-floor estimate of an input spectrum.
        % M Hewitson 17-08-06
        %
        % $Id$
        %
        N   = length(xx);
        nxx = zeros(size(xx));
        for j=1:N
            % Determine the interval we are looking in
            hbw = floor(bw/2);
            interval = j-hbw:j+hbw;
            %   idx = find(interval<=0);
            interval(interval<=0)=1;
            %   idx = find(interval>N);
            interval(interval>N)=N;
            % calculate median value of interval
            % after throwing away outliers
            trial_NFE = sort(xx(interval));
            b = floor(ol*length(trial_NFE));
            nxx(j) = median(trial_NFE(1:b));
        end
    end

% function to get standard deviation from zpkdata covariance matrix
    function ZP_sigma =  unpack_zpk_covariance_matrix(ZP,ZPcov)
        if ~isempty(ZPcov) && ~isempty(ZP)
            if isa(ZP,'cell')
                ZP = cell2mat(ZP);
            end
            if isa(ZPcov,'cell')
                ZPcov = cell2mat(ZPcov);
            end
            ZP_sigma = zeros(size(ZP));
            ZP_sigma_tensor = sqrt(ZPcov);
            for iop = 1:size(ZPcov,3)
                zmat_temp = ZP_sigma_tensor(:,:,iop);
                ZPdiag = diag(zmat_temp);
                ZP_sigma(iop) = ZPdiag(1);
            end
        else
            ZP_sigma = [];
        end
    end



    function preview_bodeplot(BO,FIG_HANDLE,SYS_orig,SYS_processed,APP)
        FIG_GCF = figure(FIG_HANDLE,'Visible',0);

        BD = bodeplot(SYS_orig,SYS_processed,BO);
        % set ylim to within the original levels defined by SYS_orig
        YLIM = getoptions(BD,'YLim');
        [SS,LL] = bounds(abs(squeeze(SYS_orig.ResponseData)));
        YLIM(1)= {mag2db([SS,LL]) + [-5,+5]};   % mag2db with some margin
        YLIM(2)= {[-180,180]};
        XLIM = [max(min(SYS_orig.Frequency),APP.F_INITIALEditField.Value) min(max(SYS_orig.Frequency),APP.F_FINALEditField.Value)];
        setoptions(BD,'YLim',YLIM)
        try setoptions(BD,'XLim',XLIM);catch;end
        set(findall(gcf,'-property','FontSize'),'FontSize',15)
        set(findall(gcf,'type','line'),'linewidth',2)
        
        % Add ToolbarExplorationButtons (for versions >= R2018b)
        try
            if datetime(version('-date')) > datetime('05-Aug-2018')
                addToolbarExplorationButtons(gcf)
            end
        catch
        end
        % change x-label location a bit!
        %     vec_pos = get(get(gca, 'XLabel'), 'Position');
        %     set(get(gca, 'XLabel'), 'Position', vec_pos + [ -2.5 0 0]);
        xlh  = get(gca, 'XLabel');
        xlh.Position(1) = xlh.Position(1) - abs(xlh.Position(1) * 0.5);
        
        %[lgnd, hobj, ~, ~] = legend({'Measurement ( original )','Measurement ( processed )','Focus Region',sprintf('Modeled Response ( Order: %d, GOF: %0.2f %s)',order(modelSYS),gof_tempo,'%')},'Location','Best');
        [~, hobj, ~, ~] = legend({'Measurement ( original )','Measurement ( processed )'},'Location','Best');
        
        % Change Legend linewidth
        hl = findobj(hobj,'type','line');
        set(hl,'LineWidth',2);
        ht = findobj(hobj,'type','text');
        set(ht,'FontSize',12);
        
        figure(FIG_GCF);
        %set(gcf,'XLIM',XLIM);
        exportgraphics(FIG_GCF,'temp.png');
        delete(FIG_GCF)
        IMG = imread('temp.png');
        imshow(IMG,'Parent',APP.UIAxes);
        figure(APP.UIFigure);
        
        %Code to display image preview inside the App
        %saveas(FIG_GCF,'temp.png');
        %IMG = imread('temp.png');
        %imshow(IMG,'Parent',APP.UIAxes);
        %imh = getframe(gca(FIG_GCF));
        %imshow(imh.cdata,'Parent',APP.UIAxes);
        %haX = findobj(FIG_GCF,'type','axes');
        %copyobj(haX,APP.UIAxes);
    end



end





