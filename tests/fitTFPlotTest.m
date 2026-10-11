classdef fitTFPlotTest < matlab.unittest.TestCase
    % Regression coverage for RIFF's public preview and fit workflows.
    properties
        App
    end

    properties (TestParameter)
        previewVisible = struct('hidden',false,'visible',true)
        frequencyUnits = struct('hertz','Hz','radians','rad/s')
        fittingRoutine = struct('invfreqs','invfreqsNode','aaa','AAANode')
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

            testCase.verifyAppPlot();
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

            testCase.verifyAppPlot();
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

        function appFitCallbackAndExport(testCase,fittingRoutine)
            f = logspace(-1,1,80)';
            response = 1./(1 + 1i*2*pi*f);
            writematrix([f,real(response),imag(response)],...
                fullfile('measured_TFs','fit_response.txt'),'Delimiter','tab');
            testCase.App.ChooseTFListBox.Items = ...
                [testCase.App.ChooseTFListBox.Items,{'fit_response.txt'}];
            testCase.App.ChooseTFListBox.Value = 'fit_response.txt';
            testCase.App.Tree.CheckedNodes = testCase.App.(fittingRoutine);
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

            testCase.verifyAppPlot();
            testCase.verifyEqual(testCase.App.Lamp.Color,[0 1 0],'AbsTol',eps);
            testCase.verifyNativeFigureCleanup();
            files = dir(fullfile('app_exported','*','bode_plot.fig'));
            testCase.assertNumElements(files,1);
            savedFigure = openfig(fullfile(files.folder,files.name),'invisible');
            testCase.verifyResponseCurves(savedFigure);
            savedData = load(fullfile(files.folder,'FIT.mat'),'FIT');
            testCase.verifyGreaterThan(savedData.FIT.gof,99);
            testCase.verifyEmpty(findall(savedFigure,'Type','uibutton'));
            testCase.verifyNotEmpty(findall(savedFigure,'Type','textboxshape'));
            testCase.verifyFittedEditsSurviveVerification();
        end
    end

    methods (Test,TestTags={'NativeCharts'})
        function embeddedZoomAndRefresh(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.App.ChooseTFListBox.Value = 'damped_transmission.txt';
            callback = testCase.App.PreviewBodeplotButton.ButtonPushedFcn;
            callback(testCase.App.PreviewBodeplotButton,[]);
            chart = testCase.embeddedChart();
            initialResponses = chart.Responses;

            setoptions(chart,'XLim',[1 2]);
            drawnow;

            testCase.verifyEqual(getoptions(chart,'XLim'),{[1 2]},'AbsTol',1e-10);
            testCase.verifyEqual(chart.Responses,initialResponses);
            testCase.verifyEqual(string(chart.ToolbarVisible),"on");
            testCase.verifyEmpty(testCase.plotFigures());

            testCase.App.F_FINALEditField.Value = 5;
            callback(testCase.App.PreviewBodeplotButton,[]);

            testCase.verifyFalse(isvalid(chart));
            chart = testCase.embeddedChart();
            testCase.verifyEqual(getoptions(chart,'XLim'),{[0.1 5]},'AbsTol',1e-10);
            testCase.verifyEmpty(testCase.plotFigures());
        end

        function embeddedResize(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.App.ChooseTFListBox.Value = 'damped_transmission.txt';
            testCase.App.UIFigure.Visible = 'on';
            callback = testCase.App.PreviewBodeplotButton.ButtonPushedFcn;
            callback(testCase.App.PreviewBodeplotButton,[]);
            panel = findobj(testCase.App.RightPanel,'Tag','RIFFInteractivePlot');
            testCase.verifyPlotFitsPanel(panel);

            testCase.App.UIFigure.Position(3:4) = [1100 800];
            drawnow;

            testCase.verifyPlotFitsPanel(panel);
            testCase.verifyAppPlot();

            testCase.App.UIFigure.Position(3:4) = [500 800];
            drawnow;

            testCase.verifyThat(@() testCase.App.RightPanel.Layout.Row,...
                matlab.unittest.constraints.Eventually(...
                matlab.unittest.constraints.IsEqualTo(2),'WithTimeoutOf',10));
            testCase.verifyPlotFitsPanel(panel);
            testCase.verifyAppPlot();
        end

        function embeddedFitDetailsAndUncertainty(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            model = idtf(1,[1 1]);
            model = setcov(model,1e-6*eye(numel(getpvec(model))));
            saved = testCase.savedResult(model,model);

            fitTF('APP',testCase.App,'POST_PROCESS_RESULT_VARIABLE',saved,...
                'VIEW_INTERMEDIATE_BODEPLOT_TOGGLE',1);

            chart = testCase.embeddedChart();
            testCase.verifyNumElements(chart.Responses,5);
            testCase.verifyEqual(chart.Responses(end).Name,"Parameter uncertainty samples");
            details = findobj(testCase.App.RightPanel,'Tag','RIFFParameterText');
            testCase.assertNumElements(details,1);
            testCase.verifyTrue(any(contains(string(details.Value),'Delay')));
            testCase.verifyEmpty(findall(testCase.App.UIFigure,'Type','textboxshape'));
            testCase.verifyEmpty(testCase.plotFigures());
        end

        function filteringCanReplaceEmbeddedPlot(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.App.ChooseTFListBox.Value = 'damped_transmission.txt';
            imageData = uint8(73*ones(3,3,3));
            % Stand in for the image produced by the time-domain callback.
            testCase.App.FilterTimeSeriesButton.ButtonPushedFcn = ...
                @(~,~) imshow(imageData,'Parent',testCase.App.UIAxes);
            preview = testCase.App.PreviewBodeplotButton.ButtonPushedFcn;
            preview(testCase.App.PreviewBodeplotButton,[]);
            panel = findobj(testCase.App.RightPanel,'Tag','RIFFInteractivePlot');
            filter = testCase.App.FilterTimeSeriesButton.ButtonPushedFcn;

            filter(testCase.App.FilterTimeSeriesButton,[]);

            testCase.verifyEqual(string(panel.Visible),"off");
            displayed = findobj(testCase.App.UIAxes,'Type','image');
            testCase.verifyEqual(displayed.CData,imageData);

            preview(testCase.App.PreviewBodeplotButton,[]);

            testCase.verifyEqual(string(panel.Visible),"on");
            testCase.verifyAppPlot();
            testCase.verifyEmpty(testCase.plotFigures());
        end
    end

    methods (Access=private)
        function verifyFittedEditsSurviveVerification(testCase)
            if verLessThan('matlab','24.2'), return; end
            editor = getappdata(testCase.App.UIFigure,'RIFFModelEditor');
            testCase.assertClass(editor,'struct');
            testCase.assertTrue(editor.isValid());
            model = editor.getModel();
            editor.setGain(model.K*1.1);
            adjusted = editor.getModel();
            testCase.App.FIT_RESULT_VARIABLEEditField.Value = 'RIFF_TEST_NO_WORKSPACE_EXPORT';
            callback = testCase.App.IntermediateResultIDSpinner.ValueChangedFcn;
            testCase.App.IntermediateResultIDSpinner.Value = 1;
            callback(testCase.App.IntermediateResultIDSpinner,[]);
            testCase.verifyEqual(getappdata(testCase.App.UIFigure,'RIFFModelEditor'),editor);
            testCase.App.IntermediateResultIDSpinner.Value = 0;
            callback(testCase.App.IntermediateResultIDSpinner,[]);
            testCase.verifyEqual(editor.getModel(),adjusted);
        end

        function verifyPlotFitsPanel(testCase,panel)
            testCase.verifyThat(@() testCase.plotFitsPanel(panel),...
                matlab.unittest.constraints.Eventually(...
                matlab.unittest.constraints.IsTrue,'WithTimeoutOf',10));
        end

        function fits = plotFitsPanel(testCase,panel)
            bounds = getpixelposition(panel);
            parentBounds = getpixelposition(testCase.App.RightPanel);
            chart = testCase.embeddedChart();
            tabBounds = getpixelposition(chart.Parent);
            fits = all(bounds(3:4) > 0.8*parentBounds(3:4)) && ...
                all(bounds(3:4) < parentBounds(3:4)) && ...
                all(tabBounds(3:4) > 0.8*bounds(3:4));
        end

        function chart = embeddedChart(testCase)
            plotTab = findobj(testCase.App.RightPanel,'Tag','RIFFBodeTab');
            chart = findall(plotTab,'-isa','controllib.chart.BodePlot');
            testCase.assertNumElements(chart,1);
        end

        function verifyNativeFigureCleanup(testCase)
            if ~verLessThan('matlab','24.2')
                testCase.verifyEmpty(testCase.plotFigures());
            end
        end

        function verifyAppPlot(testCase)
            if verLessThan('matlab','24.2')
                testCase.verifyNotEmpty(findobj(testCase.App.UIAxes,'Type','image'));
            else
                plotTab = findobj(testCase.App.RightPanel,'Tag','RIFFBodeTab');
                chart = findall(plotTab,'-isa','controllib.chart.BodePlot');
                testCase.assertNumElements(chart,1);
                testCase.verifyEmpty(findobj(testCase.App.UIAxes,'Type','image'));
                testCase.verifyEqual(ancestor(chart,'figure'),testCase.App.UIFigure);
            end
        end

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
