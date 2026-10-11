%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% fitTF.m — RIFF v4.1 (package version 4.1.0), MATLAB R2026b+
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
%    QUERY SHARED FITTING DEFAULTS:
%       defaults = fitTF('defaults');  % No fitting, plotting, or app required
%       Returns ROUTINE, AAA_BACKEND and ESTIMATE_UNCERTAINITY.
%       The current release targets MATLAB R2026b. Use the earlier major
%       RIFF release for MATLAB R2023b.
%
%    INSPECT / IMPORT COLUMNS (without fitting or opening graphics):
%       info = fitTF('inspect',source); % File, table, or numeric matrix
%       data = fitTF('import',source);  % Infer clear headers and units
%       data = fitTF('import',source,map); % Explicit column mapping
%       map fields: Frequency, Real, Imaginary, Response, Magnitude, Phase,
%       Weight, Coherence (column name or one-based index; 0 means unused).
%       ResponseType: 'real-imag', 'complex', or 'mag-phase'.
%       Units: FrequencyUnit ('Hz'/'rad/s'), MagnitudeUnit ('linear'/'dB'),
%       PhaseUnit ('deg'/'rad'). UseCoherence defaults to true.
%       Generic/ambiguous headers and unnamed columns need explicit mapping.
%       Outputs: F (Hz), TF, Weight, Coherence, EffectiveWeight, ColumnMap,
%       HasWeights, Source, Rows (original rows retained in sorted order),
%       SourceRowCount, DroppedDCRows. Frequency/response must be finite;
%       positive frequencies must be distinct. Zero-Hz rows are removed.
%       EffectiveWeight = Weight .* Coherence (absent factors are ones).
%       Coherence must be 0–1; weights must be finite and nonnegative.
%       At least one effective weight must be positive. Set UseCoherence
%       false to retain coherence without using it as a fit weight.
%       In the app: Input > TextFile > Map columns. Mappings last for the
%       app session, are keyed by file, and use column names after Apply.
%
%    COMBINE MEASUREMENTS (without running a fit):
%       data = fitTF('combine',files,dF); % SDF paths; dF in Hz (default .25)
%       data = fitTF('combine',sets,dF);  % Struct array: F (Hz), TF (complex)
%       Outputs: F, TF, FRD, Measurements, BodeOptions, Coverage.
%       Duplicate frequencies and overlaps are averaged in complex form.
%       Samples outside measured bands are omitted. Input order is arbitrary.
%       Optional BO and plotToggle follow dF; plotting defaults to false.
%
%    VERIFY AND MANUAL ADJUSTMENT (same core as the app):
%       fitTF('verify',FIT,index);    % Standalone plot; 0 = best, 1..N = trial
%       lines = fitTF('parameters',model,label); % label defaults to 'Model'
%       editor = fitTF('edit',FIT);   % Independent session, no graphics
%       editor = fitTF('edit',FIT,'Interactive',true); % Live editor window
%       editor.selectFit(index);     % Separate draft for each fit
%       editor.moveRoot('pole',1,-0.6+2.5i); % Or 'zero'; preserves conjugates
%       editor.setGain(3);
%       model = editor.getModel();   % Current zpk model
%       state = editor.getState();   % Selection, GOF and modification status
%       editedFIT = editor.exportFit(); % Original FIT stays unchanged
%       editor.saveToFile('manual.mat'); % Writes variable FIT to chosen file
%       name = editor.exportWorkspace(); % New, unique workspace variable
%       editor.resetFit();           % Restore selected fit only
%       editor.close();              % Release this session and its window
%       Options: 'EnforceStability',true; 'EnforceMinimumPhase',false;
%       'Interactive',false; 'Visible','on' (use 'off' to hide the window).
%       Logical constraint options apply to subsequent root moves. Change
%       them later using editor.setConstraints(stable,minimumPhase).
%       Save editedFIT, not the live editor with its callbacks/UI handles.
%       GUI callbacks use fitTF('verify',app,FIT) for workspace selection.
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
%        'auto' detects clear headers/units and optional weight/coherence.
%        "COLUMN_MAP",map overrides detection (also enables mapped import).
%        For mapped files, extra CUSTOM_WEIGHT/COHERENCE vectors refer to
%        the original file rows, before sorting and removal of zero Hz.
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
%       "COHERENCE"     Numeric vector in [0,1], aligned with input samples.
%       "USE_COHERENCE" [Default=true] Use supplied coherence for fitting.
%       Supplied weights multiply with coherence and take precedence over
%       FIT_WEIGHT_FROM_PHASE_SMOOTHNESS. They follow all row/grid changes.
%       FIT.weighting stores original/processed frequency-weight pairs;
%       FIT.input.Import preserves mapped-file provenance and coherence.
%       "USE_PARALLEL"  [ Default = 0           ] Use Parallel Pool for optimization speedup
%       "ATTAIN_GOF"    [ Default = 0           ] Set this to 1 to attan a desired GOF (set MAX_POLES to a low value (say 2) with higher NUM_TRIALS )
%       "DESIRED_GOF"   [ Default = 50          ] Desired goodness of fit (in %), activated when ATTAIN_GOF = 1
%  "POLE_UPDATE_TRIAL"  [     Default = 5       ] Increase MAX_POLE every Nth Trial (Used when ATTAIN_GOF = 1 )
%     "FIT_NOISE_FLOOR" [     Default = 0       ] Fit transfer function noise floor
%        "ROUTINE"      [ Default = [2 5] ] 1=rationalfit, 2=tfest, 3=invfreqs, 4=fitmagfrd, 5=AAA
%       "AAA_BACKEND"   [ Default = "sysid" ] "sysid" or explicit "rf"; "auto" aliases "sysid".
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
%      FIT = fitTF('F',f,'TF',TF); % Default: tfest + SysID AAA
%      FIT = fitTF('F',f,'TF',TF,'ROUTINE',5); % SysID AAA only
%      FIT = fitTF('F',f,'TF',TF,'ROUTINE',[2 5],'PLOT_TOGGLE',0);
%      % Uncertainty/delay requests select tfest; minimum-phase selects fitmagfrd.
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
%    Aug 29, 2023: -> Added Nick Trefethen's AAA algorithm
%                  -> cycles through all fitting routines
%                  -> Uncertainity (only via tfest) not estimated by default
%                  -> Defaults changed: Fmincon->Surrogate, NUM_TRIALS->20
%                   -> try catch added to all FIT_ROUTINES to prevent
%                   errors from any missing toolboxes (if users havenot
%                   installed these already).
%                  -> Added GUI option to select fitting routine 
%                  -> Changed TFEST (and in APP) default NUM_ZEROS to NUM_POLES
% COMPATIBILITY: MATLAB R2026b+
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
%   Implement no right half plane zeros in tfest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[FIT] =  fitTF(varargin)

% Shared estimator defaults, usable by the GUI without starting a fit or
% touching graphics, toolboxes, the path, or the caller's numeric format.
fittingDefaults = struct('ROUTINE',[2 5],'AAA_BACKEND','sysid',...
    'ESTIMATE_UNCERTAINITY',0);
if nargin >= 1 && (ischar(varargin{1}) || (isstring(varargin{1}) && isscalar(varargin{1})))
    switch lower(char(varargin{1}))
        case 'inspect'
            narginchk(2,2);
            FIT = riff_inspect_measurement(varargin{2});
            return
        case 'import'
            narginchk(2,3);
            FIT = riff_import_measurement(varargin{2:end});
            return
        case 'setup-import'
            narginchk(2,2);
            FIT = riff_setup_import(varargin{2});
            return
        case 'import-ui'
            narginchk(2,2);
            FIT = riff_import_dialog(varargin{2});
            return
        case 'combine'
            narginchk(2,5);
            FIT = riff_combine_measurements(varargin{2:end});
            return
        case 'defaults'
            narginchk(1,1);
            FIT = fittingDefaults;
            return
        case 'parameters'
            narginchk(2,3);
            label = 'Model';
            if nargin == 3, label = varargin{3}; end
            FIT = riff_model_parameters(varargin{2},label);
            return
        case 'verify'
            narginchk(2,3);
            if isstruct(varargin{2}) && isfield(varargin{2},'FRD_Model')
                index = 0;
                if nargin == 3, index = varargin{3}; end
                FIT = fitTF('POST_PROCESS_RESULT_VARIABLE',varargin{2},...
                    'VIEW_INTERMEDIATE_BODEPLOT_TOGGLE',1,...
                    'POST_PROCESS_RESULT_INTERMEDIATE_ID',index);
            else
                narginchk(3,3);
                FIT = riff_verify_fit(varargin{2},varargin{3});
            end
            return
        case 'edit'
            narginchk(2,inf);
            FIT = create_model_editor(varargin{2},varargin{3:end});
            return
    end
end

tic;
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('Starting transfer function estimation...')

format long g

% Add local helpers only when needed. Re-adding an installed add-on's
% folder can reorder MATLAB's managed package paths (R2026b).
utilsFolder = fullfile(fileparts(mfilename('fullpath')),'utils');
if ~any(strcmp(strsplit(path,pathsep),utilsFolder))
    addpath(utilsFolder);
end

if isempty(varargin)
    disp('No input arguments provided, check the description given below...')
    eval('help fitTF.m')
    return
end

% Per-fit values shared with the nested objective; never inherit another fit.
cohWeight = [];
NUM_ZEROS = [];

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
ROUTINE = fittingDefaults.ROUTINE; % tfest and System Identification AAA
AAA_BACKEND = fittingDefaults.AAA_BACKEND;
ESTIMATE_UNCERTAINITY = fittingDefaults.ESTIMATE_UNCERTAINITY; % Opt-in covariance estimation
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
COLUMN_MAP = [];
COHERENCE = [];
USE_COHERENCE = true;
importedMeasurement = [];
explicitFrequencyWeights = false;
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
% Variable for post-procressing results from FIT_RESULT
POST_PROCESS_RESULT_VARIABLE = 'FIT_RESULT';
VIEW_INTERMEDIATE_BODEPLOT_TOGGLE = 0;
POST_PROCESS_RESULT_INTERMEDIATE_ID = 1;
%--------------------------------------------------------------------------

% [FIGURE HANDLE OPTIONS]
clear FIG_HANDLE;
% persistent FIG_GCF
FIG_HANDLE.NAME    = 'System Identification';
FIG_HANDLE.UNITS = 'Normalized';
FIG_HANDLE.OUTERPOSITION = [0.04, 0.04, 0.9, 0.9];
FIG_HANDLE.PAPERORIENTATION = 'PORTRAIT';  %  PORTRAIT or LANDSCAPE
% FIG_GCF = figure(FIG_HANDLE,'Visible','off');



% Weight Filter options
WtFilter = ["EQUAL","ABSOLUTE","INVERSE","INVERSE_SQUARE_ROOT","CUSTOM"];

% Fit Routines [Donot change the order]
Routine_Names = ["rationalfit","tfest","invfreqs","fitmagfrd","AAA"];



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
        case {'COLUMN_MAP'}
            COLUMN_MAP = varargin{k+1};
        case {'COHERENCE'}
            COHERENCE = varargin{k+1};
        case {'USE_COHERENCE'}
            USE_COHERENCE = varargin{k+1};
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
        case {'ROUTINE','routine'}
            ROUTINE = varargin{k+1};
        case {'AAA_BACKEND'}
            AAA_BACKEND = varargin{k+1};
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
                cohWeight = varargin{k+1};
            else
                VIDX  = k+1;
            end
            WtMax = 5;
            WtMin = 5;
        case {lower('EXTRA_INFO')}
            EXTRA_INFO = varargin{k+1};
        case {'DESIRED_MODEL_ORDER'}
            DESIRED_MODEL_ORDER = double(varargin{k+1});
        case {'INCLUDE_IODELAY'}
            INCLUDE_IODELAY = varargin{k+1};
        case {'POST_PROCESS_RESULT_VARIABLE'}
            POST_PROCESS_RESULT_VARIABLE = varargin{k+1};
        case {'VIEW_INTERMEDIATE_BODEPLOT_TOGGLE'}
            VIEW_INTERMEDIATE_BODEPLOT_TOGGLE = varargin{k+1}; 
        case {'POST_PROCESS_RESULT_INTERMEDIATE_ID'}
            POST_PROCESS_RESULT_INTERMEDIATE_ID = varargin{k+1};            
    end
end
FIT_RESULT_VARIABLE=[];
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
            elseif contains(class(APP.(FIELDS{ijk})),'CheckBox') && ~contains(class(APP.(FIELDS{ijk})),'CheckBoxTree')
                if ~contains(FIELDS{ijk},'Label')
                    feval(@()assignin('caller', extractBefore(FIELDS{ijk},{'CheckBox'}),APP.(FIELDS{ijk}).Value));
                end
                % Use CheckBoxTree to select fit routines    
            elseif contains(class(APP.(FIELDS{ijk})),'CheckBoxTree')
                    ROUTINE = [];
                    if numel(APP.(FIELDS{ijk}).CheckedNodes) > 0
                        selected_routines_str = string({APP.(FIELDS{ijk}).CheckedNodes(:).Text});
                        selected_routines_str = erase(selected_routines_str,"FITTING_ROUTINES");
                        selected_routines_str = selected_routines_str(selected_routines_str~="");
                        routine_dictionary = dictionary(Routine_Names,[1:numel(Routine_Names)]);
                        % get fit routines based on user selection
                        ROUTINE = routine_dictionary(selected_routines_str);
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





