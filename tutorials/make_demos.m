function make_demos(outputFolder)
%MAKE_DEMOS Capture reproducible walkthrough frames from the actual RIFF app.
%   make_demos(fullfile(tempdir,'riff-demos'))
%   Then run encode_demos.py to create captioned, compact MP4s and posters.
%   These are scripted walkthroughs: computation waits are omitted.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1, outputFolder = fullfile(tempdir,'riff-demos'); end
if ~isfolder(outputFolder), mkdir(outputFolder); end
oldPath = path; oldFolder = pwd; oldRandom = rng;
cleanup = onCleanup(@()restore(oldPath,oldFolder,oldRandom));
addpath(fullfile(root,'src'),fullfile(root,'src','utils'),'-begin');
work = tempname; mkdir(work); cd(work);
copyfile(fullfile(root,'measured_TFs'),'measured_TFs');
rng(42,'twister');
% Use the difficult bundled measurement, including its real noise and wraps.
% Fit the broad useful band; retain out-of-band data in the overview plots.
measurement = 'isolated_transmission.txt';
fitRange = [0.04 20]; overviewRange = [0.03 40];
app = RIFF; appCleanup = onCleanup(@()delete(app));
% Preserve the app's default 1299-by-693 layout; do not maximize/resize.
app.EXPORT_TO_WORKSPACECheckBox.Value = true;
app.EXPORT_VARIABLE_NAMEEditField.Value = 'RIFF_DEMO_FIT';
app.FIT_RESULT_VARIABLEEditField.Value = 'RIFF_DEMO_FIT';
app.SAVE_TOGGLECheckBox.Value = false;
app.FIG_HANDLE_VISIBILITYCheckBox.Value = false;
app.FIT_WEIGHT_FROM_PHASE_SMOOTHNESSCheckBox.Value = false;
app.F_INITIALEditField.Value = fitRange(1); app.F_FINALEditField.Value = fitRange(2);
app.F_INITIAL_toggleCheckBox.Value = true; app.F_FINAL_toggleCheckBox.Value = true;
app.SMOOTH_LEVELEditField.Value = 7;
app.SMOOTH_WIN_LENSlider.Value = 7;
app.ChooseTFListBox.Value = measurement;
app.FORMATDropDown.Value = 'f a b';
app.OPTIMIZERDropDown.Value = 'FMINCON';
app.MIN_POLESEditField.Value = 12; app.MAX_POLESEditField.Value = 24;
app.NUM_ZEROSEditField.Value = 23;
app.NUM_TRIALSEditField.Value = 4;
app.INTERMEDIATE_PLOTCheckBox.Value = true;
manifest = struct('Clip',{},'File',{},'Seconds',{},'Caption',{});
app.TabGroup.SelectedTab = app.InputTab;
snap('fitting',3,'1  Open isolated_transmission.txt: a difficult bundled measurement');
invoke(app.PreviewBodeplotButton);
setOverview();
snap('fitting',4,'2  Broadband preview: deep notches, resonances, noise and phase wraps');
app.TabGroup.SelectedTab = app.FreqTab;
snap('fitting',4,'3  Fit 0.04-20 Hz; smooth over 7 samples; retain the noisy tail for context');
app.TabGroup.SelectedTab = app.FittingTab;
app.Tree.CheckedNodes = [app.tfestNode,app.AAANode];
expand(app.FITTING_ROUTINESNode);
snap('fitting',4,'4  AAA + tfest: four trials, 12-24 poles, stability enforced');
invoke(app.FITButton);
app.TabGroup.SelectedTab = app.VerifyTab;
selectTrial(0);
result = evalin('base','RIFF_DEMO_FIT');
setOverview();
snap('fitting',6,sprintf('5  Best fit: order %d, GOF %.2f%% | computation waits omitted',...
    order(result.FRD_Model.modeled),result.gof));
