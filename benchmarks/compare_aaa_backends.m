function results = compare_aaa_backends(outputFolder)
%COMPARE_AAA_BACKENDS Compare RIFF fitting algorithms on held-out frequencies.
% Estimate on four out of every five samples; the fifth is validation only.
% Order/weight choices are ranked by training GOF, never validation GOF.
% These are interleaved samples from the same sweep, not independent repeats.
    if nargin == 0, outputFolder = tempname; end
    if ~isfolder(outputFolder), mkdir(outputFolder); end
    root = fileparts(fileparts(mfilename('fullpath')));
    previousRng = rng; cleanup = onCleanup(@()rng(previousRng)); %#ok<NASGU>
    rng(42,'twister');
    files = dir(fullfile(root,'measured_TFs','*.txt'));
    rows = {}; maxSamples = 600; orders = [4 8 12];
    for fileIndex = 1:numel(files)
        raw = readmatrix(fullfile(files(fileIndex).folder,files(fileIndex).name));
        raw = raw(all(isfinite(raw(:,1:3)),2) & raw(:,1)>0,1:3);
        [~,uniqueRows] = unique(raw(:,1)); raw = raw(uniqueRows,:);
        raw = raw(unique(round(linspace(1,size(raw,1),min(maxSamples,size(raw,1))))),:);
        f = raw(:,1); response = complex(raw(:,2),raw(:,3));
        validation = mod((1:numel(f))',5)==0; training = ~validation;
        ft = f(training); ht = response(training);
        data = idfrd(ht,2*pi*ft,0);
        % Inspect high-frequency phase slope as a delay diagnostic. No delay
        % is imposed on any algorithm in this comparison (RIFF's default).
        edge = max(1,floor(0.8*numel(ft))):numel(ft);
        phaseSlope = polyfit(2*pi*ft(edge),unwrap(angle(ht(edge))),1);
        fprintf('%s: %d training / %d held out; apparent phase-slope delay %.4g s\n',...
            files(fileIndex).name,nnz(training),nnz(validation),-phaseSlope(1));
        for modelOrder = orders
            for method = ["SysID AAA","SysID AAA refined","tfest N4SID","RF AAA default","RF AAA relative"]
                weightModes = ["equal","inverse"];
                if startsWith(method,"RF"), weightModes = "internal"; end
                for weightMode = weightModes
                    weight = ones(size(ht));
                    if weightMode == "inverse", weight = 1./max(abs(ht),max(abs(ht))*1e-10); end
                    started = tic; actualOrder=NaN; stable=false; trainGOF=NaN; validGOF=NaN;
                    complexFit=NaN; failure="";
                    try
                        if startsWith(method,"RF")
                            metric = 'default';
                            if endsWith(method,"relative"), metric = 'Relative'; end
                            fit = rational(ft,ht,'MaxPoles',modelOrder,'ErrorMetric',metric,'QLimit',1e7);
                            model = ss(zpk(tfFromResidues(fit)));
                        elseif method == "tfest N4SID"
                            opt = tfestOptions('InitializeMethod','n4sid','EnforceStability',true,...
                                'WeightingFilter',weight,'EstimateCovariance',false,'Display','off');
                            opt.SearchOptions.MaxIterations = 20;
                            model = tfest(data,modelOrder,modelOrder,opt);
                        else
                            opt = ssestOptions('InitializeMethod','AAA','Focus','simulation',...
                                'InteractiveOrderSelection',false,'EstimateCovariance',false,...
                                'EnforceStability',true,'WeightingFilter',weight,'Display','off');
                            opt.SearchOptions.MaxIterations = 0;
                            if method == "SysID AAA refined", opt.SearchOptions.MaxIterations=20; end
                            model = ssest(data,modelOrder,'Ts',0,'Feedthrough',true,opt);
                            % AAA may return nx+1 states when adding a pair.
                            % Retry with one fewer pole to honor RIFF's cap.
                            if order(model)>modelOrder
                                model = ssest(data,modelOrder-1,'Ts',0,'Feedthrough',true,opt);
                            end
                        end
                        actualOrder=order(model); stable=isstable(model);
                        trainGOF=riffScore(ht,squeeze(freqresp(model,2*pi*ft)));
                        predicted=squeeze(freqresp(model,2*pi*f(validation)));
                        validGOF=riffScore(response(validation),predicted);
                        complexFit=100*(1-norm(response(validation)-predicted)/...
                            norm(response(validation)-mean(response(validation))));
                    catch err
                        failure=string(err.identifier)+": "+string(err.message);
                    end
                    elapsed=toc(started);
                    rows(end+1,:)={string(files(fileIndex).name),method,modelOrder,weightMode,...
                        actualOrder,stable,trainGOF,validGOF,complexFit,elapsed,failure}; %#ok<AGROW>
                    fprintf('  %-18s n=%2d %-8s train %7.2f validation %7.2f (%5.2fs) %s\n',...
                        method,modelOrder,weightMode,trainGOF,validGOF,elapsed,failure);
                end
            end
            results=cell2table(rows,'VariableNames',{'Dataset','Method','RequestedOrder','Weight',...
                'ActualOrder','Stable','TrainingGOF','ValidationGOF','ValidationComplexFit','Seconds','Error'});
            writetable(results,fullfile(outputFolder,'aaa_comparison.csv'));
        end
    end
    selected=results([],:);
    groups=unique(results(:,{'Dataset','Method'}),'rows','stable');
    for n=1:height(groups)
        candidates=results(results.Dataset==groups.Dataset(n) & results.Method==groups.Method(n) & ...
            results.Stable & isfinite(results.TrainingGOF),:);
        if isempty(candidates), continue; end
        [~,best]=max(candidates.TrainingGOF); selected=[selected;candidates(best,:)]; %#ok<AGROW>
    end
    writetable(selected,fullfile(outputFolder,'aaa_selected_by_training.csv'));
    disp(selected(:,{'Dataset','Method','RequestedOrder','Weight','ValidationGOF','Seconds'}));
    save(fullfile(outputFolder,'aaa_comparison.mat'),'results','selected');
end

function model = tfFromResidues(fit)
    [b,a]=residue(squeeze(fit.Residues),squeeze(fit.Poles),squeeze(fit.DirectTerm));
    model=tf(real(b),a);
end

function gof = riffScore(observed,predicted)
    observed=observed(:); predicted=predicted(:);
    magnitude=log10(max(abs(observed),realmin));
    phase=mod(angle(observed)*180/pi+180,360)-180;
    modelPhase=mod(angle(predicted)*180/pi+180,360)-180;
    gof=100*(1-0.5*norm(magnitude-log10(max(abs(predicted),realmin)))/norm(magnitude-mean(magnitude))...
        -0.5*norm(phase-modelPhase)/norm(phase-mean(phase)));
end