FIG_HANDLE_VISIBILITY_ORIG = FIG_HANDLE_VISIBILITY;
if MATLAB_APP_TOGGLE == 1 && ~VIEW_INTERMEDIATE_BODEPLOT_TOGGLE
    clear_model_editor(APP);
end

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
    autoMap = ~isempty(COLUMN_MAP) || ...
        (exist('FORMAT','var') && any(strcmpi(FORMAT,{'auto','Auto / mapped'})));
    if autoMap
        if isempty(COLUMN_MAP) && MATLAB_APP_TOGGLE == 1
            COLUMN_MAP = riff_saved_import_map(APP,FNAME);
        end
        if ~USE_COHERENCE
            if isempty(COLUMN_MAP),COLUMN_MAP=struct();end
            COLUMN_MAP.UseCoherence=false;
        end
        importedMeasurement = riff_import_measurement(FNAME,COLUMN_MAP);
        f = importedMeasurement.F; TF = importedMeasurement.TF;
    else
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
    combined = riff_combine_measurements(SDF_DATASETS,SDF_DATASET_FREQ_RESO,BO,false);
    TF = combined.TF; f = combined.F;
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
        COHERENCE = mscohere(TS1,TS2,hanning(NFFT),NFFT/2,NFFT,FS);

    end


end

if VIEW_INTERMEDIATE_BODEPLOT_TOGGLE==1
    FIT = POST_PROCESS_RESULT_VARIABLE;
    count = 0;
    if isfield(FIT,'intermediate'), count = numel(FIT.intermediate); end
    index = POST_PROCESS_RESULT_INTERMEDIATE_ID;
    validateattributes(index,{'numeric'},{'scalar','integer','>=',0,'<=',count});
    DISPLAY_ZPK = 1;
    if MATLAB_APP_TOGGLE == 1, FIG_HANDLE_VISIBILITY = 0; end
    BO = FIT.options.BodeOptions;
    displayed = chgFreqUnit(FIT.FRD_Model.measured_original,BO.FreqUnits);
    BO.XLim = [min(displayed.Frequency),max(displayed.Frequency)];
    selectedModel = FIT.FRD_Model.modeled;
    selectedMeasurement = FIT.FRD_Model.truncated;
    if index > 0
        selectedModel = FIT.intermediate(index).FRD_Model.modeled;
        if isfield(FIT.intermediate(index).FRD_Model,'truncated_measurement')
            selectedMeasurement = FIT.intermediate(index).FRD_Model.truncated_measurement;
        end
        BO.Title.String = sprintf('Trial %d of %d | GOF %.2f%% | Best GOF %.2f%%',...
            index,count,FIT.intermediate(index).GOF,FIT.gof);
    else
        BO.Title.String = sprintf('Best fit | GOF %.2f%%',FIT.gof);
    end
    make_plot(BO,FIT.FRD_Model.measured_original,FIT.FRD_Model.measured_smoothed,...
        selectedMeasurement,selectedModel,FIT.FRD_Model.modeled);
    return
end

% Normalize rows together so frequency, response, and supplied weights agree.
f = f(:); TF = TF(:);
if numel(f)~=numel(TF) || numel(f)<2 || ~isreal(f) || ...
        any(~isfinite(f)) || any(f<0)
    error('RIFF:ImportFrequency','Supply matching response/frequency vectors with at least two nonnegative, finite frequencies.');
end
validateattributes(USE_COHERENCE,{'logical','numeric'},{'scalar','binary'});
if ~isempty(importedMeasurement)
    % Extra vectors refer to original file rows, even after sorting/removing DC.
    riff_validate_weights(cohWeight,importedMeasurement.SourceRowCount,'weight');
    riff_validate_weights(COHERENCE,importedMeasurement.SourceRowCount,'coherence');
    if ~isempty(cohWeight),cohWeight=cohWeight(importedMeasurement.Rows);end
    if ~isempty(COHERENCE)
        if ~isempty(importedMeasurement.Coherence)
            error('RIFF:ImportCoherence','Select coherence from the file or supply COHERENCE, not both.');
        end
        COHERENCE=COHERENCE(importedMeasurement.Rows);
    end
else
    riff_validate_weights(cohWeight,numel(f),'weight');
    riff_validate_weights(COHERENCE,numel(f),'coherence');
end
if ~isempty(cohWeight),cohWeight=double(cohWeight(:));end
COHERENCE=double(COHERENCE(:));
coherenceEnabled=logical(USE_COHERENCE);
if ~isempty(importedMeasurement)
    if ~isempty(importedMeasurement.Coherence)
        coherenceEnabled=coherenceEnabled && importedMeasurement.ColumnMap.UseCoherence;
    end
    if importedMeasurement.HasWeights
        if isempty(cohWeight),cohWeight=ones(size(f));end
        cohWeight=cohWeight.*importedMeasurement.EffectiveWeight;
    end
end
if ~isempty(COHERENCE) && USE_COHERENCE
    if isempty(cohWeight),cohWeight=ones(size(f));end
    cohWeight=cohWeight.*COHERENCE;
end
rows=find(f>0);[~,orderRows]=sort(f(rows));rows=rows(orderRows);
if numel(rows)<2 || any(diff(f(rows))<=0)
    error('RIFF:ImportFrequency','Need at least two distinct positive frequencies; remove or combine duplicates.');
end
if numel(rows)<numel(f),fprintf('Zeroth frequency terms removed.\n');end
f=f(rows);TF=TF(rows);
if ~isempty(cohWeight),cohWeight=cohWeight(rows);end
if ~isempty(COHERENCE),COHERENCE=COHERENCE(rows);end

% Expressions remain supported and multiply any supplied file/coherence weights.
if exist('VIDX','var')
    fprintf('Modifying weighting, making use of input argument %d ...\n',VIDX);
    coh_cell = strsplit(varargin{VIDX},',');
    if isempty(cohWeight),cohWeight=ones(size(f));end
    for ijk = 1:numel(coh_cell)
        cohWeight = cohWeight.*eval(coh_cell{ijk});
    end
    riff_validate_weights(cohWeight,numel(f),'weight');
    cohWeight=cohWeight(:);
end
if ~isempty(cohWeight)
    WtMin=5;WtMax=5;explicitFrequencyWeights=true;
end
TF_orig=TF;f_orig=f;
originalWeights=cohWeight;


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
            freq_rs = logspace(log10(min(f)),log10(max(f)),1000);
            freq_rs([1 end]) = f([1 end]);
            if ~isempty(cohWeight)
                cohWeight=interp1(f,cohWeight,freq_rs(:),'linear');
            end
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

if isempty(ROUTINE)
    if PREVIEW_BODEPLOT_TOGGLE
        ROUTINE = fittingDefaults.ROUTINE;
    else
        error('RIFF:NoFitRoutine','Select at least one fitting routine.');
    end
end

% Currently only tfestimate can estimate uncertainity
if ESTIMATE_UNCERTAINITY == 1
    fprintf('Uncertainty estimation requested. FIT_ROUTINE set to tfest. \n')
    ROUTINE = 2;
end


% Currently only tfestimate include un-stable models
if ENFORCE_STABILITY ~= 1
    fprintf('ENFORCE_STABILITY set to 0. FIT_ROUTINE set to tfest. \n')
    ROUTINE = 2;
end

% Added by NM on 28th April 2022
% Switch ROUTINE to fitmagfrd if ENFORCE_MINIMUM_PHASE flag is On
if ENFORCE_MINIMUM_PHASE==1
    fprintf('ENFORCE_MINIMUM_PHASE set to 1. FIT_ROUTINE set to fitfrdmag. \n')
    ROUTINE = 4;
end
% Added by NM on 28th April 2022
if INCLUDE_IODELAY == 1
    fprintf('INCLUDE_IODELAY set to 1. FIT_ROUTINE set to tfest. \n')
    ROUTINE = 2;
end