plotTab = findall(app.RightPanel,'Tag','RIFFBodeTab');
chart = findall(plotTab,'-isa','controllib.chart.BodePlot');
setoptions(chart,'XLim',{[0.5 2]});
snap('fitting',3,'6  Briefly zoom into the deep notch with the embedded chart controls');
setOverview();
snap('fitting',5,'7  Restore the broad view; the achieved fit and remaining mismatches are visible');

% Keep a fit and its settings with the raw captures for inspection/reproduction.
recordedFit = result; recordedFit.APP = [];
save(fullfile(outputFolder,'recorded-fit.mat'),'recordedFit');
settings = struct('measurement',measurement,'requested_band_hz',fitRange,...
    'overview_band_hz',overviewRange,'optimized_band_hz',...
    [result.options.Optimization.F_Start result.options.Optimization.F_Stop],...
    'algorithm',result.options.Optimization.FINAL_FIT_ROUTINE,...
    'order',order(result.FRD_Model.modeled),'gof',result.gof,...
    'winning_weight',result.options.Optimization.FINAL_WEIGHTING_FILTER,...
    'stable',isstable(result.FRD_Model.modeled),...
    'optimizer',app.OPTIMIZERDropDown.Value,...
    'function_evaluations',result.options.FUNC_EVAL,...
    'pole_bounds',[app.MIN_POLESEditField.Value app.MAX_POLESEditField.Value],...
    'max_tfest_zeros',app.NUM_ZEROSEditField.Value,...
    'smoothing_method',7,'smoothing_samples',7,'trials',4,'seed',42);
file = fopen(fullfile(outputFolder,'fit-settings.json'),'w');
fprintf(file,'%s\n',jsonencode(settings,PrettyPrint=true)); fclose(file);

app.TabGroup.SelectedTab = app.VerifyTab;
selectTrial(1); chooseRight('RIFFParametersTab');
snap('refinement',4,'1  Verify trial 1: the model parameters follow the selected fit');
selectTrial(2); chooseRight('RIFFParametersTab');
snap('refinement',4,'2  Switch to trial 2: its poles, zeros and gain are shown');
selectTrial(0); chooseRight('RIFFEditorTab');
editor = getappdata(app.UIFigure,'RIFFModelEditor');
original = editor.getModel();
snap('refinement',4,'3  Refine the same broadband measured response; originals are preserved');
poles = pole(original); candidates = find(imag(poles)>0);
% Choose the pair nearest the measured high-frequency resonance, in rad/s.
[~,nearest] = min(abs(imag(poles(candidates))-2*pi*17.7));
poleID = candidates(nearest);
assert(~isempty(poleID),'Expected a conjugate pole pair in the demo fit.');
start = poles(poleID); finish = complex(real(start)*0.85,imag(start)*1.04);
editor.RootSelector.Value = poleID;
callback = editor.RootSelector.ValueChangedFcn; callback(editor.RootSelector,[]);
zoomButton = findall(app.RightPanel,'Text','Zoom to root'); invoke(zoomButton);
% Near-cancelled roots need a closer horizontal view than the default zoom.
% Separate their markers so the gesture hits the selected pole, not a zero.
editor.PoleAxes.XLim = real(start)+[-2 2];
radius = max(1,1.5*abs(finish-start));
editor.PoleAxes.YLim = imag(start)+[-radius radius];
snap('refinement',3,'4  Select a pole and use Zoom to root for precise movement');
ui = matlab.uitest.TestCase.forInteractiveUse;
previous = start;
for fraction = linspace(0.1,1,10)
    target = start + fraction*(finish-start);
    ui.drag(editor.PoleAxes,[real(previous) imag(previous)],[real(target) imag(target)]);
    updated = pole(editor.getModel());
    [~,nearest] = min(abs(updated-target)); previous = updated(nearest);
    snap('refinement',0.18,'5  Drag a pole: its conjugate and Bode response update together');
end
adjusted = pole(editor.getModel());
assert(abs(adjusted(poleID)-finish)<max(0.05,abs(start)*0.005),...
    'Pole drag did not reach the selected root within gesture resolution.');
