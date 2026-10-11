classdef RIFFCombineTest < matlab.unittest.TestCase
    % Shared CLI/app merge behavior, including mismatched instrument grids.
    properties
        Root
    end
    methods (TestClassSetup)
        function sources(testCase)
            testCase.Root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(testCase.Root,'src')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(testCase.Root,'src','utils')));
        end
    end
    methods (TestMethodSetup)
        function isolate(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            figures = findall(groot,'Type','figure');
            testCase.addTeardown(@()delete(setdiff(findall(groot,'Type','figure'),figures)));
        end
    end
    methods (Test)
        function commonGridAndOrder(testCase)
            a = struct('F',[1 2 4 6],'TF',(1+2i)*[1 2 4 6]);
            b = struct('F',[2.3 4.1 5.9 8.7],'TF',(1+2i)*[2.3 4.1 5.9 8.7]);
            first = fitTF('combine',[a b],0.7);
            reverse = fitTF('combine',[b a],0.7);
            testCase.verifyEqual(first.F,reverse.F,'AbsTol',1e-12);
            testCase.verifyEqual(first.TF,reverse.TF,'AbsTol',1e-12);
            testCase.verifyEqual(first.TF,(1+2i)*first.F,'AbsTol',1e-12);
            testCase.verifyTrue(all(diff(first.F)>0));
            testCase.verifyEqual(first.FRD.Frequency,2*pi*first.F,'AbsTol',1e-12);
            testCase.verifyEqual(squeeze(first.FRD.ResponseData),first.TF,'AbsTol',1e-12);
        end
        function duplicateAndInvalidSamples(testCase)
            data = struct('F',[3 2 1 2 0 NaN 4],'TF',[3 1 1 3 99 99 Inf]*(1+1i));
            combined = fitTF('combine',data,0.5);
            testCase.verifyEqual(combined.TF,(1+1i)*combined.F,'AbsTol',1e-12);
            testCase.verifyEqual(combined.F([1 end]),[1;3],'AbsTol',eps);
        end
        function complexOverlapAcrossPhaseWrap(testCase)
            a = struct('F',[1 2 3],'TF',exp(1i*deg2rad([179 179 179])));
            b = struct('F',[2 3 4],'TF',exp(1i*deg2rad([-179 -179 -179])));
            combined = fitTF('combine',[a b],1);
            testCase.verifyEqual(combined.TF(2:3),cosd(179)*ones(2,1),'AbsTol',1e-12);
            testCase.verifyEqual(combined.Coverage,[1;2;2;1]);
        end
        function nestedBandsAndGaps(testCase)
            a = struct('F',[1 5],'TF',[1 5]);
            b = struct('F',[2 3],'TF',[2 3]);
            c = struct('F',[8 10],'TF',[8 10]);
            combined = fitTF('combine',[c b a],1);
            testCase.verifyEqual(combined.F,[1:5 8:10]','AbsTol',eps);
            testCase.verifyEqual(combined.TF,combined.F,'AbsTol',eps);
            testCase.verifyEqual(combined.Coverage,[1 2 2 1 1 1 1 1]');
        end
        function noGlobalSideEffects(testCase)
            beforePath = path; beforeWarnings = warning;
            beforeFont = get(groot,'DefaultAxesFontSize');
            beforeFigures = findall(groot,'Type','figure');
            fitTF('combine',struct('F',[1 2],'TF',[1 2]),0.1);
            testCase.verifyEqual(path,beforePath);
            testCase.verifyEqual(warning,beforeWarnings);
            testCase.verifyEqual(get(groot,'DefaultAxesFontSize'),beforeFont);
            testCase.verifyEqual(findall(groot,'Type','figure'),beforeFigures);
        end
        function actionableErrors(testCase)
            testCase.verifyError(@()fitTF('combine',strings(0,1)),'RIFF:CombineInput');
            testCase.verifyError(@()fitTF('combine','missing.DAT'),'RIFF:SDFFile');
            testCase.verifyError(@()fitTF('combine',struct('F',[1 2],'TF',1)),'RIFF:CombineLength');
            testCase.verifyError(@()fitTF('combine',struct('F',[0 1],'TF',[1 1])),'RIFF:CombineSamples');
            testCase.verifyError(@()fitTF('combine',struct('F',[1 100],'TF',[1 1]),1e-6),'RIFF:CombineResolution');
        end
        function oldWrapperSupportsThreeArgumentsAndPlot(testCase)
            [h,f,~,data,model] = combineTFs(struct('F',[1 2 3],'TF',[1 2 3]),0.5,bodeoptions);
            testCase.verifyEqual(h,f,'AbsTol',eps);
            testCase.verifyEqual(squeeze(model.ResponseData),h.','AbsTol',eps);
            testCase.verifyNumElements(data,1);
            testCase.verifyNumElements(findall(groot,'Type','figure','Name','Combined measurements'),1);
        end
        function bundledSdfAnyOrder(testCase)
            files = fullfile(testCase.Root,'measured_TFs',...
                ["N1_100mHz_100Hz.DAT","N2_50Hz_1500Hz.DAT","N3_500Hz_10KHz.DAT"]);
            normal = fitTF('combine',files,10);
            reverse = fitTF('combine',files([3 1 2]),10);
            testCase.verifyEqual(normal.F,reverse.F,'AbsTol',1e-12);
            testCase.verifyEqual(normal.TF,reverse.TF,'RelTol',1e-12,'AbsTol',1e-12);
            testCase.verifyTrue(all(isfinite(normal.TF)));
            testCase.verifyTrue(all(diff(normal.F)>0));
        end
        function coreFitsSdfMeasurements(testCase)
            files = fullfile(testCase.Root,'measured_TFs',...
                ["N2_50Hz_1500Hz.DAT","N1_100mHz_100Hz.DAT"]);
            result = fitTF('SDF_DATASETS',files,'SDF_DATASET_FREQ_RESO',10,...
                'ROUTINE',5,'MIN_POLES',1,'MAX_POLES',2,'NUM_TRIALS',1,...
                'FUNC_EVAL',2,'PLOT_TOGGLE',0,'DAMP_RESONANCES',0,...
                'FREQ_WIN_LOW',0,'FREQ_WIN_UP',0);
            testCase.verifyTrue(isfinite(result.gof));
            testCase.verifyTrue(isstable(result.FRD_Model.modeled));
            testCase.verifyEqual(result.options.Optimization.AAA_BACKEND,'sysid');
        end
        function appMultipleSdfPreview(testCase)
            copyfile(fullfile(testCase.Root,'measured_TFs'),'measured_TFs');
            app = RIFF; testCase.addTeardown(@()delete(app)); app.UIFigure.Visible='off';
            app.INPUT_DATA_FORMATDropDown.Value='HP_Agilent_Keysight_SDF';
            app.ChooseTFListBox_2.Value={'N3_500Hz_10KHz.DAT','N1_100mHz_100Hz.DAT','N2_50Hz_1500Hz.DAT'};
            app.FIT_WEIGHT_FROM_PHASE_SMOOTHNESSCheckBox.Value=false;
            callback=app.PreviewBodeplotButton.ButtonPushedFcn;
            callback(app.PreviewBodeplotButton,[]);
            testCase.verifyEqual(app.Lamp.Color,[0 1 0],'AbsTol',eps);
            testCase.verifyNotEmpty(findall(app.RightPanel,'Tag','RIFFInteractivePlot'));
            testCase.verifyEmpty(findall(groot,'Type','figure','Name','System Identification'));
        end
    end
end
