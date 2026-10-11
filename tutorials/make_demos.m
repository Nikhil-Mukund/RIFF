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
f = logspace(log10(0.05),log10(20),180)';
plant = zpk([-2+3i;-2-3i],[-1+2i;-1-2i;-5],2);
h = squeeze(freqresp(plant,2*pi*f));
h = h.*(1+0.004*sin(3*log(f))).*exp(0.004i*cos(2*log(f)));
writematrix([f real(h) imag(h)],fullfile('measured_TFs','demo_response.csv'));
app = RIFF; appCleanup = onCleanup(@()delete(app));
% Preserve the app's default 1299-by-693 layout; do not maximize/resize.
app.EXPORT_TO_WORKSPACECheckBox.Value = true;
app.EXPORT_VARIABLE_NAMEEditField.Value = 'RIFF_DEMO_FIT';
app.FIT_RESULT_VARIABLEEditField.Value = 'RIFF_DEMO_FIT';
app.SAVE_TOGGLECheckBox.Value = false;
app.FIG_HANDLE_VISIBILITYCheckBox.Value = false;
app.FIT_WEIGHT_FROM_PHASE_SMOOTHNESSCheckBox.Value = false;
app.F_INITIALEditField.Value = 0.05; app.F_FINALEditField.Value = 20;
app.F_INITIAL_toggleCheckBox.Value = true; app.F_FINAL_toggleCheckBox.Value = true;
app.ChooseTFListBox.Value = 'demo_response.csv';
app.FORMATDropDown.Value = 'f a b';
app.OPTIMIZERDropDown.Value = 'FMINCON';
app.MIN_POLESEditField.Value = 3; app.MAX_POLESEditField.Value = 3;
app.NUM_ZEROSEditField.Value = 2;
app.NUM_TRIALSEditField.Value = 2;
app.INTERMEDIATE_PLOTCheckBox.Value = true;
manifest = struct('Clip',{},'File',{},'Seconds',{},'Caption',{});
app.TabGroup.SelectedTab = app.InputTab;
snap('fitting',3,'1  Select frequency/real/imaginary data (synthetic example)');
invoke(app.PreviewBodeplotButton);
snap('fitting',4,'2  Preview: native Bode plots stay inside the app');
app.TabGroup.SelectedTab = app.FittingTab;
app.Tree.CheckedNodes = [app.tfestNode,app.AAANode];
expand(app.FITTING_ROUTINESNode);
snap('fitting',4,'3  Defaults: SysID AAA + N4SID-initialized tfest');
invoke(app.FITButton);
app.TabGroup.SelectedTab = app.VerifyTab;
selectTrial(0);
result = evalin('base','RIFF_DEMO_FIT');
snap('fitting',5,sprintf('4  Best fit: GOF %.2f%% | computation wait omitted',result.gof));
plotTab = findall(app.RightPanel,'Tag','RIFFBodeTab');
chart = findall(plotTab,'-isa','controllib.chart.BodePlot');
setoptions(chart,'XLim',{[0.1 1]});
snap('fitting',4,'5  Inspect the resonance with the embedded chart controls');
setoptions(chart,'XLim',{[0.05 20]});
snap('fitting',3,'6  Restore the frequency range; standalone exports remain available');

app.TabGroup.SelectedTab = app.VerifyTab;
selectTrial(1); chooseRight('RIFFParametersTab');
snap('refinement',4,'1  Verify trial 1: the model parameters follow the selected fit');
selectTrial(2); chooseRight('RIFFParametersTab');
snap('refinement',4,'2  Switch to trial 2: its poles, zeros and gain are shown');
selectTrial(0); chooseRight('RIFFEditorTab');
editor = getappdata(app.UIFigure,'RIFFModelEditor');
original = editor.getModel();
snap('refinement',4,'3  Start from the best fit; originals are preserved');
poles = pole(original); poleID = find(imag(poles)>0,1);
assert(~isempty(poleID),'Expected a conjugate pole pair in the demo fit.');
start = poles(poleID); finish = complex(real(start)*0.8,imag(start)*1.1);
editor.RootSelector.Value = poleID;
callback = editor.RootSelector.ValueChangedFcn; callback(editor.RootSelector,[]);
zoomButton = findall(app.RightPanel,'Text','Zoom to root'); invoke(zoomButton);
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
assert(abs(adjusted(poleID)-finish)<0.05,'Pole drag did not reach the selected root.');
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
snap('measurements',4,'5  Continue with the same AAA + tfest fitting workflow');

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
end
function invoke(button)
callback=button.ButtonPushedFcn;callback(button,[]);
end
function restore(oldPath,oldFolder,oldRandom)
path(oldPath);cd(oldFolder);rng(oldRandom);
end
