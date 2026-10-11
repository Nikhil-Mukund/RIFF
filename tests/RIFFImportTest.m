classdef RIFFImportTest < matlab.uitest.TestCase
    % Import semantics and real app controls exercise the shared public API.
    properties (TestParameter)
        weightedRoutine = {2,5}
    end
    methods (TestClassSetup)
        function sources(testCase)
            root=fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src','utils')));
        end
    end
    methods (TestMethodSetup)
        function isolate(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            prior=findall(groot,'Type','figure');
            testCase.addTeardown(@()delete(setdiff(findall(groot,'Type','figure'),prior)));
            saved=rng;testCase.addTeardown(@()rng(saved));rng(42);
            state=warning;testCase.addTeardown(@()warning(state));
        end
    end
    methods (Test)
        function shuffledColumnsAndDcStayAligned(testCase)
            t=table([0.3;1;0.8;0.5],[3;0;2;1],[30;0;20;10],[2;9;3;4],[-3;0;-2;-1],...
                'VariableNames',{'Coherence','FrequencyHz','Real','Weight','Imag'});
            data=fitTF('import',t);
            testCase.verifyEqual(data.F,[1;2;3]);
            testCase.verifyEqual(data.TF,[10;20;30]-1i*[1;2;3]);
            testCase.verifyEqual(data.Weight,[4;3;2]);
            testCase.verifyEqual(data.Coherence,[0.5;0.8;0.3]);
            testCase.verifyEqual(data.EffectiveWeight,[2;2.4;0.6],'AbsTol',1e-12);
            testCase.verifyEqual(data.Rows,[4;3;1]);
            testCase.verifyEqual(data.DroppedDCRows,2);
        end
        function autoCsvAndComplexValues(testCase)
            t=table([1;2;3],['1+2i';'3-4i';'5+6i'],[0;0.5;1],...
                'VariableNames',{'FrequencyHz','TF','Coherence'});
            writetable(t,'complex.csv');data=fitTF('import','complex.csv');
            testCase.verifyEqual(data.TF,[1+2i;3-4i;5+6i]);
            testCase.verifyEqual(data.EffectiveWeight,[0;0.5;1]);
        end
        function magnitudePhaseUnits(testCase)
            t=table(2*pi*[1;2],[0;20],[90;-180],...
                'VariableNames',{'FrequencyRad_s','Magnitude_dB','Phase_deg'});
            data=fitTF('import',t);
            testCase.verifyEqual(data.F,[1;2],'AbsTol',eps);
            testCase.verifyEqual(data.TF,[1i;-10],'AbsTol',1e-12);
            map=struct('Frequency',1,'FrequencyUnit','Hz','ResponseType','mag-phase',...
                'Magnitude',2,'MagnitudeUnit','linear','Phase',3,'PhaseUnit','rad');
            data=fitTF('import',[1 2 pi/2;2 3 pi],map);
            testCase.verifyEqual(data.TF,[2i;-3],'AbsTol',1e-12);
        end
        function headerlessRequiresMap(testCase)
            raw=[1 2 -1 0.1;2 3 -2 0.9];
            testCase.verifyError(@()fitTF('import',raw),'RIFF:ColumnMap');
            map=struct('Frequency',1,'FrequencyUnit','Hz','ResponseType','real-imag',...
                'Real',2,'Imaginary',3,'Coherence',4);
            writematrix(raw,'unnamed.csv');data=fitTF('import','unnamed.csv',map);
            testCase.verifyEqual(data.TF,[2-1i;3-2i]);
            testCase.verifyEqual(data.EffectiveWeight,[0.1;0.9]);
        end
        function ambiguousHeadersNeedSelection(testCase)
            t=table([1;2],[2;4],[3;4],[5;6],...
                'VariableNames',{'f','FrequencyHz','Real','Imag'});
            info=fitTF('inspect',t);
            testCase.verifyEqual(info.AmbiguousRoles,{'Frequency'});
            testCase.verifyError(@()fitTF('import',t),'RIFF:ColumnMap');
            data=fitTF('import',t,struct('Frequency','f','FrequencyUnit','Hz'));
            testCase.verifyEqual(data.F,[1;2]);
        end
        function genericUnitsNeedSelection(testCase)
            t=table([1;2],[2;3],[0;0],'VariableNames',{'Frequency','Magnitude','Phase'});
            testCase.verifyError(@()fitTF('import',t),'RIFF:ColumnMap');
            map=struct('FrequencyUnit','Hz','MagnitudeUnit','linear','PhaseUnit','deg');
            data=fitTF('import',t,map);testCase.verifyEqual(data.TF,[2;3]);
        end
        function ignoreCoherenceKeepsExplicitWeight(testCase)
            t=table([1;2],[1;1],[0;0],[2;3],'VariableNames',{'f','TF','Coherence','Weight'});
            testCase.verifyError(@()fitTF('import',t),'RIFF:ImportWeights');
            data=fitTF('import',t,struct('UseCoherence',false));
            testCase.verifyEqual(data.EffectiveWeight,[2;3]);
            testCase.verifyEqual(data.Coherence,[0;0]);
            data=fitTF('import',removevars(t,'Weight'),struct('UseCoherence',false));
            testCase.verifyFalse(data.HasWeights);
        end
        function invalidCoherenceRejected(testCase)
            t=table([1;2],[1;1],[0.5;1.2],'VariableNames',{'f','TF','Coherence'});
            testCase.verifyError(@()fitTF('import',t),'RIFF:ImportCoherence');
            t.Coherence=[-0.1;1];
            testCase.verifyError(@()fitTF('import',t),'RIFF:ImportWeights');
            t.Coherence=[NaN;1];
            testCase.verifyError(@()fitTF('import',t),'RIFF:ImportWeights');
            t.Coherence=[0.3;0.9];t.Properties.VariableNames{3}='Coherence_percent';
            testCase.verifyError(@()fitTF('import',t),'RIFF:ImportCoherence');
            data=fitTF('import',t,struct('Coherence',0));testCase.verifyFalse(data.HasWeights);
        end
        function invalidWeightsAndSamplesRejected(testCase)
            t=table([1;2],[1;1],[-1;2],'VariableNames',{'f','TF','Weight'});
            testCase.verifyError(@()fitTF('import',t),'RIFF:ImportWeights');
            t.Weight=[1;2];t.f=[1;1];
            testCase.verifyError(@()fitTF('import',t),'RIFF:ImportFrequency');
            t.f=[-1;2];testCase.verifyError(@()fitTF('import',t),'RIFF:ImportSamples');
            t.f=[1;2];t.TF=[NaN;2];testCase.verifyError(@()fitTF('import',t),'RIFF:ImportSamples');
        end
        function cannotReuseColumnForDifferentRoles(testCase)
            map=struct('Frequency',1,'FrequencyUnit','Hz','ResponseType','complex','Response',1);
            testCase.verifyError(@()fitTF('import',[1 2;2 3],map),'RIFF:ColumnMap');
        end
        function vectorWeightsSurviveDcSortingAndPhaseOption(testCase,weightedRoutine)
            [f,h]=testCase.measurement(160,100);args=testCase.fitArguments(f);
            dataF=[flipud(f);0];dataH=[flipud(h);1];
            coherence=[linspace(0.1,0.9,numel(f))';1];weight=[linspace(1,3,numel(f))';9];
            result=fitTF('F',dataF,'TF',dataH,args{:},'COHERENCE',coherence,...
                'CUSTOM_WEIGHT',weight,'FIT_WEIGHT_FROM_PHASE_SMOOTHNESS',1,'ROUTINE',weightedRoutine,...
                'GUESS',[3 f(1) f(end) weightedRoutine 5]);
            expected=flipud(coherence(1:end-1).*weight(1:end-1));
            testCase.verifyEqual(result.options.CUSTOM_WEIGHT,expected,'AbsTol',1e-12);
            testCase.verifyEqual(result.weighting.Frequency,f);
            testCase.verifyEqual(result.weighting.Coherence,flipud(coherence(1:end-1)));
            testCase.verifyTrue(result.weighting.SuppliedWeights);
        end
        function weightsResampleWithResponse(testCase)
            [f,h]=testCase.measurement(10005,200);args=testCase.fitArguments(f);
            coherence=0.1+0.8*f/max(f);
            result=fitTF('F',f,'TF',h,args{:},'COHERENCE',coherence,...
                'CUSTOM_WEIGHT',uint8(2*ones(size(f))),'FIT_WEIGHT_FROM_PHASE_SMOOTHNESS',1);
            testCase.verifyNumElements(result.weighting.Frequency,1000);
            expected=interp1(f,2*coherence,result.weighting.Frequency);
            testCase.verifyEqual(result.options.CUSTOM_WEIGHT,expected,'AbsTol',1e-12);
            testCase.verifyEqual(result.weighting.OriginalWeight,2*coherence,'AbsTol',1e-12);
            testCase.verifyEqual(result.FRD_Model.measured_smoothed.Frequency,...
                2*pi*result.weighting.Frequency,'AbsTol',1e-10);
        end
        function mappedFileFitsAndRetainsProvenance(testCase)
            [f,h]=testCase.measurement(160,100);args=testCase.fitArguments(f);
            t=table(f,real(h),imag(h),linspace(0.1,1,numel(f))',...
                'VariableNames',{'FrequencyHz','Real','Imag','Coherence'});
            writetable(t,'measurement.csv');
            result=fitTF('FNAME','measurement.csv','FORMAT','auto',args{:});
            testCase.verifyEqual(result.options.CUSTOM_WEIGHT,t.Coherence,'AbsTol',1e-12);
            testCase.verifyEqual(result.input.Import.ColumnMap.Coherence,4);
            testCase.verifyGreaterThan(result.gof,99);
        end
        function suppliedCoherenceActuallyChangesEstimate(testCase)
            [f,h]=testCase.measurement(160,100);args=testCase.fitArguments(f);
            args=[args,{'MIN_POLES',1,'MAX_POLES',1,'GUESS',[1 f(1) f(end) 5 5]}];
            uniform=fitTF('F',f,'TF',h,args{:},'COHERENCE',ones(size(f)));
            coherence=0.05+0.95*(f>1);
            weighted=fitTF('F',f,'TF',h,args{:},'COHERENCE',coherence);
            a=squeeze(freqresp(uniform.FRD_Model.modeled,2*pi*f));
            b=squeeze(freqresp(weighted.FRD_Model.modeled,2*pi*f));
            testCase.verifyGreaterThan(norm(a-b)/norm(a),0.01);
        end
        function minimumPhaseUsesSuppliedCoherence(testCase)
            [f,h]=testCase.measurement(80,100);args=testCase.fitArguments(f);
            args=[args,{'ENFORCE_MINIMUM_PHASE',1,'MIN_POLES',1,'MAX_POLES',1,...
                'GUESS',[1 f(1) f(end) 4 5]}];
            uniform=fitTF('F',f,'TF',h,args{:},'COHERENCE',ones(size(f)));
            weighted=fitTF('F',f,'TF',h,args{:},'COHERENCE',0.01+0.99*(f>1));
            a=squeeze(freqresp(uniform.FRD_Model.modeled,2*pi*f));
            b=squeeze(freqresp(weighted.FRD_Model.modeled,2*pi*f));
            testCase.verifyEqual(weighted.options.Optimization.FINAL_FIT_ROUTINE,"fitmagfrd");
            testCase.verifyGreaterThan(norm(a-b)/norm(a),0.01);
        end
        function columnOverrideUsesNewUnits(testCase)
            t=table([1;2],2*pi*[4;5],[1;2],'VariableNames',{'FrequencyHz','sweep_rad_s','TF'});
            data=fitTF('import',t,struct('Frequency','sweep_rad_s'));
            testCase.verifyEqual(data.F,[4;5],'AbsTol',1e-12);
            t.Properties.VariableNames{2}='Frequency_kHz';
            testCase.verifyError(@()fitTF('import',t,struct('Frequency','Frequency_kHz')),'RIFF:ColumnMap');
            t.Properties.VariableNames{2}='sweep';
            testCase.verifyError(@()fitTF('import',t,struct('Frequency','sweep')),'RIFF:ColumnMap');
        end
        function nextFitDoesNotReusePreviousWeights(testCase)
            [f,h]=testCase.measurement(160,100);args=testCase.fitArguments(f);
            first=fitTF('F',f,'TF',h,args{:},'COHERENCE',0.5*ones(size(f)));
            testCase.verifyTrue(first.weighting.SuppliedWeights);
            % An unweighted fit must not inherit that same-length vector either.
            next=fitTF('F',f,'TF',h,args{:},'GUESS',[3 f(1) f(end) 5 1]);
            testCase.verifyFalse(next.weighting.SuppliedWeights);
            testCase.verifyEmpty(next.weighting.OriginalWeight);
        end
        function namedFileWeightsAndExternalVectorsMultiply(testCase)
            [f,h]=testCase.measurement(160,100);args=testCase.fitArguments(f);
            t=table([flipud(f);0],[flipud(h);1],[(1:numel(f))';9],...
                [0.5*ones(size(f));1],'VariableNames',{'f','TF','Weight','Coherence'});
            writetable(t,'weighted.csv');external=linspace(1,2,height(t))';
            result=fitTF('FNAME','weighted.csv','FORMAT','auto',args{:},'CUSTOM_WEIGHT',external);
            expected=flipud(t.Weight(1:end-1).*t.Coherence(1:end-1).*external(1:end-1));
            testCase.verifyEqual(result.options.CUSTOM_WEIGHT,expected,'AbsTol',1e-10);
            ignored=fitTF('FNAME','weighted.csv','FORMAT','auto',args{:},'USE_COHERENCE',false);
            testCase.verifyEqual(ignored.options.CUSTOM_WEIGHT,flipud(t.Weight(1:end-1)),'AbsTol',1e-10);
            testCase.verifyFalse(ignored.weighting.UseCoherence);
            ignored=fitTF('FNAME','weighted.csv',args{:},'COLUMN_MAP',struct('UseCoherence',false));
            testCase.verifyFalse(ignored.weighting.UseCoherence);
            testCase.verifyEqual(ignored.options.CUSTOM_WEIGHT,flipud(t.Weight(1:end-1)),'AbsTol',1e-10);
        end
        function badVectorWeightSizesFailBeforeFitting(testCase)
            testCase.verifyError(@()fitTF('F',[1 2 3],'TF',[1 2 3],...
                'COHERENCE',[0.5 1],'PLOT_TOGGLE',0),'RIFF:ImportWeights');
            testCase.verifyError(@()fitTF('F',[1 2 3],'TF',[1 2 3],...
                'CUSTOM_WEIGHT',[-1 1 1],'PLOT_TOGGLE',0),'RIFF:ImportWeights');
        end
        function dialogAppliesMapAndPreviewsInsideApp(testCase)
            mkdir('measured_TFs');
            writematrix([1 2 -1 0.5;2 3 -2 0.9;3 4 -3 1],'measured_TFs/raw.csv');
            app=RIFF;testCase.addTeardown(@()delete(app));
            originalPosition=app.UIFigure.Position;
            ui=fitTF('import-ui',app);
            testCase.choose(ui.Controls.Frequency,'Var1');
            testCase.choose(ui.Controls.FrequencyUnit,'Hz');
            testCase.choose(ui.Controls.ResponseType,'Real + imaginary');
            testCase.choose(ui.Controls.Real,'Var2');
            testCase.choose(ui.Controls.Imaginary,'Var3');
            testCase.choose(ui.Controls.Coherence,'Var4');
            testCase.verifyEqual(ui.Apply.Enable,matlab.lang.OnOffSwitchState.on);
            testCase.press(ui.Apply);
            testCase.verifyEqual(app.FORMATDropDown.Value,'Auto / mapped');
            testCase.verifyFalse(isgraphics(ui.Figure));
            app.SMOOTH_LEVELEditField.Value=0;
            fitTF('APP',app,'FNAME','measured_TFs/raw.csv','PREVIEW_BODEPLOT_TOGGLE',1);
            testCase.verifyEqual(app.UIFigure.Position,originalPosition);
            testCase.verifyNotEmpty(findall(app.RightPanel,'Tag','RIFFBodeTab'));
            testCase.verifyEmpty(findall(groot,'Type','figure','Name','System Identification'));
            ui=fitTF('import-ui',app);
            testCase.verifyEqual(ui.Controls.Coherence.Value,4);
            testCase.press(ui.Cancel);
        end
        function mappingDoesNotLeakToOtherFiles(testCase)
            mkdir('measured_TFs');t=table([1;2],[1;2],[0.3;0.8],'VariableNames',{'f','TF','Coherence'});
            writetable(t,'measured_TFs/a.csv');
            writetable(t(:,[3 2 1]),'measured_TFs/b.csv');
            app=RIFF;testCase.addTeardown(@()delete(app));
            app.ChooseTFListBox.Value='a.csv';ui=fitTF('import-ui',app);
            testCase.press(ui.Apply);
            app.ChooseTFListBox.Value='b.csv';ui=fitTF('import-ui',app);
            testCase.verifyEqual(ui.Controls.Frequency.Value,3);
            testCase.verifyEqual(ui.Controls.Coherence.Value,1);
            testCase.press(ui.Cancel);
            % The same file can reorder its named columns without changing meaning.
            writetable(t(:,[3 2 1]),'measured_TFs/a.csv');
            app.ChooseTFListBox.Value='a.csv';ui=fitTF('import-ui',app);
            testCase.verifyEqual(ui.Controls.Frequency.Value,3);
            testCase.verifyEqual(ui.Controls.Coherence.Value,1);
            delete(app);
            testCase.verifyFalse(isgraphics(ui.Figure));
        end
    end
    methods (Static,Access=private)
        function [f,h]=measurement(count,last)
            f=logspace(-2,log10(last),count)';
            h=squeeze(freqresp(zpk([],[-1+2i;-1-2i;-10],40),2*pi*f));
        end
        function args=fitArguments(f)
            args={'ROUTINE',5,'GUESS',[3 f(1) f(end) 5 5],...
                'MIN_POLES',3,'MAX_POLES',3,'NUM_TRIALS',1,'FUNC_EVAL',10,...
                'OPTIMIZER','FMINCON','DAMP_RESONANCES',0,'F_INITIAL',f(1),...
                'F_FINAL',f(end),'FREQ_WIN_LOW',0,'FREQ_WIN_UP',0,...
                'SMOOTH_LEVEL',0,'PLOT_TOGGLE',0,'SAVE_TOGGLE',0,'INTERMEDIATE_PLOT',0};
        end
    end
end