% Optimize an index into the selected routines, not the numerical ID range.
% For example [2 5] must never run unchecked routines 3 or 4.
validateattributes(ROUTINE,{'numeric'},{'vector','nonempty','integer','>=',1,'<=',5});
ROUTINE = unique(ROUTINE(:)','stable');
if any(ROUTINE == 5) && ~PREVIEW_BODEPLOT_TOGGLE && ~VIEW_INTERMEDIATE_BODEPLOT_TOGGLE
    AAA_BACKEND = riff_aaa_backend(AAA_BACKEND);
    fprintf('AAA backend: %s\n',AAA_BACKEND);
end
lb = [MIN_POLES,F_INITIAL-FREQ_WIN_LOW,F_FINAL-FREQ_WIN_UP, 1,WtMin];
ub = [MAX_POLES,F_INITIAL+FREQ_WIN_LOW,F_FINAL+FREQ_WIN_UP, numel(ROUTINE),WtMax];


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

if FIT_WEIGHT_FROM_PHASE_SMOOTHNESS==1 && ~explicitFrequencyWeights
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
    preview_bodeplot(BO,frd(TF_orig,2*pi*f_orig),frd(TF,2*pi*f),APP);
    FIT=[];

else


    if WtMin == 5 && ~any(cohWeight > 0)
        error('RIFF:AAAWeights','At least one custom frequency weight must be positive.');
    end

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
                % Public GUESS/results use the algorithm ID for compatibility.
                routineIndex = find(ROUTINE == round(GUESS(4)),1);
                if isempty(routineIndex)
                    error('RIFF:GuessRoutine','GUESS specifies an unchecked fitting routine.');
                end
                x0(4) = routineIndex;
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
                outfilename = websave('bads.zip','https://github.com/acerbilab/bads/archive/refs/heads/master.zip');
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
            FIT.intermediate(trial).FRD_Model.truncated_measurement = trunSYS;
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
                trunSYS_best  = trunSYS;
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
                    trunSYS_best  = trunSYS;
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
            FIT.intermediate(trial).FRD_Model.truncated_measurement = trunSYS;
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
                trunSYS_best  = trunSYS;
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
                    trunSYS_best  = trunSYS;
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
                FIT.intermediate(trial).FRD_Model.truncated_measurement = trunSYS;

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
                    trunSYS_best  = trunSYS;
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
                        trunSYS_best  = trunSYS;
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
                FIT.intermediate(trial).FRD_Model.truncated_measurement = trunSYS;
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
                    trunSYS_best  = trunSYS;
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
                        trunSYS_best  = trunSYS;
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
        if exist('FIT','var') && isfield(FIT,'intermediate') && numel(FIT.intermediate) >= trial
            FIT.intermediate(trial).FIT_ROUTINE = Routine_Names(ROUTINE(round(xsur(4))));
            if ROUTINE(round(xsur(4))) == 5
                FIT.intermediate(trial).AAA_BACKEND = AAA_BACKEND;
            end
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



    % Check if atleast one solution was found else return & disp status
    if ~exist('p_best','var')
        fprintf('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n')
        fprintf('Unable to find a solution with the given settings.\n')
        fprintf('Relax some of the specified settings. (Ex. Set INCLUDE_DELAY=0)\n')
        fprintf('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n')
        FIT=[];
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

    FIT.input.Import = importedMeasurement;
    FIT.weighting = struct('Frequency',f,'EffectiveWeight',cohWeight,...
        'OriginalFrequency',f_orig,'OriginalWeight',originalWeights,...
        'Coherence',COHERENCE,'UseCoherence',coherenceEnabled,...
        'SuppliedWeights',explicitFrequencyWeights);
    FIT.frequency.measured = f_orig;
    FIT.frequency.truncated = ff_trun;

    FIT.transferFunction.measured = TF_orig;
    FIT.transferFunction.measured_smoothed = TF;
    FIT.transferFunction.truncated = TF_trun;

    FIT.FRD_Model.measured_original = SYS_orig;
    FIT.FRD_Model.measured_smoothed = SYS;
    FIT.FRD_Model.truncated         = trunSYS_best;
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
    FIT.options.ESTIMATE_UNCERTAINITY = ESTIMATE_UNCERTAINITY;
    FIT.options.SMOOTH_LEVEL = SMOOTH_LEVEL;
    FIT.options.Optimization.OPTIMIZER = OPTIMIZER;
    FIT.options.Optimization.options = opts;
    FIT.options.Optimization.lb = lb;
    FIT.options.Optimization.ub = ub;
    FIT.options.Optimization.SELECTED_ROUTINES = ROUTINE;
    FIT.options.Optimization.lb(4) = min(ROUTINE);
    FIT.options.Optimization.ub(4) = max(ROUTINE);
    FIT.options.Optimization.startingPoints = x0_best;
    FIT.options.Optimization.startingPoints(4) = ROUTINE(round(x0_best(4)));
    FIT.options.Optimization.NUM_TRIALS  = NUM_TRIALS;
    FIT.options.Optimization.BEST_TRIAL  = best_trial;
    FIT.options.Optimization.results    = xsur_best;
    FIT.options.Optimization.results(4) = ROUTINE(round(xsur_best(4)));
    FIT.options.Optimization.Num_Poles  = round(xsur_best(1));
    FIT.options.Optimization.F_Start    = xsur_best(2);
    FIT.options.Optimization.F_Stop     = xsur_best(3);
    FIT.options.Optimization.FINAL_FIT_ROUTINE = Routine_Names(ROUTINE(round(xsur_best(4))));
    if ROUTINE(round(xsur_best(4))) == 5
        FIT.options.Optimization.AAA_BACKEND = AAA_BACKEND;
    end
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
            FIG_GCF = make_plot(BO,SYS_orig,SYS,trunSYS_best,modelSYS_best,modelSYS_best,modelSYS_best_reducedOrder);
        else
            FIG_GCF = make_plot(BO,SYS_orig,SYS,trunSYS_best,modelSYS_best,modelSYS_best);
        end

        if SAVE_TOGGLE
            if MATLAB_APP_TOGGLE == 1 && ~verLessThan('matlab','24.2') && ~FIG_HANDLE_VISIBILITY
                exportCleanup = onCleanup(@() delete(FIG_GCF));
            end

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
            savefig(FIG_GCF,figName)

            % Use exportgraphics function (if available)
            if exist('exportgraphics','file') == 6
                exportgraphics(FIG_GCF,imageName);
            else
                saveas(FIG_GCF,imageName)
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
        warningState = warning;
        warningCleanup = onCleanup(@() warning(warningState));
        warning('off','all');

        NUM_POLES = round(Params(1));
        F_INITIAL0 = Params(2);
        F_FINAL0   = Params(3);
        FIT_ROUTINE = ROUTINE(max(1,min(numel(ROUTINE),round(Params(4)))));
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

        %fprintf("Using FIT_ROUTINE: %s\n",Routine_Names(FIT_ROUTINE))


        if FIT_ROUTINE == 1

            % Fit a rational function (Vector Fitting)
            try
            fit  =  rationalfit(ff_trun0,TF_trun0,'Npoles',NUM_POLES,'Weight',Wt);
            [b,a] = residue (fit.C,fit.A,fit.D);
            modelSYS = tf(real (b),a);
            catch myExp1
                % set to random stable TF in case to errors
                disp(getReport(myExp1))
                modelSYS =  tf([1 1],[1 1 1]);
            end

        elseif FIT_ROUTINE == 2

            if INCLUDE_IODELAY == 1
                iodelay_flag = NaN;
            else
                iodelay_flag = [];
            end

            % Fit using tfest
            try
            if isempty(NUM_ZEROS)
                modelSYS = tfest(trunSYS0,NUM_POLES,NUM_POLES,iodelay_flag,tfestOpt);
            else
                % Use min(NUM_POLES,NUM_ZEROS) for NUM_ZEROS
                modelSYS = tfest(trunSYS0,NUM_POLES,min(NUM_POLES,NUM_ZEROS),iodelay_flag,tfestOpt);
            end
            catch myExp2
                % set to random stable TF in case to errors
                disp(getReport(myExp2))
                modelSYS =  tf([1 1],[1 1 1]);
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
            try 
            [b,a] = invfreqs(TF_trun0,ff_trun0*2*pi,NUM_POLES,NUM_POLES,Wt,1e3,1e-11);
            modelSYS = tf(real (b),a);
             catch myExp3
                % set to random stable TF in case to errors
                disp(getReport(myExp3))
                modelSYS =  tf([1 1],[1 1 1]);
            end

        elseif FIT_ROUTINE == 4

            % Fit using fitmagfrd
            %   minimum-phase state-space model using log-Chebyshev magnitude design
            try
                if explicitFrequencyWeights
                    modelSYS = fitmagfrd(trunSYS0,NUM_POLES,[],frd(Wt,2*pi*ff_trun0));
                else
                    modelSYS = fitmagfrd(trunSYS0,NUM_POLES);
                end
            catch myExp4
                % set to random stable TF in case to errors
                disp(getReport(myExp4))
                modelSYS =  tf([1 1],[1 1 1]);
            end


        elseif FIT_ROUTINE == 5

            try
                modelSYS = riff_fit_aaa(ff_trun0,TF_trun0,NUM_POLES,Wt,...
                    ENFORCE_STABILITY,AAA_BACKEND);
                % RIFF stores pole/zero models; idss has no IODelay property.
                modelSYS = zpk(modelSYS);
            catch fitError
                % Penalize failed optimizer probes; never accept a dummy model.
                % If the chosen final candidate failed, expose the real error.
                if nargout > 1, rethrow(fitError); end
                residual = Inf;
                return
            end

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



    function FIG_GCF = make_plot(BO,SYS_orig,SYS,trunSYS,modelSYS,modelSYS_best,modelSYS_best_reducedOrder)

        [~,gof_tempo] = compareSYS(trunSYS,modelSYS);
        systems = {SYS_orig,SYS,trunSYS};
        labels = {'Measurement ( original )','Measurement ( processed )','Focus Region'};
        lineSpecs = {'-','-','-'};
        orderReducedToggle = nargin == 7 && ...
            order(modelSYS_best_reducedOrder) < order(modelSYS);

        if orderReducedToggle
            [~,gof_reduced] = compareSYS(trunSYS,modelSYS_best_reducedOrder);
            systems = [systems,{modelSYS,modelSYS_best_reducedOrder}];
            labels = [labels,{...
                sprintf('Modeled Response ( Order: %d, GOF: %0.2f %%)',order(modelSYS),gof_tempo),...
                sprintf('Reduced Order: %d, GOF: %0.2f %%',order(modelSYS_best_reducedOrder),gof_reduced)}];
            lineSpecs = [lineSpecs,{'-','g--'}];
        elseif isequal(modelSYS,modelSYS_best) || nargin == 7
            systems{end+1} = modelSYS;
            labels{end+1} = sprintf('Best Fit ( Order: %d, GOF: %0.2f %%)',order(modelSYS),gof_tempo);
            lineSpecs{end+1} = 'm--';
        else
            systems = [systems,{modelSYS_best,modelSYS}];
            labels = [labels,{'Best Fit',...
                sprintf('Modeled Response ( Order: %d, GOF: %0.2f %%)',order(modelSYS),gof_tempo)}];
            lineSpecs = [lineSpecs,{'m--','-'}];
        end

        % UserData can contain arbitrary metadata. Only sample identified
        % models that actually have a parameter covariance estimate.
        hasUncertainty = isa(modelSYS,'idmodel') && ~isempty(getcov(modelSYS));
        if hasUncertainty && ~orderReducedToggle
            systems{end+1} = rsample(modelSYS,20);
            labels{end+1} = 'Parameter uncertainty samples';
            lineSpecs{end+1} = 'c:';
        end
        % Native charts are supported inside App Designer from R2024b.
        % Make a separate figure only for the requested window or final export.
        embedded = MATLAB_APP_TOGGLE == 1 && ~verLessThan('matlab','24.2');
        FIG_GCF = [];
        charts = {};
        Str = strings(1,0);
        extraParameters = strings(0,1);

        selectedIndex = 0;
        selectedLabel = 'Best fit';
        if VIEW_INTERMEDIATE_BODEPLOT_TOGGLE && POST_PROCESS_RESULT_INTERMEDIATE_ID > 0
            selectedIndex = POST_PROCESS_RESULT_INTERMEDIATE_ID;
            selectedLabel = sprintf('Trial %d',selectedIndex);
        elseif ~isfield(FIT,'ZPK') && isfield(FIT,'intermediate')
            selectedLabel = sprintf('Trial %d',numel(FIT.intermediate));
        end
        if DISPLAY_ZPK == 1
            Str = riff_model_parameters(modelSYS,selectedLabel);
            if orderReducedToggle
                extraParameters = [""; riff_model_parameters(modelSYS_best_reducedOrder,'Reduced order')];
                Str = [Str; extraParameters];
            end
        end

        if embedded
            plotParent = app_bode_container(APP,Str);
            [~,BD] = create_bodeplot(BO,systems,labels,lineSpecs,0,plotParent);
            charts{end+1} = BD;
            if isfield(FIT,'ZPK')
                editor = getappdata(APP.UIFigure,'RIFFModelEditor');
                if isempty(editor) || ~isstruct(editor) || ~editor.isValid() || ~editor.matchesFit(FIT)
                    clear_model_editor(APP);
                    editor = create_model_editor(FIT,'App',APP,'Tabs',plotParent.Parent);
                    setappdata(APP.UIFigure,'RIFFModelEditor',editor);
                end
                parameterText = findobj(plotParent.Parent,'Tag','RIFFParameterText');
                editor.bind(BD,selectedIndex,parameterText,extraParameters);
            end
        end
        if ~embedded || FIG_HANDLE_VISIBILITY || (nargout > 0 && SAVE_TOGGLE)
            [FIG_GCF,BD] = create_bodeplot(BO,systems,labels,lineSpecs,FIG_HANDLE_VISIBILITY);
            charts{end+1} = BD;
            if ~isempty(Str)
                txtAnno = annotation(FIG_GCF,'textbox');
                txtAnno.String = Str;
                txtAnno.FontSize = 8;
                txtAnno.FontWeight = 'normal';
                txtAnno.LineStyle = 'None';
                txtAnno.Position = [0.84 0.65 0.15 0.25];
            end
        end
        for chartIndex = 1:numel(charts)
            BD = charts{chartIndex};
            if hasUncertainty && ~orderReducedToggle && isa(BD,'controllib.chart.BodePlot')
                BD.Responses(numel(systems)).LineWidth = 0.5;
                BD.Responses(numel(systems)).Color = [110,163,163]/255;
            end
        end
        if MATLAB_APP_TOGGLE == 1 && ~embedded
            display_app_plot(FIG_GCF,APP);
            if ~isfield(FIT,'ZPK')
                delete(FIG_GCF);
            end
        end
        drawnow;

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



    function preview_bodeplot(BO,SYS_orig,SYS_processed,APP)
        embedded = ~verLessThan('matlab','24.2');
        systems = {SYS_orig,SYS_processed};
        labels = {'Measurement ( original )','Measurement ( processed )'};
        lineSpecs = {'-','-'};
        charts = {};
        if embedded
            plotParent = app_bode_container(APP,strings(1,0));
            [~,BD] = create_bodeplot(BO,systems,labels,lineSpecs,0,plotParent);
            charts{end+1} = BD;
        end
        if ~embedded || FIG_HANDLE_VISIBILITY
            [FIG_GCF,BD] = create_bodeplot(BO,systems,labels,lineSpecs,FIG_HANDLE_VISIBILITY);
            charts{end+1} = BD;
        end

        % App frequency fields are in Hz; FRD frequency data are in rad/s.
        % Convert both to the displayed units before applying plot limits.
        displayedSYS = chgFreqUnit(SYS_orig,BO.FreqUnits);
        unitFrequency = chgFreqUnit(frd(1,1,'FrequencyUnit','Hz'),BO.FreqUnits);
        requestedRange = [APP.F_INITIALEditField.Value,APP.F_FINALEditField.Value]...
            * unitFrequency.Frequency;
        xLimits = [max(min(displayedSYS.Frequency),min(requestedRange)),...
            min(max(displayedSYS.Frequency),max(requestedRange))];
        if all(isfinite(xLimits)) && xLimits(1) > 0 && xLimits(1) < xLimits(2)
            for chartIndex = 1:numel(charts)
                setoptions(charts{chartIndex},'XLim',xLimits);
            end
        end
        if ~embedded
            display_app_plot(FIG_GCF,APP);
            if ~FIG_HANDLE_VISIBILITY
                delete(FIG_GCF);
            end
        end
        drawnow;
    end

    function [fig,BD] = create_bodeplot(BO,systems,labels,lineSpecs,visibility,plotParent)
        % LineSpec and BodeOptions work with both the legacy response plots
        % (R2023b) and the chart objects introduced in R2024b. Never index
        % hidden graphics children or move chart labels through gca.
        fig = [];
        embedded = nargin == 6;
        fontSize = 15;
        if embedded
            fontSize = 12;
        else
            fig = figure(FIG_HANDLE,'Visible',visibility);
            if ~verLessThan('matlab','24.2')
                plotParent = fig;
            else
                plotParent = axes('Parent',fig);
            end
        end
        BO.Title.FontSize = fontSize;
        BO.XLabel.FontSize = fontSize;
        BO.YLabel.FontSize = fontSize;
        BO.TickLabel.FontSize = fontSize;
        args = {};
        for systemIndex = 1:numel(systems)
            args{end+1} = systems{systemIndex};
            % A bare '-' resets every legacy response to blue. Omit it so
            % measurements retain their automatic, distinct colors.
            if ~strcmp(lineSpecs{systemIndex},'-')
                args{end+1} = lineSpecs{systemIndex};
            end
        end
        BD = bodeplot(plotParent,args{:},BO);

        magnitude = abs(systems{1}.ResponseData(:));
        magnitude = magnitude(isfinite(magnitude));
        if strcmpi(BO.MagUnits,'dB')
            magnitude = mag2db(magnitude(magnitude > 0));
            margin = 5;
        else
            margin = max(magnitude)*0.1;
            margin = max(margin,eps);
        end
        yLimits = getoptions(BD,'YLim');
        if ~isempty(magnitude)
            yLimits{1} = [min(magnitude)-margin,max(magnitude)+margin];
            if strcmpi(BO.MagUnits,'abs')
                yLimits{1}(1) = max(0,yLimits{1}(1));
            end
        end
        if strcmpi(BO.PhaseWrapping,'on') && strcmpi(BO.PhaseUnits,'deg')
            yLimits{2} = BO.PhaseWrappingBranch + [0,360];
        end
        setoptions(BD,'YLim',yLimits);

        % Modern charts expose response styling directly. Legacy plots use
        % LineSpec above; a uniform width needs no assumptions about order.
        if isa(BD,'controllib.chart.BodePlot')
            for responseIndex = 1:numel(BD.Responses)
                BD.Responses(responseIndex).LineWidth = 2;
            end
        else
            % Legacy response plots defer data generation in hidden figures.
            % Initialize once before hiding, otherwise exports contain axes
            % and legends but no response curves.
            fig.Visible = 'on';
            drawnow;
            fig.Visible = visibility;
            set(findall(fig,'Type','line'),'LineWidth',2);
        end
        if isa(BD,'controllib.chart.BodePlot')
            lgnd = legend(BD,labels,'Location','best');
        else
            lgnd = legend(labels,'Location','best');
        end
        lgnd.FontSize = min(fontSize,12);
        % R2026a+ exposes legend options on the chart itself.
        if ~isprop(BD,'Legend')
            lgnd.Box = 'off';
        end
    end

    function display_app_plot(fig,app)
        % Use a unique temporary file so previews never overwrite user data
        % or require write access to the current folder.
        imageFile = [tempname,'.png'];
        imageCleanup = onCleanup(@() delete_plot_image(imageFile));
        exportgraphics(fig,imageFile,'Resolution',120);
        imshow(imread(imageFile),'Parent',app.UIAxes);
    end

    function delete_plot_image(imageFile)
        if isfile(imageFile)
            delete(imageFile);
        end
    end



end

function plotTab = app_bode_container(app,parameters)
% Add a native chart container at runtime to keep the .mlapp editable in
% R2023b. The existing axes remain available for time-domain filtering.
    panel = findobj(app.RightPanel,'Type','uipanel','Tag','RIFFInteractivePlot');
    if isempty(panel)
        % Let App Designer's layout engine size the native plot and header.
        % Reparenting the existing components preserves their app callbacks.
        layout = uigridlayout(app.RightPanel,[2 1],...
            'RowHeight',{70,'1x'},'Padding',[12 12 12 12]);
        header = uigridlayout(layout,[3 2],'Padding',[0 0 0 0],...
            'RowHeight',{'1x',20,'1x'},'ColumnWidth',{'1x',20});
        header.Layout.Row = 1;
        app.RIFTLabel.Parent = header;
        app.RIFTLabel.Layout.Row = [1 3];
        app.RIFTLabel.Layout.Column = 1;
        app.RIFTLabel.HorizontalAlignment = 'center';
        app.Lamp.Parent = header;
        app.Lamp.Layout.Row = 2;
        app.Lamp.Layout.Column = 2;
        % The native panel overlays the image axes in the same grid cell.
        app.UIAxes.Parent = layout;
        app.UIAxes.Layout.Row = 2;
        panel = uipanel(layout,'BorderType','none','Tag','RIFFInteractivePlot');
        panel.Layout.Row = 2;
        plotLayout = uigridlayout(panel,[1 1],'Padding',[0 0 0 0]);
        tabs = uitabgroup(plotLayout);
        plotTab = uitab(tabs,'Title','Bode plot','Tag','RIFFBodeTab');
        % Restore the image axes when using the separate time-domain workflow.
        button = app.FilterTimeSeriesButton;
        originalCallback = button.ButtonPushedFcn;
        axesToolbar = app.UIAxes.Toolbar;
        toolbarVisibility = axesToolbar.Visible;
        button.ButtonPushedFcn = @(src,event) show_filter_plot(...
            src,event,originalCallback,panel,axesToolbar,toolbarVisibility);
    else
        plotTab = findobj(panel,'Type','uitab','Tag','RIFFBodeTab');
        tabs = plotTab.Parent;
        delete(plotTab.Children);
    end
    cla(app.UIAxes);
    app.UIAxes.Visible = 'off';
    app.UIAxes.Toolbar.Visible = 'off';
    panel.Visible = 'on';
    parameterTab = findobj(tabs,'Type','uitab','Tag','RIFFParametersTab');
    if isempty(parameters)
        delete(parameterTab);
    else
        if isempty(parameterTab)
            parameterTab = uitab(tabs,'Title','Model parameters',...
                'Tag','RIFFParametersTab');
            layout = uigridlayout(parameterTab,[1 1]);
            uitextarea(layout,'Editable','off','FontName','Monospaced',...
                'Tag','RIFFParameterText');
        end
        parameterText = findobj(parameterTab,'Tag','RIFFParameterText');
        parameterText.Value = parameters(:);
    end
end

function show_filter_plot(src,event,originalCallback,panel,axesToolbar,toolbarVisibility)
    if isgraphics(panel)
        panel.Visible = 'off';
    end
    axesToolbar.Visible = toolbarVisibility;
    originalCallback(src,event);
end

function clear_model_editor(app)
    editor = getappdata(app.UIFigure,'RIFFModelEditor');
    if isstruct(editor) && isfield(editor,'close')
        editor.close();
    elseif ~isempty(editor) && isvalid(editor)
        delete(editor); % Dispose an editor from an older loaded session.
    end
    if isappdata(app.UIFigure,'RIFFModelEditor'), rmappdata(app.UIFigure,'RIFFModelEditor'); end
end

function model = riff_fit_aaa(frequencyHz,response,maxPoles,weight,enforceStability,backend)
%RIFF_FIT_AAA Fit a continuous-time SISO response using AAA.
% Frequencies are in Hz. SYSID uses the supplied frequency weights and a
% direct AAA estimate (no nonlinear refinement). RF retains the legacy
% rational fit with a deterministic default error metric; it ignores weight.
% maxPoles is a cap, not an exact order or an independent zero-count limit.
    if nargin < 6, backend = 'sysid'; end
    backend = riff_aaa_backend(backend);
    validateattributes(frequencyHz,{'numeric'},{'vector','real','finite','nonnegative'});
    validateattributes(response,{'numeric'},{'vector','finite','numel',numel(frequencyHz)});
    validateattributes(maxPoles,{'numeric'},{'scalar','integer','positive'});
    validateattributes(weight,{'numeric'},{'vector','real','finite','nonnegative','numel',numel(response)});
    frequencyHz = frequencyHz(:); response = response(:); weight = weight(:);
    if ~any(weight > 0)
        error('RIFF:AAAWeights','At least one AAA frequency weight must be positive.');
    end
    if strcmp(backend,'sysid')
        data = idfrd(response,2*pi*frequencyHz,0);
        options = ssestOptions('InitializeMethod','AAA','Focus','simulation',...
            'InteractiveOrderSelection',false,'EstimateCovariance',false,...
            'EnforceStability',logical(enforceStability),...
            'WeightingFilter',weight,'Display','off');
        options.SearchOptions.MaxIterations = 0;
        model = ssest(data,maxPoles,'Ts',0,'Feedthrough',true,options);
        % AAA can add a conjugate pair and return nx+1 states. Retry with a
        % smaller limit rather than silently exceeding the requested cap.
        if order(model) > maxPoles
            model = ssest(data,maxPoles-1,'Ts',0,'Feedthrough',true,options);
        end
    else
        fit = rational(frequencyHz,response,'MaxPoles',maxPoles,...
            'ErrorMetric','default','QLimit',1e7);
        [b,a] = residue(squeeze(fit.Residues),squeeze(fit.Poles),squeeze(fit.DirectTerm));
        model = tf(real(b),real(a));
    end
    if order(model) > maxPoles
        error('RIFF:AAAOrder','AAA returned more than the requested %d poles.',maxPoles);
    end
    if enforceStability && ~isstable(model)
        error('RIFF:AAAStability','AAA could not produce a stable model.');
    end
end

function backend = riff_aaa_backend(requested)
%RIFF_AAA_BACKEND Resolve the AAA implementation before starting a fit.
% The current release uses System Identification AAA by default. RF remains
% an explicit option for comparisons; AUTO is retained as a SYSID alias.
    if nargin == 0, requested = 'sysid'; end
    backend = validatestring(requested,{'auto','sysid','rf'});
    if strcmp(backend,'auto'), backend = 'sysid'; end
    if strcmp(backend,'sysid')
        if isMATLABReleaseOlderThan('R2026a')
            error('RIFF:AAARelease','System Identification AAA requires MATLAB R2026a or newer.');
        end
        available = exist('ssest','file') == 2 && license('test','Identification_Toolbox');
        product = 'System Identification Toolbox';
    else
        available = exist('rational','file') == 2 && license('test','RF_Toolbox');
        product = 'RF Toolbox';
    end
    if ~available
        error('RIFF:AAAToolbox','AAA backend "%s" requires %s.',backend,product);
    end
end

function result = riff_verify_fit(app,result)
%RIFF_VERIFY_FIT Display the selected trial, or the best fit at index zero.
    variable = app.FIT_RESULT_VARIABLEEditField.Value;
    if isvarname(variable) && evalin('base',sprintf('exist(''%s'',''var'')',variable))
        result = evalin('base',variable);
    end
    if ~isstruct(result) || ~isfield(result,'FRD_Model') || ~isfield(result.FRD_Model,'modeled')
        uialert(app.UIFigure,'Run a fit or enter a valid fit-result workspace variable.','No fit available');
        return
    end
    count = 0;
    if isfield(result,'intermediate'), count = numel(result.intermediate); end
    index = app.IntermediateResultIDSpinner.Value;
    if index < 0 || index > count || index ~= fix(index)
        uialert(app.UIFigure,sprintf('Choose 0 for the best fit or a trial from 1 to %d.',count),'Invalid trial');
        return
    end
    app.Lamp.Color = [1 0 0];
    cleanup = onCleanup(@() set(app.Lamp,'Color',[0 1 0]));
    result = fitTF('APP',app,'POST_PROCESS_RESULT_VARIABLE',result,...
        'VIEW_INTERMEDIATE_BODEPLOT_TOGGLE',1,'POST_PROCESS_RESULT_INTERMEDIATE_ID',index);
end

function lines = riff_model_parameters(model,label)
%RIFF_MODEL_PARAMETERS Describe the model actually shown in a response plot.
    model = zpk(model);
    [z,p,k] = zpkdata(model,'v');
    lines = [string(label); "Zeros"; string(z(:)); "Poles"; string(p(:)); ...
        "Gain"; string(k); "Delay"; string(totaldelay(model)); ...
        "Time unit"; string(model.TimeUnit)];
end

function editor = create_model_editor(result,varargin)
% One closure owns each editing session. GUI callbacks and command-line
% operations share these models; no app or external editor class is required.
    parser = inputParser;
    addParameter(parser,'App',[]);
    addParameter(parser,'Tabs',[]);
    addParameter(parser,'Interactive',false,@(v)islogical(v) && isscalar(v));
    addParameter(parser,'Visible','on',@(v)any(strcmp(v,{'on','off'})));
    addParameter(parser,'EnforceStability',true,@(v)islogical(v) && isscalar(v));
    addParameter(parser,'EnforceMinimumPhase',false,@(v)islogical(v) && isscalar(v));
    parse(parser,varargin{:});
    settings = parser.Results;
    if ~isstruct(result) || ~isscalar(result) || ~isfield(result,'FRD_Model') || ...
            ~isfield(result.FRD_Model,'modeled')
        error('RIFF:InvalidFit','Supply a fitTF result containing FRD_Model.modeled.');
    end
    obj = struct();
    obj.App = settings.App;
    obj.OriginalFit = result;
    obj.SelectedIndex = 0;
    obj.EnforceStability = settings.EnforceStability;
    obj.EnforceMinimumPhase = settings.EnforceMinimumPhase;
    obj.Interactive = settings.Interactive || ~isempty(obj.App);
    obj.Deleting = false;
    obj.DragKind = ''; obj.DragIndex = 0;
    obj.ExtraParameters = strings(0,1);
    fields = {'Tab','PoleAxes','Chart','Selector','RootSelector','RealField',...
        'ImagField','GainField','StableCheckBox','MinimumPhaseCheckBox','Status',...
        'MainChart','MainResponse','MainTitle','ParameterText','PoleLine','ZeroLine',...
        'DestroyListener','OldMotion','OldRelease','Figure','OwnedFigure'};
    for setupIndex = 1:numel(fields), obj.(fields{setupIndex}) = []; end
    obj.Entries = makeEntry(result.FRD_Model.modeled,'Best fit',0,result.FRD_Model.truncated);
    if isfield(result,'intermediate')
        for setupIndex = 1:numel(result.intermediate)
            trial = result.intermediate(setupIndex);
            measured = result.FRD_Model.truncated;
            if isfield(trial.FRD_Model,'truncated_measurement')
                measured = trial.FRD_Model.truncated_measurement;
            end
            obj.Entries(end+1) = makeEntry(trial.FRD_Model.modeled,...
                sprintf('Trial %d',setupIndex),setupIndex,measured);
        end
    end
    try
        if obj.Interactive
            tabs = settings.Tabs;
            if isempty(obj.App)
                obj.OwnedFigure = uifigure('Name','RIFF manual model adjustment',...
                    'Position',[100 100 1150 720],'Visible','off');
                obj.Figure = obj.OwnedFigure;
                layout = uigridlayout(obj.Figure,[1 1],'Padding',[6 6 6 6]);
                tabs = uitabgroup(layout);
            else
                obj.Figure = obj.App.UIFigure;
                obj.EnforceStability = obj.App.ENFORCE_STABILITYCheckBox.Value;
                obj.EnforceMinimumPhase = obj.App.ENFORCE_MINIMUM_PHASECheckBox.Value;
            end
            createUI(tabs);
            obj.DestroyListener = addlistener(obj.Figure,'ObjectBeingDestroyed',@(~,~)close());
            refresh(true);
            if isgraphics(obj.OwnedFigure), obj.OwnedFigure.Visible = settings.Visible; end
        end
    catch failure
        close();
        rethrow(failure);
    end
    editor = struct('getModel',@currentModel,'getState',@getState,...
        'selectFit',@selectFit,'moveRoot',@moveRoot,'setGain',@setGain,...
        'setConstraints',@setConstraints,'resetFit',@resetFit,...
        'exportFit',@exportFit,'exportWorkspace',@exportWorkspace,...
        'saveToFile',@saveToFile,'close',@close,'isValid',@isValid,...
        'matchesFit',@matchesFit,'bind',@bind,'OriginalFit',result);
    % Controls are handles and remain live; changing model state is done only
    % through the operations above. getModel/getState return fresh values.
    controls = {'Tab','PoleAxes','Chart','Selector','RootSelector','RealField',...
        'ImagField','GainField','StableCheckBox','MinimumPhaseCheckBox','Status','Figure'};
    for setupIndex = 1:numel(controls), editor.(controls{setupIndex}) = obj.(controls{setupIndex}); end

    function bind(chart,index,parameterText,extraParameters)
        ensureOpen();
        % Reattach after Verify rebuilds the main Bode chart.
        stopDrag();
        obj.MainChart = chart;
        obj.MainResponse = [];
        obj.MainTitle = chart.Title.String;
        obj.ParameterText = parameterText;
        obj.ExtraParameters = extraParameters;
        obj.SelectedIndex = index;
        obj.Selector.Value = index;
        obj.App.IntermediateResultIDSpinner.Value = index;
        refresh(true);
    end

    function same = matchesFit(result)
        % fitTF adds the live app handle after drawing its final plot.
        % That UI metadata does not identify a different fitted model.
        original = obj.OriginalFit;
        if isfield(original,'APP'), original = rmfield(original,'APP'); end
        if isfield(result,'APP'), result = rmfield(result,'APP'); end
        same = isequaln(original,result);
    end

    function selectFit(index)
        ensureOpen();
        validateattributes(index,{'numeric'},{'scalar','integer','>=',0,'<',numel(obj.Entries)});
        stopDrag();
        if ~isempty(obj.App)
            fitTF('APP',obj.App,'POST_PROCESS_RESULT_VARIABLE',obj.OriginalFit,...
                'VIEW_INTERMEDIATE_BODEPLOT_TOGGLE',1,'POST_PROCESS_RESULT_INTERMEDIATE_ID',index);
        else
            obj.SelectedIndex = index;
            if isgraphics(obj.Selector), obj.Selector.Value = index; end
            refresh(true);
        end
    end

    function moveRoot(kind,index,value)
        ensureOpen();
        validateattributes(value,{'numeric'},{'scalar','finite'});
        entry = obj.Entries(obj.SelectedIndex+1);
        if strcmp(kind,'pole')
            roots = entry.Edited.P{1}; pairs = entry.PolePairs;
            constrained = obj.EnforceStability;
            if isgraphics(obj.StableCheckBox), constrained = obj.StableCheckBox.Value; end
        elseif strcmp(kind,'zero')
            roots = entry.Edited.Z{1}; pairs = entry.ZeroPairs;
            constrained = obj.EnforceMinimumPhase;
            if isgraphics(obj.MinimumPhaseCheckBox), constrained = obj.MinimumPhaseCheckBox.Value; end
        else
            error('RIFF:RootKind','Choose a pole or zero.');
        end
        validateattributes(index,{'numeric'},{'scalar','integer','>=',1,'<=',numel(roots)});
        partner = pairs(index);
        if partner == index, value = real(value); end
        if constrained
            if entry.Edited.Ts == 0
                value = complex(min(real(value),-1e-9),imag(value));
            elseif abs(value) >= 1
                value = value/abs(value)*(1-1e-9);
            end
        end
        roots(index) = value;
        if partner > 0 && partner ~= index, roots(partner) = conj(value); end
        if strcmp(kind,'pole'), entry.Edited.P = {roots};
        else, entry.Edited.Z = {roots}; end
        obj.Entries(obj.SelectedIndex+1) = entry;
        refresh(false);
    end

    function setGain(value)
        ensureOpen();
        validateattributes(value,{'numeric'},{'scalar','real','finite'});
        obj.Entries(obj.SelectedIndex+1).Edited.K = value;
        refresh(false);
    end

    function resetFit()
        ensureOpen();
        stopDrag();
        slot = obj.SelectedIndex+1;
        obj.Entries(slot).Edited = obj.Entries(slot).Original;
        refresh(true);
    end

    function result = exportFit()
        ensureOpen();
        entry = obj.Entries(obj.SelectedIndex+1);
        model = entry.Edited;
        if isstruct(model.UserData)
            stale = intersect(fieldnames(model.UserData),...
                {'CovarianceMatrix','VALUE','sigmaCovMat','sigmaZ','sigmaP','sigmaK'});
            model.UserData = rmfield(model.UserData,stale);
        end
        % Build a self-consistent result; do not copy obsolete optimizer
        % rankings, reduced models, or parameter covariance into this fit.
        result.FRD_Model.measured_original = obj.OriginalFit.FRD_Model.measured_original;
        result.FRD_Model.measured_smoothed = obj.OriginalFit.FRD_Model.measured_smoothed;
        result.FRD_Model.truncated = entry.Measured;
        result.FRD_Model.modeled = model;
        [result.ZPK.z,result.ZPK.p,result.ZPK.k] = zpkdata(model,'v');
        result.ZPK.z_sigma = []; result.ZPK.p_sigma = []; result.ZPK.k_sigma = [];
        result.ZPK.parameterCovarianceMatrix = [];
        result.IODelay = totaldelay(model);
        result.gof = score(entry);
        result.frequency = obj.OriginalFit.frequency;
        selectedFrequency = chgFreqUnit(entry.Measured,'Hz');
        result.frequency.truncated = selectedFrequency.Frequency(:);
        result.transferFunction.measured = result.FRD_Model.measured_original.ResponseData(:);
        result.transferFunction.measured_smoothed = result.FRD_Model.measured_smoothed.ResponseData(:);
        result.transferFunction.truncated = entry.Measured.ResponseData(:);
        result.options.BodeOptions = obj.OriginalFit.options.BodeOptions;
        result.manualAdjustment.Source = entry.Label;
        result.manualAdjustment.TrialIndex = entry.TrialIndex;
        result.manualAdjustment.OriginalModel = entry.Original;
        result.manualAdjustment.Modified = ~isequal(entry.Original,entry.Edited);
        result.manualAdjustment.Time = char(datetime('now'));
    end

    function name = exportWorkspace()
        ensureOpen();
        base = 'RIFF_MANUAL_FIT';
        if ~isempty(obj.App), base = [obj.App.EXPORT_VARIABLE_NAMEEditField.Value,'_MANUAL']; end
        if ~isvarname(base), base = 'RIFF_MANUAL_FIT'; end
        name = base; suffix = 2;
        while evalin('base',sprintf('exist(''%s'',''var'')',name))
            name = sprintf('%s_%d',base,suffix); suffix = suffix+1;
        end
        assignin('base',name,exportFit());
        if isgraphics(obj.Status), obj.Status.Text = ['Exported to workspace: ',name]; end
    end

    function saveToFile(file)
        ensureOpen();
        FIT = exportFit();
        save(file,'FIT');
    end

    function createUI(tabs)
        obj.Tab = uitab(tabs,'Title','Pole/zero editor','Tag','RIFFEditorTab');
        grid = uigridlayout(obj.Tab,[1 2],'ColumnWidth',{'1x',280},'Padding',[4 4 4 4]);
        host = uipanel(grid,'BorderType','none'); host.Layout.Column = 1;
        options = obj.OriginalFit.options.BodeOptions;
        options.Title.String = 'Manual adjustment';
        options.Title.FontSize = 11; options.TickLabel.FontSize = 10;
        options.XLabel.FontSize = 11; options.YLabel.FontSize = 11;
        entry = obj.Entries(1);
        obj.Chart = bodeplot(host,entry.Measured,entry.Original,'m--',entry.Edited,'g-',options);
        legend(obj.Chart,{'Measurement','Original fit','Manual adjustment'},'Location','best');
        for n = 1:numel(obj.Chart.Responses), obj.Chart.Responses(n).LineWidth = 1.5; end
        side = uigridlayout(grid,[12 2],'ColumnWidth',{'1x','1x'},...
            'RowHeight',{24,'1x',24,16,24,24,22,22,26,26,40,34},...
            'Padding',[2 2 2 2],'RowSpacing',5);
        side.Layout.Column = 2;
        obj.Selector = uidropdown(side,'Items',{obj.Entries.Label},...
            'ItemsData',[obj.Entries.TrialIndex],'Value',0,...
            'ValueChangedFcn',@(src,~)selectFit(src.Value),'Tag','RIFFEditFit');
        obj.Selector.Layout.Row = 1; obj.Selector.Layout.Column = [1 2];
        obj.PoleAxes = uiaxes(side,'Tag','RIFFPoleZeroAxes');
        obj.PoleAxes.Layout.Row = 2; obj.PoleAxes.Layout.Column = [1 2];
        title(obj.PoleAxes,'Drag poles (×) or zeros (○)');
        xlabel(obj.PoleAxes,'Real'); ylabel(obj.PoleAxes,'Imaginary');
        gridOn = obj.PoleAxes; gridOn.XGrid = 'on'; gridOn.YGrid = 'on';
        disableDefaultInteractivity(obj.PoleAxes);
        obj.PoleAxes.Toolbar.Visible = 'off';
        hold(obj.PoleAxes,'on');
        xline(obj.PoleAxes,0,':','HitTest','off'); yline(obj.PoleAxes,0,':','HitTest','off');
        if entry.Edited.Ts ~= 0
            theta = linspace(0,2*pi,200);
            plot(obj.PoleAxes,cos(theta),sin(theta),':','HitTest','off');
        end
        obj.PoleLine = plot(obj.PoleAxes,NaN,NaN,'x','MarkerSize',10,'LineWidth',2,...
            'ButtonDownFcn',@(~,event)startDrag('pole',event));
        obj.ZeroLine = plot(obj.PoleAxes,NaN,NaN,'o','MarkerSize',9,'LineWidth',2,...
            'ButtonDownFcn',@(~,event)startDrag('zero',event));
        obj.PoleAxes.ButtonDownFcn = @(~,event)startDrag('',event);
        obj.RootSelector = uidropdown(side,'Items',{'No roots'},'ItemsData',0,...
            'ValueChangedFcn',@(~,~)updateFields(),'Tag','RIFFEditRoot');
        obj.RootSelector.Layout.Row = 3; obj.RootSelector.Layout.Column = [1 2];
        label = uilabel(side,'Text','Real'); label.Layout.Row = 4;
        label = uilabel(side,'Text','Imaginary'); label.Layout.Row = 4; label.Layout.Column = 2;
        obj.RealField = uieditfield(side,'numeric','Tooltip','Real part of selected root',...
            'ValueChangedFcn',@(~,~)numericRoot(),'Tag','RIFFRootReal');
        obj.RealField.Layout.Row = 5;
        obj.ImagField = uieditfield(side,'numeric','Tooltip','Imaginary part of selected root',...
            'ValueChangedFcn',@(~,~)numericRoot(),'Tag','RIFFRootImag');
        obj.ImagField.Layout.Row = 5; obj.ImagField.Layout.Column = 2;
        label = uilabel(side,'Text','Gain'); label.Layout.Row = 6;
        obj.GainField = uieditfield(side,'numeric','ValueChangedFcn',@(src,~)setGain(src.Value));
        obj.GainField.Layout.Row = 6; obj.GainField.Layout.Column = 2;
        obj.StableCheckBox = uicheckbox(side,'Text','Keep poles stable',...
            'Value',obj.EnforceStability);
        obj.StableCheckBox.Layout.Row = 7; obj.StableCheckBox.Layout.Column = [1 2];
        obj.MinimumPhaseCheckBox = uicheckbox(side,'Text','Keep zeros minimum-phase',...
            'Value',obj.EnforceMinimumPhase);
        obj.MinimumPhaseCheckBox.Layout.Row = 8; obj.MinimumPhaseCheckBox.Layout.Column = [1 2];
        button = uibutton(side,'Text','Zoom to root','ButtonPushedFcn',@(~,~)zoomToRoot());
        button.Layout.Row = 9;
        button = uibutton(side,'Text','Show all roots','ButtonPushedFcn',@(~,~)fitMap());
        button.Layout.Row = 9; button.Layout.Column = 2;
        button = uibutton(side,'Text','Reset this fit','ButtonPushedFcn',@(~,~)resetFit(),...
            'Tag','RIFFResetModel'); button.Layout.Row = 10;
        button = uibutton(side,'Text','Save MAT…','ButtonPushedFcn',@(~,~)saveDialog());
        button.Layout.Row = 10; button.Layout.Column = 2;
        obj.Status = uilabel(side,'WordWrap','on','FontSize',11,'Tag','RIFFEditStatus');
        obj.Status.Layout.Row = 11; obj.Status.Layout.Column = [1 2];
        button = uibutton(side,'Text','Export edited fit to workspace',...
            'ButtonPushedFcn',@(~,~)exportWorkspace(),'Tag','RIFFExportModel');
        button.Layout.Row = 12; button.Layout.Column = [1 2];
    end

    function refresh(resetView)
        if isempty(obj.Tab) || ~isgraphics(obj.Tab), return; end
        entry = obj.Entries(obj.SelectedIndex+1);
        [z,p,k] = zpkdata(entry.Edited,'v');
        obj.PoleLine.XData = real(p); obj.PoleLine.YData = imag(p);
        obj.ZeroLine.XData = real(z); obj.ZeroLine.YData = imag(z);
        if resetView
            names = [compose('Pole %d',1:numel(p)),compose('Zero %d',1:numel(z))];
            if isempty(names), names = "No roots"; ids = 0;
            else, ids = 1:numel(names); end
            obj.RootSelector.Items = cellstr(names);
            obj.RootSelector.ItemsData = ids;
            obj.RootSelector.Value = ids(1);
            setResponse(obj.Chart.Responses(1),entry.Measured);
            setResponse(obj.Chart.Responses(2),entry.Original);
            obj.Chart.Title.String = [entry.Label,' — original and manual adjustment'];
            fitMap();
        end
        obj.GainField.Value = real(k);
        updateFields();
        setResponse(obj.Chart.Responses(3),entry.Edited);
        dirty = ~isequal(entry.Original,entry.Edited);
        gof = score(entry);
        state = 'Stable';
        if ~isstable(entry.Edited), state = 'UNSTABLE'; end
        obj.Status.Text = sprintf('%s | GOF %.2f%% | %s',entry.Label,gof,state);
        obj.Status.FontColor = [0.2 0.7 0.4];
        if ~isstable(entry.Edited), obj.Status.FontColor = [1 0.3 0.3]; end
        label = entry.Label;
        if dirty, label = [label,' — manual adjustment']; end
        if isgraphics(obj.ParameterText)
            obj.ParameterText.Value = [riff_model_parameters(entry.Edited,label);obj.ExtraParameters];
        end
        if ~isempty(obj.MainChart) && isvalid(obj.MainChart)
            if dirty && isempty(obj.MainResponse)
                addResponse(obj.MainChart,entry.Edited);
                obj.MainResponse = obj.MainChart.Responses(end);
                obj.MainResponse.Color = [0.2 0.8 0.4];
                obj.MainResponse.LineWidth = 2;
            end
            if ~isempty(obj.MainResponse) && isvalid(obj.MainResponse)
                setResponse(obj.MainResponse,entry.Edited);
                obj.MainResponse.Name = sprintf('Manual adjustment (GOF %.2f%%)',gof);
                obj.MainResponse.Visible = dirty;
                if isprop(obj.MainResponse,'LegendDisplay'), obj.MainResponse.LegendDisplay = dirty; end
            end
            obj.MainChart.Title.String = obj.MainTitle;
            if dirty
                obj.MainChart.Title.String = sprintf('%s\nManual adjustment GOF: %.2f%%',...
                    strjoin(string(obj.MainTitle),newline),gof);
            end
        end
        drawnow limitrate nocallbacks;
    end

    function updateFields()
        [kind,index] = selectedRoot();
        enabled = index > 0;
        obj.RealField.Enable = enabled; obj.ImagField.Enable = enabled;
        if ~enabled, return; end
        entry = obj.Entries(obj.SelectedIndex+1);
        if strcmp(kind,'pole'), value = entry.Edited.P{1}(index); pairs = entry.PolePairs;
        else, value = entry.Edited.Z{1}(index); pairs = entry.ZeroPairs; end
        obj.RealField.Value = real(value); obj.ImagField.Value = imag(value);
        obj.ImagField.Enable = pairs(index) ~= index;
    end

    function [kind,index] = selectedRoot()
        model = currentModel();
        count = numel(model.P{1});
        index = obj.RootSelector.Value; kind = 'pole';
        if index > count, kind = 'zero'; index = index-count; end
    end

    function numericRoot()
        [kind,index] = selectedRoot();
        if index > 0, moveRoot(kind,index,complex(obj.RealField.Value,obj.ImagField.Value)); end
    end

    function startDrag(kind,event)
        if ~strcmp(obj.Figure.SelectionType,'normal'), return; end
        point = obj.PoleAxes.CurrentPoint(1,1:2);
        if isprop(event,'IntersectionPoint'), point = event.IntersectionPoint(1:2); end
        model = currentModel();
        values = [model.P{1};model.Z{1}];
        ids = 1:numel(values);
        count = numel(model.P{1});
        if strcmp(kind,'pole'), ids = 1:count;
        elseif strcmp(kind,'zero'), ids = count+(1:numel(model.Z{1})); end
        if isempty(ids), return; end
        distance = hypot((real(values(ids))-point(1))/diff(obj.PoleAxes.XLim),...
            (imag(values(ids))-point(2))/diff(obj.PoleAxes.YLim));
        [nearest,at] = min(distance);
        if nearest > 0.08, return; end
        obj.RootSelector.Value = ids(at);
        [obj.DragKind,obj.DragIndex] = selectedRoot();
        updateFields();
        obj.OldMotion = obj.Figure.WindowButtonMotionFcn;
        obj.OldRelease = obj.Figure.WindowButtonUpFcn;
        obj.Figure.WindowButtonMotionFcn = @(~,~)dragRoot();
        obj.Figure.WindowButtonUpFcn = @(~,~)stopDrag();
    end

    function dragRoot()
        if obj.DragIndex == 0, return; end
        point = obj.PoleAxes.CurrentPoint(1,1:2);
        if all(isfinite(point))
            moveRoot(obj.DragKind,obj.DragIndex,complex(point(1),point(2)));
        end
    end

    function stopDrag()
        if obj.DragIndex == 0, return; end
        fig = obj.Figure;
        if isgraphics(fig) && strcmp(fig.BeingDeleted,'off')
            fig.WindowButtonMotionFcn = obj.OldMotion;
            fig.WindowButtonUpFcn = obj.OldRelease;
        end
        obj.DragIndex = 0; obj.DragKind = '';
    end

    function fitMap()
        model = currentModel();
        values = [model.P{1};model.Z{1};0];
        span = max([range(real(values)),range(imag(values)),1]);
        obj.PoleAxes.XLim = [min(real(values))-0.15*span,max(real(values))+0.15*span];
        obj.PoleAxes.YLim = [min(imag(values))-0.15*span,max(imag(values))+0.15*span];
    end

    function zoomToRoot()
        model = currentModel();
        [kind,index] = selectedRoot();
        if index == 0, return; end
        if strcmp(kind,'pole'), value = model.P{1}(index);
        else, value = model.Z{1}(index); end
        radius = max(abs(value)*0.4,0.1);
        obj.PoleAxes.XLim = real(value)+[-radius radius];
        obj.PoleAxes.YLim = imag(value)+[-radius radius];
    end

    function saveDialog()
        [file,folder] = uiputfile('*.mat','Save manually adjusted fit','RIFF_manual_fit.mat');
        if isequal(file,0), return; end
        saveToFile(fullfile(folder,file));
        obj.Status.Text = ['Saved: ',file];
    end

    function entry = makeEntry(model,label,index,measured)
        entry.Original = zpk(model); entry.Edited = entry.Original;
        entry.Label = label; entry.TrialIndex = index; entry.Measured = measured;
        entry.PolePairs = pairRoots(entry.Original.P{1});
        entry.ZeroPairs = pairRoots(entry.Original.Z{1});
        [mag,phase,w] = bode(measured);
        entry.Magnitude = mag(:); entry.Phase = phase(:); entry.Frequency = w;
    end

    function pairs = pairRoots(values)
        pairs = zeros(size(values));
        for n = 1:numel(values)
            if pairs(n) ~= 0, continue; end
            tolerance = 1e-7*max(1,abs(values(n)));
            if abs(imag(values(n))) <= tolerance, pairs(n) = n; continue; end
            candidate = find(abs(values-conj(values(n))) <= tolerance & pairs == 0);
            candidate(candidate == n) = [];
            if ~isempty(candidate), pairs(n) = candidate(1); pairs(candidate(1)) = n; end
        end
    end

    function setResponse(response,model)
        if isprop(response,'Model'), response.Model = model;
        else, response.SourceData.Model = model; end
    end

    function gof = score(entry)
        [mag,phase] = bode(entry.Edited,entry.Frequency);
        observedMag = log10(max(entry.Magnitude,realmin));
        observedPhase = wrapTo180(entry.Phase);
        magDenom = norm(observedMag-mean(observedMag));
        phaseDenom = norm(observedPhase-mean(observedPhase));
        if magDenom == 0 || phaseDenom == 0, gof = NaN; return; end
        gof = 100*(1-0.5*norm(observedMag-log10(max(mag(:),realmin)))/magDenom...
            -0.5*norm(observedPhase-wrapTo180(phase(:)))/phaseDenom);
    end

    function model = currentModel()
        ensureOpen();
        model = obj.Entries(obj.SelectedIndex+1).Edited;
    end

    function close()
        if obj.Deleting, return; end
        obj.Deleting = true;
        stopDrag();
        if isgraphics(obj.Tab), delete(obj.Tab); end
        if isgraphics(obj.OwnedFigure), delete(obj.OwnedFigure); end
        if ~isempty(obj.DestroyListener), delete(obj.DestroyListener); end
    end

    function state = getState()
        ensureOpen();
        entry = obj.Entries(obj.SelectedIndex+1);
        stable = obj.EnforceStability; minimumPhase = obj.EnforceMinimumPhase;
        if isgraphics(obj.StableCheckBox), stable = obj.StableCheckBox.Value; end
        if isgraphics(obj.MinimumPhaseCheckBox), minimumPhase = obj.MinimumPhaseCheckBox.Value; end
        state = struct('SelectedIndex',obj.SelectedIndex,'Label',entry.Label,...
            'CurrentModel',entry.Edited,'Modified',~isequal(entry.Original,entry.Edited),...
            'GOF',score(entry),'EnforceStability',stable,'EnforceMinimumPhase',minimumPhase);
    end

    function setConstraints(stable,minimumPhase)
        ensureOpen();
        validateattributes(stable,{'logical','numeric'},{'scalar','binary'});
        validateattributes(minimumPhase,{'logical','numeric'},{'scalar','binary'});
        obj.EnforceStability = logical(stable);
        obj.EnforceMinimumPhase = logical(minimumPhase);
        if isgraphics(obj.StableCheckBox), obj.StableCheckBox.Value = stable; end
        if isgraphics(obj.MinimumPhaseCheckBox), obj.MinimumPhaseCheckBox.Value = minimumPhase; end
    end

    function valid = isValid()
        valid = ~obj.Deleting;
        if obj.Interactive, valid = valid && isgraphics(obj.Tab); end
    end

    function ensureOpen()
        if obj.Deleting, error('RIFF:EditorClosed','This editing session is closed.'); end
    end

end

function combined = riff_combine_measurements(dataSets,dF,BO,plotToggle)
% Combine on a shared Hz grid; average complex responses only where measured.
if nargin < 2 || isempty(dF), dF = 0.25; end
if nargin < 3 || isempty(BO)
    BO = bodeoptions;
    BO.FreqUnits = 'Hz'; BO.PhaseWrapping = 'on';
    BO.PhaseWrappingBranch = -180; BO.Grid = 'on';
end
if nargin < 4 || isempty(plotToggle), plotToggle = false; end
validateattributes(dF,{'numeric'},{'real','scalar','finite','positive'},mfilename,'dF');
validateattributes(plotToggle,{'logical','numeric'},{'scalar','binary'},mfilename,'plotToggle');
if ~isa(BO,'plotopts.BodeOptions')
    error('RIFF:CombineOptions','Supply a bodeoptions object for BO.');
end
if isstruct(dataSets)
    if isempty(dataSets) || ~all(isfield(dataSets,{'F','TF'}))
        error('RIFF:CombineInput','Measurement structures must contain F (Hz) and TF.');
    end
    names = "Measurement " + (1:numel(dataSets));
elseif ischar(dataSets) || isstring(dataSets) || iscellstr(dataSets)
    names = string(dataSets);
    if isempty(names) || ~isvector(names) || any(ismissing(names) | strlength(names)==0)
        error('RIFF:CombineInput','Select at least one SDF file.');
    end
    names = unique(names(:)','stable');
    utilsFolder = fullfile(fileparts(mfilename('fullpath')),'utils');
    oldPath = path;
    pathCleanup = onCleanup(@()path(oldPath));
    if ~any(strcmp(strsplit(path,pathsep),utilsFolder)), addpath(utilsFolder); end
    dataSets = repmat(struct('F',[],'TF',[]),size(names));
    for k = 1:numel(names)
        if ~isfile(names(k))
            error('RIFF:SDFFile','SDF file does not exist: %s',names(k));
        end
        imported = SDF_import(char(names(k)));
        if numel(imported.SDF_XDATA_HDR) ~= 1 || numel(imported.SDF_YDATA_HDR) ~= 1
            error('RIFF:SDFTrace','Select a single frequency-response trace per SDF file: %s',names(k));
        end
        f = imported.SDF_XDATA_HDR.zz_data;
        raw = imported.SDF_YDATA_HDR.zz_data;
        if ~isvector(f) || ~isvector(raw)
            error('RIFF:SDFTrace','Expected vector frequency-response data in %s.',names(k));
        end
        if numel(raw) == 2*numel(f)
            response = raw(1:2:end) + 1i*raw(2:2:end);
        elseif numel(raw) == numel(f)
            response = raw;
        else
            error('RIFF:SDFTrace','Frequency and response lengths do not match in %s.',names(k));
        end
        dataSets(k).F = f; dataSets(k).TF = response;
    end
else
    error('RIFF:CombineInput','Use SDF filenames or structures with F (Hz) and TF.');
end
measurements = repmat(struct('FF',[],'TF',[],'FRD',[],'Name',""),1,numel(dataSets));
bounds = zeros(numel(dataSets),2);
for k = 1:numel(dataSets)
    f = dataSets(k).F; response = dataSets(k).TF;
    validateattributes(f,{'numeric'},{'real','vector'},mfilename,'F');
    validateattributes(response,{'numeric'},{'vector'},mfilename,'TF');
    if numel(f) ~= numel(response)
        error('RIFF:CombineLength','F and TF must have the same length in %s.',names(k));
    end
    f = double(f(:)); response = double(response(:));
    keep = isfinite(f) & f > 0 & isfinite(response);
    f = f(keep); response = response(keep);
    [f,~,group] = unique(f,'sorted');
    % Repeated samples at one frequency are repeated complex measurements.
    response = accumarray(group,real(response),[],@mean) + ...
        1i*accumarray(group,imag(response),[],@mean);
    if numel(f) < 2
        error('RIFF:CombineSamples','Need at least two distinct positive finite frequencies in %s.',names(k));
    end
    measurements(k).FF = f'; measurements(k).TF = response.';
    measurements(k).FRD = frd(response,2*pi*f);
    measurements(k).Name = names(k);
    bounds(k,:) = [f(1),f(end)];
end
% Canonical ordering gives consistent accumulation when file order changes.
[~,order] = sortrows([bounds,(1:size(bounds,1))'],[1 2]);
measurements = measurements(order); bounds = bounds(order,:);
fmin = min(bounds(:,1)); fmax = max(bounds(:,2));
if (fmax-fmin)/dF > 2e6
    error('RIFF:CombineResolution','The requested resolution exceeds two million samples. Increase dF.');
end
f = unique([(fmin:dF:fmax)';bounds(:)]);
response = complex(zeros(size(f))); coverage = zeros(size(f));
for k = 1:numel(measurements)
    use = f >= bounds(k,1) & f <= bounds(k,2);
    values = interp1(measurements(k).FF,measurements(k).TF,f(use),'linear');
    response(use) = response(use) + values;
    coverage(use) = coverage(use) + 1;
end
keep = coverage > 0; % Never synthesize samples in unmeasured gaps.
f = f(keep); coverage = coverage(keep); response = response(keep)./coverage;
combined = struct('F',f,'TF',response,'FRD',frd(response,2*pi*f),...
    'Measurements',measurements,'BodeOptions',BO,'Coverage',coverage);
if plotToggle
    fig = figure('Name','Combined measurements','NumberTitle','off');
    models = {measurements.FRD}; models{end+1} = combined.FRD;
    chart = bodeplot(fig,models{:},BO);
    labels = string({measurements.Name});
    [~,labels,extensions] = fileparts(labels);
    labels = labels + extensions;
    legend(chart,[labels,"Combined response"],'Interpreter','none','Location','best');
end
end

function info = riff_inspect_measurement(source)
% Read columns without assigning physical meaning to unnamed numeric data.
if istable(source)
    values = source; sourceName = '';
elseif isnumeric(source) && ismatrix(source)
    values = array2table(source); sourceName = '';
elseif (ischar(source) || (isstring(source) && isscalar(source))) && isfile(source)
    values = readtable(source,'VariableNamingRule','preserve');
    sourceName = char(source);
else
    error('RIFF:ImportSource','Supply a table, numeric matrix, or existing text/CSV file.');
end
if height(values)<2 || width(values)<2
    error('RIFF:ImportSource','The measurement needs at least two rows and two columns.');
end
names = string(values.Properties.VariableNames);
keys = lower(regexprep(names,'[^a-zA-Z0-9]',''));
map = struct('Frequency',0,'Real',0,'Imaginary',0,'Response',0,...
    'Magnitude',0,'Phase',0,'Weight',0,'Coherence',0,...
    'FrequencyUnit','','ResponseType','','MagnitudeUnit','','PhaseUnit','',...
    'UseCoherence',true);
aliases = struct('Frequency',{{'f','freq','frequency','fhz','freqhz','frequencyhz','hz','w','omega','frequencyrads','freqrads','wrads','omegarads'}},...
    'Real',{{'real','re','realpart','tfreal','realresponse'}},...
    'Imaginary',{{'imag','im','imaginary','imaginarypart','tfimag','imagresponse'}},...
    'Response',{{'tf','response','transferfunction','complexresponse','h'}},...
    'Magnitude',{{'mag','magnitude','amplitude','magdb','magnitudedb','amplitudedb','magnitudelinear','maglinear'}},...
    'Phase',{{'phase','phasedeg','phasedegrees','phaserad','phaseradians'}},...
    'Weight',{{'weight','weights','fitweight','weighting'}},...
    'Coherence',{{'coherence','coh','mscoherence','magnitudesquaredcoherence','gamma2','coherencepercent','coherencepct'}});
roles = fieldnames(aliases); ambiguous = {};
for n=1:numel(roles)
    matches = find(ismember(keys,string(aliases.(roles{n}))));
    if isscalar(matches), map.(roles{n}) = matches;
    elseif numel(matches)>1, ambiguous{end+1} = roles{n}; end %#ok<AGROW>
end
if map.Frequency>0,map.FrequencyUnit=riff_import_units('Frequency',names(map.Frequency));end
formats = [map.Real>0 && map.Imaginary>0,map.Response>0,map.Magnitude>0 && map.Phase>0];
if sum(formats)==1
    types={'real-imag','complex','mag-phase'};map.ResponseType=types{find(formats,1)};
end
if map.Magnitude>0,map.MagnitudeUnit=riff_import_units('Magnitude',names(map.Magnitude));end
if map.Phase>0,map.PhaseUnit=riff_import_units('Phase',names(map.Phase));end
info=struct('Table',values,'ColumnNames',names,'SuggestedMap',map,...
    'AmbiguousRoles',{ambiguous},'Source',sourceName);
end

function data = riff_import_measurement(source,map)
info=riff_inspect_measurement(source);
if nargin<2 || isempty(map),map=struct();end
validateattributes(map,{'struct'},{'scalar'},mfilename,'COLUMN_MAP');
unknown=setdiff(fieldnames(map),fieldnames(info.SuggestedMap));
if ~isempty(unknown),error('RIFF:ColumnMap','Unknown mapping field: %s',unknown{1});end
explicit=fieldnames(map); resolved=info.SuggestedMap;
for n=1:numel(explicit),resolved.(explicit{n})=map.(explicit{n});end
% Ambiguous optional columns also need an explicit selection or explicit 0.
for n=1:numel(info.AmbiguousRoles)
    role=info.AmbiguousRoles{n};
    if ~ismember(role,explicit)
        error('RIFF:ColumnMap','Select columns explicitly: %s. Use fitTF(''inspect'',source) or Map columns.',role);
    end
end
map=resolved; values=info.Table;
roles={'Frequency','Real','Imaginary','Response','Magnitude','Phase','Weight','Coherence'};
for n=1:numel(roles)
    role=roles{n}; selected=map.(role);
    if ischar(selected) || (isstring(selected) && isscalar(selected))
        selected=find(info.ColumnNames==string(selected));
        if ~isscalar(selected),error('RIFF:ColumnMap','Column name for %s was not found.',role);end
    end
    validateattributes(selected,{'numeric'},{'real','scalar','integer','>=',0,'<=',width(values)},mfilename,role);
    map.(role)=selected;
end
% A changed column must not inherit the unit of the old suggested column.
unitRoles={'Frequency','Magnitude','Phase'};
for n=1:numel(unitRoles)
    role=unitRoles{n};unit=[role 'Unit'];
    if ismember(role,explicit) && ~ismember(unit,explicit) && map.(role)>0
        map.(unit)=riff_import_units(role,info.ColumnNames(map.(role)));
    end
end
validateattributes(map.UseCoherence,{'logical','numeric'},{'scalar','binary'});
if ~ismember(string(map.FrequencyUnit),["Hz","rad/s"])
    error('RIFF:ColumnMap','Select FrequencyUnit as Hz or rad/s.');
end
f=column('Frequency');
if ~isreal(f),error('RIFF:ImportFrequency','Frequency must be real.');end
if strcmp(map.FrequencyUnit,'rad/s'),f=f/(2*pi);end
used=map.Frequency;
switch string(map.ResponseType)
    case 'real-imag'
        a=column('Real');b=column('Imaginary');
        if ~isreal(a)||~isreal(b),error('RIFF:ImportResponse','Real/imaginary columns must contain real coefficients.');end
        response=a+1i*b;used=[used map.Real map.Imaginary];
    case 'complex'
        response=column('Response');used=[used map.Response];
    case 'mag-phase'
        magnitude=column('Magnitude');phase=column('Phase');
        if ~isreal(magnitude)||~isreal(phase),error('RIFF:ImportResponse','Magnitude and phase must be real.');end
        if strcmp(map.MagnitudeUnit,'dB'),magnitude=10.^(magnitude/20);
        elseif ~strcmp(map.MagnitudeUnit,'linear'),error('RIFF:ColumnMap','Select MagnitudeUnit as linear or dB.');end
        if any(magnitude<0),error('RIFF:ImportResponse','Linear magnitude must be nonnegative.');end
        if strcmp(map.PhaseUnit,'deg'),phase=deg2rad(phase);
        elseif ~strcmp(map.PhaseUnit,'rad'),error('RIFF:ColumnMap','Select PhaseUnit as deg or rad.');end
        response=magnitude.*exp(1i*phase);used=[used map.Magnitude map.Phase];
    otherwise
        error('RIFF:ColumnMap','Select ResponseType: real-imag, complex, or mag-phase.');
end
weight=[];coherence=[];
if map.Weight>0,weight=column('Weight');used=[used map.Weight];end
if map.Coherence>0
    key=lower(string(info.ColumnNames(map.Coherence)));
    if contains(key,'percent') || contains(key,'pct') || contains(key,'%')
        error('RIFF:ImportCoherence','Coherence must use 0–1 units. Convert percentage columns before importing, or deselect that column.');
    end
    coherence=column('Coherence');used=[used map.Coherence];
end
if numel(unique(used))~=numel(used)
    error('RIFF:ColumnMap','Each selected quantity must use a different column.');
end
if any(~isfinite(f)) || any(f<0) || any(~isfinite(response))
    error('RIFF:ImportSamples','Frequency/response must be finite, with nonnegative frequencies. Check columns and units.');
end
riff_validate_weights(weight,height(values),'weight');
riff_validate_weights(coherence,height(values),'coherence');
rows=find(f>0);[~,order]=sort(f(rows));rows=rows(order);
if numel(rows)<2 || any(diff(f(rows))<=0)
    error('RIFF:ImportFrequency','Need at least two distinct positive frequencies; remove or combine duplicates.');
end
f=f(rows);response=response(rows);
if ~isempty(weight),weight=weight(rows);end
if ~isempty(coherence),coherence=coherence(rows);end
effective=ones(size(f));
if ~isempty(weight),effective=effective.*weight;end
if ~isempty(coherence)&&map.UseCoherence,effective=effective.*coherence;end
if ~any(effective>0),error('RIFF:ImportWeights','At least one effective weight must be positive.');end
data=struct('F',f,'TF',response,'Weight',weight,'Coherence',coherence,...
    'EffectiveWeight',effective,'HasWeights',~isempty(weight)||(~isempty(coherence)&&map.UseCoherence),...
    'ColumnMap',map,'Source',info.Source,'Rows',rows,'SourceRowCount',height(values),...
    'DroppedDCRows',find(column('Frequency')==0));

    function out=column(role)
        index=map.(role);
        if index==0,error('RIFF:ColumnMap','Select the %s column.',role);end
        raw=values{:,index};
        if isnumeric(raw)||islogical(raw),out=double(raw);
        elseif iscell(raw)||isstring(raw)||ischar(raw),out=str2double(string(raw));
        else
            error('RIFF:ImportColumn','The %s column must contain numeric samples.',role);
        end
        if ~isvector(out)||numel(out)~=height(values),error('RIFF:ImportColumn','The %s column must contain one numeric value per row.',role);end
        out=out(:);
    end
end

function riff_validate_weights(values,count,kind)
if isempty(values),return;end
if ~isnumeric(values)&&~islogical(values)
    error('RIFF:ImportWeights','%s must be a numeric vector.',kind);
end
if ~isvector(values)||numel(values)~=count||~isreal(values)||any(~isfinite(values))||any(values<0)
    error('RIFF:ImportWeights','%s must have one finite, nonnegative real value per input sample.',kind);
end
if strcmp(kind,'coherence')&&any(values>1)
    error('RIFF:ImportCoherence','Coherence must be in [0,1]; convert percentages before importing.');
end
end

function key=riff_import_key(file)
[ok,details]=fileattrib(file);
if ~ok,error('RIFF:ImportSource','Select an existing measurement file.');end
key=details.Name;
end

function button = riff_setup_import(app)
% Keep App Designer callbacks thin; build the optional mapping UI in the core.
button=findall(app.TextFileTab,'Tag','RIFFMapColumns');
if ~isempty(button),return;end
app.FORMATDropDown.Items=[app.FORMATDropDown.Items,{'Auto / mapped'}];
button=uibutton(app.TextFileTab,'Text','Map columns...',...
    'Tag','RIFFMapColumns','Position',[206 105 140 28],...
    'Tooltip','Map frequency, response, optional weight and coherence columns.',...
    'ButtonPushedFcn',@(~,~)riff_import_dialog(app));
uilabel(app.TextFileTab,'Text',{'Optional weight /','coherence columns'},...
    'Position',[206 62 145 38],'FontSize',11);
end

function map = riff_saved_import_map(app,file)
map=struct();
if isappdata(app.UIFigure,'RIFFImportMaps')
    cache=getappdata(app.UIFigure,'RIFFImportMaps');key=riff_import_key(file);
    if isKey(cache,key),map=cache(key);end
end
end

function ui = riff_import_dialog(app)
% This dialog only stores a mapping. Every fit/preview rereads the source file.
if isempty(app.ChooseTFListBox.Value)
    uialert(app.UIFigure,'Upload and select a measurement file first.','Map columns');ui=[];return
end
file=fullfile('measured_TFs',app.ChooseTFListBox.Value);
try
    key=riff_import_key(file);info=riff_inspect_measurement(file);
catch exception
    uialert(app.UIFigure,exception.message,'Cannot read measurement');ui=[];return
end
if isappdata(app.UIFigure,'RIFFImportDialog')
    previous=getappdata(app.UIFigure,'RIFFImportDialog');
    if isgraphics(previous),delete(previous);end
end
fig=uifigure('Name','RIFF — Map measurement columns','Position',[140 100 760 650],...
    'Tag','RIFFImportDialog','Visible','off');
setappdata(app.UIFigure,'RIFFImportDialog',fig);
owner=addlistener(app.UIFigure,'ObjectBeingDestroyed',@(~,~)deleteDialog());
fig.DeleteFcn=@(~,~)delete(owner);
layout=uigridlayout(fig,[10 4],'RowHeight',{28,26,130,28,28,28,28,28,'1x',32},...
    'ColumnWidth',{125,'1x',125,'1x'},'Padding',[15 12 15 12]);
[~,baseName,extension]=fileparts(key);
header=uilabel(layout,'Text',[baseName extension],'Tooltip',key,'Interpreter','none','FontWeight','bold');
header.Layout.Row=1;header.Layout.Column=[1 4];
help=uilabel(layout,'Text','Check columns and units. Coherence is 0–1; weight × coherence is used for fitting.');
help.Layout.Row=2;help.Layout.Column=[1 4];
preview=uitable(layout,'Data',info.Table(1:min(6,height(info.Table)),:),...
    'ColumnEditable',false,'RowName',[],'Tag','RIFFImportPreview');
preview.Layout.Row=3;preview.Layout.Column=[1 4];
items=[{'— select / none —'},cellstr(info.ColumnNames)];
itemData=0:width(info.Table);
controls=struct();
addColumn('Frequency','Frequency',4,1);
addChoice('FrequencyUnit','Frequency unit',4,3,{'— select —','Hz','rad/s'},{'','Hz','rad/s'});
addChoice('ResponseType','Response form',5,1,...
    {'— select —','Real + imaginary','Complex TF','Magnitude + phase'},...
    {'','real-imag','complex','mag-phase'});
addColumn('Response','Complex TF',5,3);
addColumn('Real','Real',6,1);addColumn('Imaginary','Imaginary',6,3);
addColumn('Magnitude','Magnitude',7,1);
addChoice('MagnitudeUnit','Magnitude unit',7,3,{'— select —','Linear','dB'},{'','linear','dB'});
addColumn('Phase','Phase',8,1);
addChoice('PhaseUnit','Phase unit',8,3,{'— select —','Degrees','Radians'},{'','deg','rad'});
optional=uigridlayout(layout,[3 4],'RowHeight',{28,24,'1x'},...
    'ColumnWidth',{125,'1x',125,'1x'},'Padding',[0 4 0 0]);
optional.Layout.Row=9;optional.Layout.Column=[1 4];
label=uilabel(optional,'Text','Weight (optional)');label.Layout.Row=1;label.Layout.Column=1;
controls.Weight=uidropdown(optional,'Items',items,'ItemsData',itemData,'Tag','RIFFImportWeight');
controls.Weight.Layout.Row=1;controls.Weight.Layout.Column=2;
label=uilabel(optional,'Text','Coherence (0–1)');label.Layout.Row=1;label.Layout.Column=3;
controls.Coherence=uidropdown(optional,'Items',items,'ItemsData',itemData,'Tag','RIFFImportCoherence');
controls.Coherence.Layout.Row=1;controls.Coherence.Layout.Column=4;
controls.UseCoherence=uicheckbox(optional,'Text','Use coherence as a fit weight','Value',true,...
    'Tag','RIFFImportUseCoherence');
controls.UseCoherence.Layout.Row=2;controls.UseCoherence.Layout.Column=[1 4];
status=uilabel(optional,'Text','','WordWrap','on','Tag','RIFFImportStatus');
status.Layout.Row=3;status.Layout.Column=[1 4];
validateButton=uibutton(layout,'Text','Check mapping','ButtonPushedFcn',@(~,~)check(false));
validateButton.Layout.Row=10;validateButton.Layout.Column=1;
apply=uibutton(layout,'Text','Apply mapping','Tag','RIFFImportApply',...
    'ButtonPushedFcn',@(~,~)check(true));apply.Layout.Row=10;apply.Layout.Column=4;
cancel=uibutton(layout,'Text','Cancel','ButtonPushedFcn',@(~,~)deleteDialog());
cancel.Layout.Row=10;cancel.Layout.Column=3;
map=info.SuggestedMap;saved=riff_saved_import_map(app,file);
fields=fieldnames(saved);
for n=1:numel(fields),map.(fields{n})=saved.(fields{n});end
fields=fieldnames(controls);
for n=1:numel(fields)
    field=fields{n};value=map.(field);
    if ismember(field,{'Frequency','Response','Real','Imaginary','Magnitude','Phase','Weight','Coherence'})
        if ischar(value)||isstring(value)
            value=find(info.ColumnNames==string(value));
            if ~isscalar(value),value=0;end
        end
    end
    controls.(field).Value=value;
    controls.(field).ValueChangedFcn=@(~,~)update();
end
ui=struct('Figure',fig,'Controls',controls,'Preview',preview,'Status',status,...
    'Apply',apply,'Check',validateButton,'Cancel',cancel,'Source',key);
update();fig.Visible='on';

    function addColumn(field,labelText,row,col)
        label=uilabel(layout,'Text',labelText);label.Layout.Row=row;label.Layout.Column=col;
        controls.(field)=uidropdown(layout,'Items',items,'ItemsData',itemData,...
            'Tag',['RIFFImport' field]);
        controls.(field).Layout.Row=row;controls.(field).Layout.Column=col+1;
    end
    function addChoice(field,labelText,row,col,labels,data)
        label=uilabel(layout,'Text',labelText);label.Layout.Row=row;label.Layout.Column=col;
        controls.(field)=uidropdown(layout,'Items',labels,'ItemsData',data,...
            'Tag',['RIFFImport' field]);
        controls.(field).Layout.Row=row;controls.(field).Layout.Column=col+1;
    end
    function selected=currentMap()
        selected=struct();names=fieldnames(controls);
        for j=1:numel(names),selected.(names{j})=controls.(names{j}).Value;end
        type=selected.ResponseType;
        if ~strcmp(type,'real-imag'),selected.Real=0;selected.Imaginary=0;end
        if ~strcmp(type,'complex'),selected.Response=0;end
        if ~strcmp(type,'mag-phase'),selected.Magnitude=0;selected.Phase=0;end
    end
    function update()
        type=controls.ResponseType.Value;
        controls.Real.Enable=onoff(strcmp(type,'real-imag'));
        controls.Imaginary.Enable=controls.Real.Enable;
        controls.Response.Enable=onoff(strcmp(type,'complex'));
        controls.Magnitude.Enable=onoff(strcmp(type,'mag-phase'));
        controls.Phase.Enable=controls.Magnitude.Enable;
        controls.MagnitudeUnit.Enable=controls.Magnitude.Enable;
        controls.PhaseUnit.Enable=controls.Magnitude.Enable;
        check(false);
    end
    function check(saveMapping)
        try
            fresh=info;
            if saveMapping,fresh=riff_inspect_measurement(key);end
            if ~isequal(fresh.ColumnNames,info.ColumnNames)
                error('RIFF:ColumnMap','The file columns changed. Close and reopen Map columns to review the new layout.');
            end
            selected=currentMap();data=riff_import_measurement(fresh.Table,selected);
            count=sum(data.EffectiveWeight==0);
            status.Text=sprintf('%d samples | %.6g–%.6g Hz | %d DC rows removed | %d zero weights',...
                numel(data.F),min(data.F),max(data.F),numel(data.DroppedDCRows),count);
            status.FontColor=[0.1 0.55 0.25];apply.Enable='on';
            if saveMapping
                % Store names so reordered/replaced files cannot silently reuse indices.
                fields={'Frequency','Response','Real','Imaginary','Magnitude','Phase','Weight','Coherence'};
                for k=1:numel(fields)
                    role=fields{k};index=selected.(role);
                    if index>0,selected.(role)=char(fresh.ColumnNames(index));end
                end
                if isappdata(app.UIFigure,'RIFFImportMaps')
                    cache=getappdata(app.UIFigure,'RIFFImportMaps');
                else
                    cache=containers.Map('KeyType','char','ValueType','any');
                end
                cache(key)=selected;setappdata(app.UIFigure,'RIFFImportMaps',cache);
                app.FORMATDropDown.Value='Auto / mapped';deleteDialog();
            end
        catch exception
            status.Text=exception.message;status.FontColor=[0.8 0.25 0.15];apply.Enable='off';
        end
    end
    function deleteDialog()
        if isgraphics(fig),delete(fig);end
    end
    function value=onoff(flag)
        value='off';if flag,value='on';end
    end
end

function unit=riff_import_units(role,name)
key=lower(regexprep(string(name),'[^a-zA-Z0-9]',''));unit='';
switch role
    case 'Frequency'
        if ismember(key,["w","omega"]) || ...
                (endsWith(key,'rads') && ~endsWith(key,{'krads','mrads','grads'}))
            unit='rad/s';
        elseif key=="f" || (endsWith(key,'hz') && ~endsWith(key,{'khz','mhz','ghz','thz'}))
            unit='Hz';
        end
    case 'Magnitude'
        if endsWith(key,'db'),unit='dB';elseif endsWith(key,'linear'),unit='linear';end
    case 'Phase'
        if endsWith(key,{'deg','degrees'}),unit='deg';elseif endsWith(key,{'rad','radians'}),unit='rad';end
end
end
