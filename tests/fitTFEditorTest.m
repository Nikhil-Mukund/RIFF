classdef fitTFEditorTest < matlab.unittest.TestCase
    % The same public editing API works without RIFF or any new helper file.
    properties
        Saved
    end
    methods (TestMethodSetup)
        function isolatedCore(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            copyfile(fullfile(root,'src','fitTF.m'),'fitTF.m');
            mkdir('utils');
            % Only original dependencies accompany the isolated fitTF copy.
            copyfile(fullfile(root,'src','utils','IniConfig.m'),'utils');
            testCase.blockExternalHelpers(pwd);
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(pwd));
            testCase.Saved = testCase.exampleFit();
            prior = findall(groot,'Type','figure');
            testCase.addTeardown(@()delete(setdiff(findall(groot,'Type','figure'),prior)));
            testCase.addTeardown(@()evalin('base','clear RIFF_MANUAL_FIT RIFF_MANUAL_FIT_2'));
        end
    end
    methods (Test)
        function headlessEditsConjugateRootsGainAndParameters(testCase)
            before = findall(groot,'Type','figure');
            editor = fitTF('edit',testCase.Saved);
            testCase.addTeardown(editor.close);

            editor.moveRoot('pole',1,-0.6+2.5i);
            editor.moveRoot('zero',1,-1.5+3.5i);
            editor.setGain(3);
            expected = zpk([-1.5+3.5i;-1.5-3.5i],[-0.6+2.5i;-0.6-2.5i;-5],3,'IODelay',0.02);
            state = editor.getState();
            lines = fitTF('parameters',editor.getModel(),'Adjusted');

            testCase.verifyEqual(editor.getModel(),expected);
            testCase.verifyTrue(state.Modified);
            testCase.verifyEqual(state.SelectedIndex,0);
            testCase.verifyTrue(isfinite(state.GOF));
            testCase.verifyEqual(lines,["Adjusted";"Zeros";string(expected.Z{1});...
                "Poles";string(expected.P{1});"Gain";"3";"Delay";"0.02";"Time unit";"seconds"]);
            testCase.verifyEqual(editor.OriginalFit,testCase.Saved);
            testCase.verifyEqual(findall(groot,'Type','figure'),before);
        end

        function trialDraftsResetAndIndependentSessions(testCase)
            editor = fitTF('edit',testCase.Saved);
            testCase.addTeardown(editor.close);
            other = fitTF('edit',testCase.Saved);
            testCase.addTeardown(other.close);
            editor.setGain(4);
            best = editor.getModel();
            editor.selectFit(1);
            editor.setGain(8);
            trial = editor.getModel();
            editor.selectFit(0);
            testCase.verifyEqual(editor.getModel(),best);
            editor.resetFit();
            testCase.verifyEqual(editor.getModel(),testCase.Saved.FRD_Model.modeled);
            editor.selectFit(1);
            testCase.verifyEqual(editor.getModel(),trial);
            editor.resetFit();
            testCase.verifyEqual(editor.getModel(),testCase.Saved.intermediate(1).FRD_Model.modeled);
            testCase.verifyEqual(other.getModel(),testCase.Saved.FRD_Model.modeled);
        end

        function continuousConstraintsAndRealRoots(testCase)
            editor = fitTF('edit',testCase.Saved,'EnforceMinimumPhase',true);
            testCase.addTeardown(editor.close);
            editor.moveRoot('pole',3,2+4i);
            editor.moveRoot('zero',1,2+3i);
            constrained = editor.getModel();
            editor.setConstraints(false,false);
            editor.moveRoot('pole',3,2+4i);
            relaxed = editor.getModel();
            testCase.verifyTrue(isstable(constrained));
            testCase.verifyEqual(imag(constrained.P{1}(3)),0);
            testCase.verifyLessThan(real(constrained.Z{1}),[0;0]);
            testCase.verifyFalse(isstable(relaxed));
            testCase.verifyEqual(relaxed.P{1}(3),2);
        end

        function discreteConstraintsPreserveSampleTimeAndDelay(testCase)
            saved = testCase.Saved;
            saved.FRD_Model.modeled = zpk([0.2+0.3i;0.2-0.3i],[0.5+0.2i;0.5-0.2i;0.1],2,0.01,'IODelay',2);
            editor = fitTF('edit',saved,'EnforceMinimumPhase',true);
            testCase.addTeardown(editor.close);
            editor.moveRoot('pole',1,2+3i);
            editor.moveRoot('zero',1,-2+3i);
            model = editor.getModel();
            testCase.verifyLessThan(abs(model.P{1}),ones(3,1));
            testCase.verifyLessThan(abs(model.Z{1}),ones(2,1));
            testCase.verifyEqual(model.P{1}(2),conj(model.P{1}(1)));
            testCase.verifyEqual(model.Z{1}(2),conj(model.Z{1}(1)));
            testCase.verifyEqual(model.Ts,0.01);
            testCase.verifyEqual(totaldelay(model),2);
        end

        function exportUsesSelectedBandAndClearsObsoleteResults(testCase)
            saved = testCase.Saved;
            saved.intermediate(1).FRD_Model.truncated_measurement = frd(saved.FRD_Model.modeled,2*pi*[1;2;3]);
            saved.intermediate(1).FRD_Model.modeled.UserData = struct('instrument','Example','CovarianceMatrix',eye(3));
            editor = fitTF('edit',saved);
            testCase.addTeardown(editor.close);
            editor.selectFit(1);
            editor.setGain(9);
            result = editor.exportFit();
            editor.saveToFile('edited.mat');
            disk = load('edited.mat','FIT');
            testCase.verifyEqual(result.frequency.truncated,[1;2;3],'AbsTol',1e-12);
            testCase.verifyEqual(result.transferFunction.truncated,saved.intermediate(1).FRD_Model.truncated_measurement.ResponseData(:));
            testCase.verifyEqual(result.FRD_Model.modeled.UserData,struct('instrument','Example'));
            testCase.verifyEqual(result.IODelay,0.15);
            testCase.verifyEqual(result.ZPK.k,9);
            testCase.verifyEmpty(result.ZPK.parameterCovarianceMatrix);
            testCase.verifyFalse(isfield(result,'intermediate'));
            testCase.verifyFalse(isfield(result,'reducedOrder'));
            testCase.verifyEqual(disk.FIT.FRD_Model.modeled,result.FRD_Model.modeled);
            testCase.verifyEqual(editor.exportWorkspace(),'RIFF_MANUAL_FIT');
            testCase.verifyEqual(editor.exportWorkspace(),'RIFF_MANUAL_FIT_2');
            testCase.verifyEqual(evalin('base','RIFF_MANUAL_FIT.FRD_Model.modeled'),result.FRD_Model.modeled);
            testCase.verifyEqual(editor.OriginalFit,saved);
        end

        function standaloneInteractiveEditorWithoutApp(testCase)
            editor = fitTF('edit',testCase.Saved,'Interactive',true,'Visible','off');
            testCase.addTeardown(editor.close);
            editor.selectFit(1);
            editor.moveRoot('pole',1,-2+5i);
            editor.setGain(7);
            model = editor.getModel();
            testCase.verifyTrue(isgraphics(editor.Figure));
            testCase.verifyEqual(editor.Selector.Value,1);
            testCase.verifyEqual(editor.GainField.Value,7);
            testCase.verifyEqual(testCase.responseModel(editor.Chart.Responses(3)),model);
            testCase.verifyTrue(contains(editor.Status.Text,'Trial 1'));
            delete(editor.Figure);
            testCase.verifyFalse(editor.isValid());
            testCase.verifyError(editor.getModel,'RIFF:EditorClosed');
        end

        function verifyAndParametersWithoutApp(testCase)
            result = fitTF('verify',testCase.Saved,1);
            fig = findall(groot,'Type','figure','Name','System Identification');
            testCase.verifyEqual(result,testCase.Saved);
            testCase.assertNumElements(fig,1);
            testCase.verifyEqual(string(fig.Visible),"on");
            charts = findall(fig,'-isa','controllib.chart.BodePlot');
            testCase.assertNumElements(charts,1);
            testCase.verifyTrue(contains(charts.Title.String,'Trial 1'));
            lines = fitTF('parameters',testCase.Saved.intermediate(1).FRD_Model.modeled);
            testCase.verifyEqual(lines(1),"Model");
            testCase.verifyTrue(any(lines == "0.15"));
        end

        function invalidRootAndClosedEditor(testCase)
            editor = fitTF('edit',testCase.Saved);
            testCase.verifyError(@()editor.moveRoot('banana',1,-1),'RIFF:RootKind');
            editor.close();
            editor.close();
            testCase.verifyFalse(editor.isValid());
            testCase.verifyError(editor.getModel,'RIFF:EditorClosed');
            testCase.verifyError(@()editor.setGain(3),'RIFF:EditorClosed');
        end
    end
    methods (Static,Access=private)
        function model = responseModel(response)
            if isprop(response,'Model'), model = response.Model;
            else, model = response.SourceData.Model; end
        end
        function blockExternalHelpers(folder)
            names = {'RIFF','RIFFModelEditor','riff_verify_fit','riff_model_parameters',...
                'riff_fit_aaa','riff_aaa_backend','riff_default_routines'};
            for index = 1:numel(names)
                fid = fopen(fullfile(folder,[names{index} '.m']),'w');
                cleanup = onCleanup(@()fclose(fid));
                fprintf(fid,['function varargout = %s(varargin)\n'...
                    'error(''RIFF:ExternalCoreDependency'',''Unexpected external call.'');\nend\n'],names{index});
                clear cleanup
            end
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
