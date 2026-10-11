classdef RIFFAAATest < matlab.unittest.TestCase
    % R2026b regression tests through the public fitTF API, without an app.
    properties (TestParameter)
        poleCap = {1,3,4}
        inputFormat = struct('vectors','vectors','frd','frd','file','file')
        plotMode = struct('headless',0,'standalonePlot',1)
    end
    methods (TestClassSetup)
        function prepare(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src','utils')));
        end
    end
    methods (TestMethodSetup)
        function isolate(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            initialFigures = findall(groot,'Type','figure');
            testCase.addTeardown(@() delete(setdiff(findall(groot,'Type','figure'),initialFigures)));
            randomState = rng;
            testCase.addTeardown(@() rng(randomState));
            rng(42,'twister');
            warningState = warning;
            testCase.addTeardown(@() warning(warningState));
        end
    end
    methods (Test)
        function defaultsQueryDoesNotStartFit(testCase)
            initialPath = path;
            initialFigures = findall(groot,'Type','figure');
            output = evalc('defaults = fitTF(''defaults'');');
            testCase.verifyEmpty(output);
            testCase.verifyEqual(defaults.ROUTINE,[2 5]);
            testCase.verifyEqual(defaults.AAA_BACKEND,'sysid');
            testCase.verifyEqual(defaults.ESTIMATE_UNCERTAINITY,0);
            testCase.verifyEqual(path,initialPath);
            testCase.verifyEqual(findall(groot,'Type','figure'),initialFigures);
        end
        function knownResponseAndHertz(testCase,inputFormat)
            [f,response,truth] = testCase.measurement();
            inputs = testCase.inputArguments(inputFormat,f,response);
            args = testCase.fitArguments(inputs,f,3,ones(size(f)));
            result = fitTF(args{:},'ROUTINE',5);
            model = result.FRD_Model.modeled;
            testCase.verifyEqual(result.options.Optimization.AAA_BACKEND,'sysid');
            testCase.verifyEqual(result.options.ESTIMATE_UNCERTAINITY,0);
            testCase.verifyEqual(model.Ts,0);
            testCase.verifyTrue(isstable(model));
            testCase.verifyLessThanOrEqual(order(model),3);
            heldOut = logspace(-1.9,1.9,93)';
            expected = squeeze(freqresp(truth,2*pi*heldOut));
            actual = squeeze(freqresp(model,2*pi*heldOut));
            testCase.verifyLessThan(norm(actual-expected)/norm(expected),1e-4);
        end
        function respectsPoleCap(testCase,poleCap)
            [f,response] = testCase.measurement();
            args = testCase.fitArguments({'F',f,'TF',response},f,poleCap,ones(size(f)));
            result = fitTF(args{:},'ROUTINE',5);
            testCase.verifyLessThanOrEqual(order(result.FRD_Model.modeled),poleCap);
            testCase.verifyTrue(isstable(result.FRD_Model.modeled));
        end
        function reproducibleRfBackend(testCase)
            [f,response] = testCase.measurement();
            args = testCase.fitArguments({'F',f,'TF',response},f,3,ones(size(f)));
            first = fitTF(args{:},'ROUTINE',5,'AAA_BACKEND','rf');
            second = fitTF(args{:},'ROUTINE',5,'AAA_BACKEND','rf');
            testCase.verifyEqual(first.options.Optimization.AAA_BACKEND,'rf');
            testCase.verifyEqual(freqresp(first.FRD_Model.modeled,2*pi*f),...
                freqresp(second.FRD_Model.modeled,2*pi*f),'AbsTol',1e-10);
        end
        function invalidWeightsFailClearly(testCase)
            [f,response] = testCase.measurement();
            args = testCase.fitArguments({'F',f,'TF',response},f,3,zeros(size(f)));
            testCase.verifyError(@() fitTF(args{:},'ROUTINE',5),'RIFF:AAAWeights');
        end
        function commandLineDefaultsAndWarmStart(testCase)
            [f,response] = testCase.measurement();
            args = testCase.fitArguments({'F',f,'TF',response},f,3,ones(size(f)));
            % Do not set ROUTINE or ESTIMATE_UNCERTAINITY: exercise CLI defaults.
            result = fitTF(args{:});
            testCase.verifyEqual(result.options.Optimization.SELECTED_ROUTINES,[2 5]);
            testCase.verifyEqual(result.options.Optimization.FINAL_FIT_ROUTINE,"AAA");
            testCase.verifyEqual(result.options.Optimization.results(4),5);
            testCase.verifyEqual(result.options.Optimization.AAA_BACKEND,'sysid');
            testCase.verifyEqual(result.intermediate(1).FIT_ROUTINE,"AAA");
            testCase.verifyEqual(result.intermediate(1).AAA_BACKEND,'sysid');
            testCase.verifyGreaterThan(result.gof,99);
            second = fitTF(args{:},'ROUTINE',5,'GUESS',result.options.Optimization.results);
            testCase.verifyEqual(second.options.Optimization.results(4),5);
            testCase.verifyGreaterThan(second.gof,99);
        end
        function uncertaintyIsOptIn(testCase)
            [f,response] = testCase.measurement();
            args = testCase.fitArguments({'F',f,'TF',response},f,3,ones(size(f)));
            result = fitTF(args{:},'ESTIMATE_UNCERTAINITY',1,'GUESS',[3 f(1) f(end) 2 5]);
            testCase.verifyEqual(result.options.Optimization.SELECTED_ROUTINES,2);
            testCase.verifyEqual(result.options.Optimization.FINAL_FIT_ROUTINE,"tfest");
            testCase.verifyEqual(result.options.ESTIMATE_UNCERTAINITY,1);
            testCase.verifyTrue(isa(result.FRD_Model.modeled,'idtf'));
            testCase.verifyNotEmpty(getcov(result.FRD_Model.modeled));
        end
        function appUsesCoreDefaults(testCase)
            app = RIFF;
            testCase.addTeardown(@() delete(app));
            app.UIFigure.Visible = 'off';
            defaults = fitTF('defaults');
            nodes = [app.rationalfitNode,app.tfestNode,app.invfreqsNode,app.fitmagfrdNode,app.AAANode];
            testCase.verifyEqual(app.Tree.CheckedNodes(:),nodes(defaults.ROUTINE)');
            testCase.verifyEqual(app.ESTIMATE_UNCERTAINITYCheckBox.Value,...
                logical(defaults.ESTIMATE_UNCERTAINITY));
        end
        function usesFrequencyWeights(testCase)
            [f,response] = testCase.measurement();
            args = testCase.fitArguments({'F',f,'TF',response},f,1,ones(size(f)));
            equal = fitTF(args{:},'ROUTINE',5);
            weight = 1./max(abs(response),1e-6);
            weighted = fitTF(args{:},'ROUTINE',5,'CUSTOM_WEIGHT',weight);
            a = squeeze(freqresp(equal.FRD_Model.modeled,2*pi*f));
            b = squeeze(freqresp(weighted.FRD_Model.modeled,2*pi*f));
            testCase.verifyGreaterThan(norm(a-b)/norm(a),0.01);
        end
        function coreRunsWithoutGuiOrAaaHelperFiles(testCase,plotMode)
            root = fileparts(fileparts(mfilename('fullpath')));
            fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            copyfile(fullfile(root,'src','fitTF.m'),fixture.Folder);
            copyfile(fullfile(root,'src','utils'),fullfile(fixture.Folder,'utils'));
            testCase.blockExternalHelpers(fixture.Folder);
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fixture.Folder));
            testCase.assertEqual(which('fitTF'),fullfile(fixture.Folder,'fitTF.m'));
            initialFigures = findall(groot,'Type','figure');
            [f,response] = testCase.measurement();
            args = testCase.fitArguments({'F',f,'TF',response},f,3,ones(size(f)));
            result = fitTF(args{:},'ROUTINE',5,'PLOT_TOGGLE',plotMode,'FIG_HANDLE_VISIBILITY',0);
            testCase.verifyGreaterThan(result.gof,99);
            testCase.verifyEqual(result.options.Optimization.AAA_BACKEND,'sysid');
            testCase.verifyNumElements(setdiff(findall(groot,'Type','figure'),initialFigures),plotMode);
        end
    end
    methods (Static, Access = private)
        function [f,response,truth] = measurement()
            f = logspace(-2,2,160)';
            truth = zpk([],[-1+2i;-1-2i;-10],40);
            response = squeeze(freqresp(truth,2*pi*f));
        end
        function args = fitArguments(inputs,f,poles,weight)
            args = [inputs,{'GUESS',[poles f(1) f(end) 5 5],...
                'MIN_POLES',poles,'MAX_POLES',poles,'NUM_TRIALS',1,...
                'FUNC_EVAL',10,'OPTIMIZER','FMINCON','DAMP_RESONANCES',0,...
                'F_INITIAL',f(1),'F_FINAL',f(end),'FREQ_WIN_LOW',0,'FREQ_WIN_UP',0,...
                'CUSTOM_WEIGHT',weight,'PLOT_TOGGLE',0,'SAVE_TOGGLE',0,'INTERMEDIATE_PLOT',0}];
        end
        function inputs = inputArguments(format,f,response)
            switch format
                case 'vectors'
                    inputs = {'F',f,'TF',response};
                case 'frd'
                    inputs = {'FRD',frd(response,2*pi*f)};
                case 'file'
                    file = fullfile(pwd,'measurement.csv');
                    writematrix([f real(response) imag(response)],file);
                    inputs = {'FNAME',file,'FORMAT','f,a,b'};
            end
        end
        function blockExternalHelpers(folder)
            names = {'rational','RIFF','RIFFModelEditor','riff_verify_fit',...
                'riff_fit_aaa','riff_aaa_backend','riff_default_routines','riff_model_parameters'};
            for index = 1:numel(names)
                fid = fopen(fullfile(folder,[names{index} '.m']),'w');
                cleanup = onCleanup(@()fclose(fid));
                fprintf(fid,['function varargout = %s(varargin)\n'...
                    'error(''RIFF:ExternalCoreDependency'',''Unexpected external call.'');\nend\n'],names{index});
                clear cleanup
            end
        end
    end
end