[~,pairID] = min(abs(poles-conj(start)));
assert(abs(adjusted(pairID)-conj(adjusted(poleID)))<1e-8,'Conjugate did not follow drag.');
snap('refinement',3,'6  Inspect the manual response and GOF before accepting it');
editor.setGain(original.K*1.15);
snap('refinement',3,'7  Gain and numeric coordinates can also be adjusted');
reset = findall(app.RightPanel,'Tag','RIFFResetModel'); invoke(reset);
assert(isequal(editor.getModel(),original));
snap('refinement',4,'8  Reset this fit restores its original model');

app.TabGroup.SelectedTab = app.InputTab;
app.INPUT_DATA_FORMATDropDown.Value = 'HP_Agilent_Keysight_SDF';
callback=app.INPUT_DATA_FORMATDropDown.ValueChangedFcn;
callback(app.INPUT_DATA_FORMATDropDown,[]);
app.ChooseTFListBox_2.Value = {'N3_500Hz_10KHz.DAT'};
app.F_INITIALEditField.Value = 0.02; app.F_FINALEditField.Value = 29000;
invoke(app.PreviewBodeplotButton);
snap('measurements',3,'1  Open the spectrum-analyzer input: bundled SDF measurements');
app.ChooseTFListBox_2.Value = {'N3_500Hz_10KHz.DAT','N1_100mHz_100Hz.DAT','N2_50Hz_1500Hz.DAT'};
app.F_INITIALEditField.Value = 0.02; app.F_FINALEditField.Value = 29000;
snap('measurements',4,'2  Multi-select all three bands; selection order does not matter');
invoke(app.PreviewBodeplotButton);
snap('measurements',5,'3  Preview the combined response; overlapping complex samples are averaged');
app.TabGroup.SelectedTab = app.FreqTab;
app.F_INITIALEditField.Value = 20; app.F_FINALEditField.Value = 2000;
invoke(app.PreviewBodeplotButton);
snap('measurements',4,'4  Choose the frequency region to inspect or fit');
app.TabGroup.SelectedTab = app.FittingTab;
app.F_INITIALEditField.Value = 0.02; app.F_FINALEditField.Value = 29000;
invoke(app.PreviewBodeplotButton);
snap('measurements',4,'5  Restore all joined bands: the broadband measurement remains available');

writetable(struct2table(manifest),fullfile(outputFolder,'frames.csv'));
evalin('base','clear RIFF_DEMO_FIT');
fprintf('Captured %d genuine app frames in %s\n',numel(manifest),outputFolder);
clear appCleanup cleanup

    function snap(clip,seconds,caption)
        folder=fullfile(outputFolder,clip);if ~isfolder(folder),mkdir(folder);end
        n=sum(strcmp({manifest.Clip},clip))+1;
        relative=sprintf('%s/frame%03d.png',clip,n);
        drawnow;
        exportapp(app.UIFigure,fullfile(outputFolder,relative));
        manifest(end+1)=struct('Clip',clip,'File',relative,'Seconds',seconds,'Caption',caption);
    end
    function selectTrial(index)
        app.IntermediateResultIDSpinner.Value=index;
        callback=app.IntermediateResultIDSpinner.ValueChangedFcn;
        callback(app.IntermediateResultIDSpinner,[]);
        chooseRight('RIFFBodeTab');
    end
    function chooseRight(tag)
        tab=findall(app.RightPanel,'Tag',tag);tab.Parent.SelectedTab=tab;
    end
    function setOverview()
        tab=findall(app.RightPanel,'Tag','RIFFBodeTab');
        chart=findall(tab,'-isa','controllib.chart.BodePlot');
        setoptions(chart,'XLim',{overviewRange});
    end
end
function invoke(button)
callback=button.ButtonPushedFcn;callback(button,[]);
end
function restore(oldPath,oldFolder,oldRandom)
path(oldPath);cd(oldFolder);rng(oldRandom);
end
