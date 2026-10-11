classdef fitTFPlotTest < matlab.unittest.TestCase
    % Regression coverage for RIFF's public preview and fit workflows.
    properties
        App
    end

    properties (TestParameter)
        previewVisible = struct('hidden',false,'visible',true)
        frequencyUnits = struct('hertz','Hz','radians','rad/s')
    end

    methods (TestClassSetup)
        function addSourceFolder(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(...
                fullfile(root,'src')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(...
                fullfile(root,'src','utils')));
        end
    end

    methods (TestMethodSetup)
        function prepareApp(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            copyfile(fullfile(root,'measured_TFs'),'measured_TFs');
            priorFigures = findall(groot,'Type','figure');
            testCase.addTeardown(@() delete(setdiff(...
                findall(groot,'Type','figure'),priorFigures)));
            warningState = warning;
            testCase.addTeardown(@() warning(warningState));
            randomState = rng;
            testCase.addTeardown(@() rng(randomState));
            rng(42,'twister');
            testCase.App = RIFF;
            testCase.addTeardown(@() delete(testCase.App));
            testCase.App.UIFigure.Visible = 'off';
            testCase.App.FIG_HANDLE_VISIBILITYCheckBox.Value = false;
            testCase.App.FIT_WEIGHT_FROM_PHASE_SMOOTHNESSCheckBox.Value = false;
            testCase.App.F_INITIALEditField.Value = 0.1;
            testCase.App.F_FINALEditField.Value = 10;
        end
    end

    methods (Test)
        function textPreviewCallback(testCase,previewVisible)
            testCase.App.ChooseTFListBox.Value = 'damped_transmission.txt';
            testCase.App.FIG_HANDLE_VISIBILITYCheckBox.Value = previewVisible;
            sentinel = uint8(73*ones(3,3,3));
            imwrite(sentinel,'temp.png');
            callback = testCase.App.PreviewBodeplotButton.ButtonPushedFcn;
            initialPath = path;

            callback(testCase.App.PreviewBodeplotButton,[]);

            testCase.verifyNotEmpty(findobj(testCase.App.UIAxes,'Type','image'));
            testCase.verifyEqual(testCase.App.Lamp.Color,[0 1 0],'AbsTol',eps);
            testCase.verifyEqual(imread('temp.png'),sentinel);
            testCase.verifyEqual(path,initialPath);
            testCase.verifyNumElements(testCase.plotFigures(),double(previewVisible));
        end

        function previewFrequencyLimits(testCase,frequencyUnits)
            f = logspace(-1,2,80)';
            response = 1./(1 + 1i*2*pi*f);
            options = bodeoptions;
            options.FreqUnits = frequencyUnits;
            testCase.App.FIG_HANDLE_VISIBILITYCheckBox.Value = true;
            testCase.App.F_INITIALEditField.Value = 0.01;
            testCase.App.F_FINALEditField.Value = 10;

            fitTF('APP',testCase.App,'F',f,'TF',response,...
                'BODEOPTIONS',options,'PREVIEW_BODEPLOT_TOGGLE',1);

            expected = chgFreqUnit(frd(ones(2,1),[0.1;10],...
                'FrequencyUnit','Hz'),frequencyUnits);
            testCase.verifyEqual(testCase.plotXLimits(),...
                expected.Frequency','RelTol',1e-10);
        end

        function previewHandlesZeroMagnitude(testCase)
            f = logspace(-1,1,80)';
            testCase.App.FIG_HANDLE_VISIBILITYCheckBox.Value = true;

            fitTF('APP',testCase.App,'F',f,'TF',zeros(size(f)),...
                'PREVIEW_BODEPLOT_TOGGLE',1);

            testCase.verifyNotEmpty(findobj(testCase.App.UIAxes,'Type','image'));
            testCase.verifyNumElements(testCase.plotFigures(),1);
        end

        function intermediateComparisonWithMetadata(testCase)
            best = tf(1,[1 1]);
            current = tf(1,[1 2]);
            current.UserData = struct('instrument','example');
            saved = testCase.savedResult(best,current);

            fitTF('POST_PROCESS_RESULT_VARIABLE',saved,...
                'VIEW_INTERMEDIATE_BODEPLOT_TOGGLE',1);

            testCase.verifyNumElements(testCase.plotFigures(),1);
            testCase.verifyTrue(any(contains(testCase.plotLabels(),'Best Fit')));
            testCase.verifyFalse(any(contains(testCase.plotLabels(),'uncertainty')));
        end

        function intermediateUncertaintySamples(testCase)
            model = idtf(1,[1 1]);
            model = setcov(model,1e-6*eye(numel(getpvec(model))));
            saved = testCase.savedResult(model,model);

            fitTF('POST_PROCESS_RESULT_VARIABLE',saved,...
                'VIEW_INTERMEDIATE_BODEPLOT_TOGGLE',1);

            testCase.verifyTrue(any(contains(testCase.plotLabels(),...
                'Parameter uncertainty samples')));
        end

        function commandLineFitAndExport(testCase)
            f = logspace(-1,1,80)';
            response = 1./(1 + 1i*2*pi*f);
            warning('on','MATLAB:singularMatrix');

            result = fitTF('F',f,'TF',response,'routine',3,...
                'MIN_POLES',1,'MAX_POLES',1,'NUM_TRIALS',1,...
                'FUNC_EVAL',10,'OPTIMIZER','FMINCON',...
                'ESTIMATE_UNCERTAINITY',0,'DAMP_RESONANCES',0,...
                'INTERMEDIATE_PLOT',1,'DISPLAY_ZPK',1,...
                'FIG_HANDLE_VISIBILITY',0,'SAVE_TOGGLE',1,...
                'SAVETO',fullfile(pwd,'exported'));

            testCase.verifyGreaterThan(result.gof,99);
            testCase.verifyTrue(isstable(result.FRD_Model.modeled));
            warningState = warning('query','MATLAB:singularMatrix');
            testCase.verifyEqual(warningState.state,'on');
            testCase.verifyResponseCurves(gcf);
            testCase.verifyNumElements(dir(fullfile('exported','*','bode_plot.png')),1);
            testCase.verifyNumElements(dir(fullfile('exported','*','bode_plot.fig')),1);
            testCase.verifyNumElements(dir(fullfile('exported','*','FIT.mat')),1);
        end

        function appFitCallbackAndExport(testCase)
            f = logspace(-1,1,80)';
            response = 1./(1 + 1i*2*pi*f);
            writematrix([f,real(response),imag(response)],...
                fullfile('measured_TFs','fit_response.txt'),'Delimiter','tab');
            testCase.App.ChooseTFListBox.Items = ...
                [testCase.App.ChooseTFListBox.Items,{'fit_response.txt'}];
            testCase.App.ChooseTFListBox.Value = 'fit_response.txt';
            testCase.App.Tree.CheckedNodes = testCase.App.invfreqsNode;
            testCase.App.OPTIMIZERDropDown.Value = 'FMINCON';
            testCase.App.MIN_POLESEditField.Value = 1;
            testCase.App.MAX_POLESEditField.Value = 1;
            testCase.App.NUM_TRIALSEditField.Value = 1;
            testCase.App.ESTIMATE_UNCERTAINITYCheckBox.Value = false;
            testCase.App.INTERMEDIATE_PLOTCheckBox.Value = true;
            testCase.App.EXPORT_TO_WORKSPACECheckBox.Value = false;
            testCase.App.SAVE_TOGGLECheckBox.Value = true;
            testCase.App.SAVETOEditField.Value = fullfile(pwd,'app_exported');
            callback = testCase.App.FITButton.ButtonPushedFcn;

            callback(testCase.App.FITButton,[]);

            testCase.verifyNotEmpty(findobj(testCase.App.UIAxes,'Type','image'));
            testCase.verifyEqual(testCase.App.Lamp.Color,[0 1 0],'AbsTol',eps);
            files = dir(fullfile('app_exported','*','bode_plot.fig'));
            testCase.assertNumElements(files,1);
            savedFigure = openfig(fullfile(files.folder,files.name),'invisible');
            testCase.verifyResponseCurves(savedFigure);
            savedData = load(fullfile(files.folder,'FIT.mat'),'FIT');
            testCase.verifyGreaterThan(savedData.FIT.gof,99);
            testCase.verifyEmpty(findall(savedFigure,'Type','uibutton'));
            testCase.verifyNotEmpty(findall(savedFigure,'Type','textboxshape'));
        end
    end

    methods (Access=private)
        function verifyResponseCurves(testCase,fig)
            if isa(fig.CurrentAxes,'controllib.chart.BodePlot')
                testCase.verifyGreaterThanOrEqual(numel(fig.CurrentAxes.Responses),4);
            else
                curves = findall(fig,'Type','line','Visible','on');
                pointCounts = arrayfun(@(line) numel(line.XData),curves);
                testCase.verifyGreaterThanOrEqual(nnz(pointCounts > 2),8);
            end
        end

        function figures = plotFigures(~)
            figures = findall(groot,'Type','figure','Name','System Identification');
        end

        function limits = plotXLimits(testCase)
            fig = testCase.plotFigures();
            testCase.assertNumElements(fig,1);
            if isa(fig.CurrentAxes,'controllib.chart.BodePlot')
                limits = getoptions(fig.CurrentAxes,'XLim');
                if iscell(limits)
                    limits = limits{1};
                end
            else
                axesList = findall(fig,'Type','axes','XScale','log');
                limits = axesList(1).XLim;
            end
        end

        function labels = plotLabels(testCase)
            fig = testCase.plotFigures();
            testCase.assertNumElements(fig,1);
            lgnd = findall(fig,'Type','legend');
            labels = string(lgnd(1).String);
        end
    end

    methods (Static,Access=private)
        function saved = savedResult(best,current)
            f = logspace(-1,1,80)';
            measurement = frd(best,2*pi*f);
            saved.frequency.measured = f;
            saved.FRD_Model.measured_original = measurement;
            saved.FRD_Model.measured_smoothed = measurement;
            saved.FRD_Model.truncated = measurement;
            saved.FRD_Model.modeled = best;
            saved.options.BodeOptions = bodeoptions;
            saved.options.BodeOptions.FreqUnits = 'Hz';
            saved.options.BodeOptions.PhaseWrapping = 'on';
            saved.intermediate.GOF = 95;
            saved.intermediate.FRD_Model.modeled = current;
            [saved.ZPK.z,saved.ZPK.p,saved.ZPK.k] = zpkdata(best,'v');
            saved.IODelay = 0;
            saved.gof = 100;
        end
    end
end
