classdef RIFFModelEditorTest < matlab.uitest.TestCase
    % Interaction and numerical regression tests for manual model tuning.
    properties
        App
        Saved
    end
    methods (TestClassSetup)
        function addSources(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src','utils')));
        end
    end
    methods (TestMethodSetup)
        function prepareApp(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            copyfile(fullfile(root,'measured_TFs'),'measured_TFs');
            testCase.App = RIFF;
            testCase.addTeardown(@() delete(testCase.App));
            testCase.App.UIFigure.Visible = 'off';
            testCase.App.FIT_RESULT_VARIABLEEditField.Value = 'RIFF_EDITOR_TEST_FIT';
            testCase.App.EXPORT_VARIABLE_NAMEEditField.Value = 'RIFF_EDITOR_TEST';
            testCase.Saved = testCase.exampleFit();
            assignin('base','RIFF_EDITOR_TEST_FIT',testCase.Saved);
            testCase.addTeardown(@() evalin('base',...
                'clear RIFF_EDITOR_TEST_FIT RIFF_EDITOR_TEST_MANUAL RIFF_EDITOR_TEST_MANUAL_2'));
            prior = findall(groot,'Type','figure');
            testCase.addTeardown(@() delete(setdiff(findall(groot,'Type','figure'),prior)));
        end
    end
    methods (Test)
        function separateWindowDefaultsOff(testCase)
            testCase.verifyFalse(testCase.App.FIG_HANDLE_VISIBILITYCheckBox.Value);
        end

        function verifyReturnsReusableFitOnAllReleases(testCase)
            testCase.App.IntermediateResultIDSpinner.Value = 1;
            displayed = fitTF('verify',testCase.App,[]);
            testCase.verifyEqual(displayed,testCase.Saved);
            evalin('base','clear RIFF_EDITOR_TEST_FIT');
            testCase.App.IntermediateResultIDSpinner.Value = 0;
            displayed = fitTF('verify',testCase.App,displayed);
            testCase.verifyEqual(displayed,testCase.Saved);
        end

    end
    methods (Test,TestTags={'NativeCharts'})
        function verifyCallbackReturnsSelectedParameters(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.verifyTrial(1);
            details = findobj(testCase.App.RightPanel,'Tag','RIFFParameterText');
            testCase.verifyEqual(string(details.Value),...
                fitTF('parameters',testCase.Saved.intermediate(1).FRD_Model.modeled,'Trial 1'));
            testCase.verifyTrial(2);
            details = findobj(testCase.App.RightPanel,'Tag','RIFFParameterText');
            testCase.verifyEqual(string(details.Value),...
                fitTF('parameters',testCase.Saved.intermediate(2).FRD_Model.modeled,'Trial 2'));
            testCase.verifyTrial(0);
            details = findobj(testCase.App.RightPanel,'Tag','RIFFParameterText');
            testCase.verifyEqual(string(details.Value),...
                fitTF('parameters',testCase.Saved.FRD_Model.modeled,'Best fit'));
            testCase.verifyEqual(testCase.App.Lamp.Color,[0 1 0]);
            testCase.verifyEmpty(findall(groot,'Type','figure','Name','System Identification'));
        end

        function verifyCallbackWorksWithoutWorkspaceExport(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.verifyTrial(1);
            evalin('base','clear RIFF_EDITOR_TEST_FIT');
            testCase.verifyTrial(2);
            editor = testCase.editor();
            state = editor.getState();
            testCase.verifyEqual(state.SelectedIndex,2);
            testCase.verifyEqual(editor.getModel(),testCase.Saved.intermediate(2).FRD_Model.modeled);
        end
    end
    methods (Test,TestTags={'NativeCharts'})
        function rootAndGainChangesUpdateResponse(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.verifyTrial(0);
            editor = testCase.editor();
            originalResponse = freqresp(editor.getModel(),2);
            editor.moveRoot('pole',1,-0.6+2.5i);
            editor.moveRoot('zero',1,-1.5+3.5i);
            editor.setGain(3);
            expected = zpk([-1.5+3.5i;-1.5-3.5i],[-0.6+2.5i;-0.6-2.5i;-5],3,'IODelay',0.02);
            testCase.verifyEqual(editor.getModel(),expected);
            testCase.verifyNotEqual(freqresp(editor.getModel(),2),originalResponse);
            testCase.verifyEqual(testCase.responseModel(editor.Chart.Responses(3)),expected);
            mainTab = findobj(testCase.App.RightPanel,'Tag','RIFFBodeTab');
            chart = findall(mainTab,'-isa','controllib.chart.BodePlot');
            testCase.verifyEqual(testCase.responseModel(chart.Responses(end)),expected);
            details = findobj(testCase.App.RightPanel,'Tag','RIFFParameterText');
            testCase.verifyEqual(string(details.Value),fitTF('parameters',expected,'Best fit — manual adjustment'));
            testCase.verifyEqual(editor.OriginalFit,testCase.Saved);
        end

        function constraintsKeepRealRootsReal(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.verifyTrial(0);
            editor = testCase.editor();
            editor.StableCheckBox.Value = true;
            editor.MinimumPhaseCheckBox.Value = true;
            editor.moveRoot('pole',3,2+4i);
            editor.moveRoot('zero',1,2+3i);
            testCase.verifyTrue(isstable(editor.getModel()));
            model = editor.getModel();
            testCase.verifyEqual(imag(model.P{1}(3)),0);
            model = editor.getModel();
            testCase.verifyLessThan(real(model.Z{1}),[0;0]);
            editor.StableCheckBox.Value = false;
            editor.moveRoot('pole',3,2+4i);
            testCase.verifyFalse(isstable(editor.getModel()));
            testCase.verifyTrue(contains(editor.Status.Text,'UNSTABLE'));
        end

        function editsAndResetBelongToEachFit(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.verifyTrial(0);
            editor = testCase.editor();
            editor.setGain(4);
            editedBest = editor.getModel();
            editor.selectFit(1);
            editor.moveRoot('pole',1,-2+4i);
            editedTrial = editor.getModel();
            editor.selectFit(0);
            testCase.verifyEqual(editor.getModel(),editedBest);
            editor.resetFit();
            testCase.verifyEqual(editor.getModel(),testCase.Saved.FRD_Model.modeled);
            editor.selectFit(1);
            testCase.verifyEqual(editor.getModel(),editedTrial);
            editor.resetFit();
            testCase.verifyEqual(editor.getModel(),testCase.Saved.intermediate(1).FRD_Model.modeled);
            testCase.verifyEqual(editor.OriginalFit,testCase.Saved);
        end

        function manualExportIsConsistentAndSeparate(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.verifyTrial(1);
            editor = testCase.editor();
            editor.setGain(9);
            result = editor.exportFit();
            [z,p,k] = zpkdata(result.FRD_Model.modeled,'v');
            testCase.verifyEqual(result.ZPK.z,z);
            testCase.verifyEqual(result.ZPK.p,p);
            testCase.verifyEqual(result.ZPK.k,k);
            testCase.verifyEqual(result.IODelay,0.15);
            testCase.verifyTrue(result.manualAdjustment.Modified);
            testCase.verifyEqual(result.manualAdjustment.TrialIndex,1);
            testCase.verifyFalse(isfield(result,'intermediate'));
            testCase.verifyFalse(isfield(result,'reducedOrder'));
            name = editor.exportWorkspace();
            testCase.verifyEqual(name,'RIFF_EDITOR_TEST_MANUAL');
            testCase.verifyEqual(evalin('base',[name,'.FRD_Model.modeled']),editor.getModel());
            testCase.verifyEqual(editor.exportWorkspace(),'RIFF_EDITOR_TEST_MANUAL_2');
            editor.saveToFile('manual.mat');
            disk = load('manual.mat','FIT');
            testCase.verifyEqual(disk.FIT.FRD_Model.modeled,editor.getModel());
            testCase.verifyEqual(evalin('base','RIFF_EDITOR_TEST_FIT'),testCase.Saved);
        end

        function exportUsesTrialBandAndDropsOldUncertainty(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            saved = testCase.Saved;
            saved.intermediate(1).FRD_Model.modeled.UserData = ...
                struct('instrument','Example','CovarianceMatrix',eye(3),'sigmaP',[1;1]);
            saved.intermediate(1).FRD_Model.truncated_measurement = ...
                frd(saved.FRD_Model.modeled,2*pi*[1;2;3]);
            assignin('base','RIFF_EDITOR_TEST_FIT',saved);
            testCase.verifyTrial(1);
            editor = testCase.editor();
            editor.setGain(9);

            result = editor.exportFit();

            testCase.verifyEqual(result.frequency.truncated,[1;2;3],'AbsTol',1e-12);
            testCase.verifyEqual(result.transferFunction.truncated,...
                saved.intermediate(1).FRD_Model.truncated_measurement.ResponseData(:));
            testCase.verifyEqual(result.FRD_Model.modeled.UserData,struct('instrument','Example'));
            testCase.verifyEmpty(result.ZPK.parameterCovarianceMatrix);
            testCase.verifyEqual(editor.OriginalFit,saved);
        end

        function mouseDragMovesRootsAndRestoresCallbacks(testCase)
            testCase.assumeFalse(verLessThan('matlab','24.2'));
            testCase.verifyTrial(0);
            editor = testCase.editor();
            testCase.App.UIFigure.Visible = 'on';
            testCase.choose(editor.Tab);
            drawnow;
            oldMotion = testCase.App.UIFigure.WindowButtonMotionFcn;
            oldRelease = testCase.App.UIFigure.WindowButtonUpFcn;
            testCase.drag(editor.PoleAxes,[-1 2],[-0.5 2.5]);
            model = editor.getModel();
            testCase.verifyEqual(model.P{1}(1),-0.5+2.5i,'AbsTol',0.15);
            model = editor.getModel();
            testCase.verifyEqual(model.P{1}(2),conj(model.P{1}(1)));
            testCase.verifyEqual(testCase.responseModel(editor.Chart.Responses(3)),editor.getModel());
            testCase.drag(editor.PoleAxes,[-2 3],[-2.4 3.8]);
            model = editor.getModel();
            testCase.verifyEqual(model.Z{1}(1),-2.4+3.8i,'AbsTol',0.15);
            model = editor.getModel();
            testCase.verifyEqual(model.Z{1}(2),conj(model.Z{1}(1)));
            testCase.verifyEqual(testCase.App.UIFigure.WindowButtonMotionFcn,oldMotion);
            testCase.verifyEqual(testCase.App.UIFigure.WindowButtonUpFcn,oldRelease);
        end
    end
    methods (Access=private)
        function verifyTrial(testCase,index)
            testCase.App.IntermediateResultIDSpinner.Value = index;
            callback = testCase.App.IntermediateResultIDSpinner.ValueChangedFcn;
            callback(testCase.App.IntermediateResultIDSpinner,[]);
        end
        function value = editor(testCase)
            value = getappdata(testCase.App.UIFigure,'RIFFModelEditor');
            testCase.assertClass(value,'struct');
            testCase.assertTrue(value.isValid());
        end
    end
    methods (Static,Access=private)
        function model = responseModel(response)
            if isprop(response,'Model'), model = response.Model;
            else, model = response.SourceData.Model; end
        end

        function saved = exampleFit()
            f = logspace(-2,2,100)';
            best = zpk([-2+3i;-2-3i],[-1+2i;-1-2i;-5],2,'IODelay',0.02);
            first = zpk(-3,[-1+4i;-1-4i],5,'IODelay',0.15);
            second = zpk([],[-2;-7],12,'IODelay',0.3);
            measurement = frd(best,2*pi*f);
            saved.frequency.measured = f;
            saved.FRD_Model.measured_original = measurement;
            saved.FRD_Model.measured_smoothed = measurement;
            saved.FRD_Model.truncated = measurement;
            saved.FRD_Model.modeled = best;
            saved.options.BodeOptions = bodeoptions;
            saved.options.BodeOptions.FreqUnits = 'Hz';
            saved.options.BodeOptions.PhaseWrapping = 'on';
            saved.intermediate(1).GOF = 90;
            saved.intermediate(1).FRD_Model.modeled = first;
            saved.intermediate(1).FRD_Model.truncated_measurement = measurement;
            saved.intermediate(2).GOF = 95;
            saved.intermediate(2).FRD_Model.modeled = second;
            saved.intermediate(2).FRD_Model.truncated_measurement = measurement;
            [saved.ZPK.z,saved.ZPK.p,saved.ZPK.k] = zpkdata(best,'v');
            saved.IODelay = 0.02;
            saved.gof = 100;
        end
    end
end
