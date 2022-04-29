function [comboTF,comboFF,BO,tfData,comboFRD] = combineTFs(dataSets,dF,BO,plotToggle)
%combineTFs.m Combine two transfer functions that span differnt but ovelapping
% frequency spans.
% INPUT:
%     dataSets:
%                 A cell array of SDF DAT files (with overlapping freqencies) saved from Agilent
%                 based Dynamic Signal Analyzer 35670A.
%           dF:
%                 desired final frequency resolution for te combo response
%           BO:
%                 bodeoptions
% OUTPUT:
%        Combined tranfer function & corresponding frequencies.
% EXAMPLE:
%        dataSets = {'TRAC17.DAT','TRAC18.DAT'};
%        [comboTF,comboFF] = combineTFs(dataSets,0.25,bodeoptions)
% AUTHOR:
%       Nikhil Mukund Menon (AEI, Hannover)
% LAST MODIFIED:
%       12th June, 2020
%

% Set figure properties
set(0,'DefaultAxesFontSize',20)
set(0,'DefaultLegendFontSize',20)
set(0,'DefaultTextFontSize',20)
set(0,'DefaultAxesLineWidth',2)
set(0,'DefaultLineLineWidth',2)


if nargin == 1
    dF = 0.25;
    plotToggle = 1;
    % Bodeplot options
    BO = bodeoptions;
    BO.PhaseWrapping = 'on';
    BO.PhaseWrappingBranch=-180;
    BO.FreqUnits = 'Hz';
    BO.Grid='on';
    
end

% set Warnings Off
warning('OFF')

% Initialize tfData structure
tfData = struct('FF',{},'TF',{});

if plotToggle
    FIG=figure();clf
    hold on
end

for ijk = 1:length(dataSets)
    
    x = SDF_import(dataSets{ijk});
    
    FF = x.SDF_XDATA_HDR.zz_data;
    TF = x.SDF_YDATA_HDR.zz_data(1:2:end)+1i*x.SDF_YDATA_HDR.zz_data(2:2:end);
    
    % discard -ve freq ?
    ID = FF>0;
    FF = FF(ID);
    TF = TF(ID);
    
    if plotToggle
        bodeplot(frd(TF,FF*2*pi),BO);
    end
    
    tfData(ijk).FF = FF;
    tfData(ijk).TF = TF;
    
    
end



% resample TFs
dFnew = dF;

% make freq interpolation
for ijk = 1:numel(tfData)
    FFnew = tfData(ijk).FF(1):dFnew: tfData(ijk).FF(end);
    TFnew = interp1(tfData(ijk).FF,tfData(ijk).TF,FFnew);
    
    tfData(ijk).FF = FFnew;
    tfData(ijk).TF = TFnew;
    tfData(ijk).FRD = frd(tfData(ijk).TF,2*pi*tfData(ijk).FF);
end


if numel(tfData) > 1
    % Merge diff freq spans into one signle TF
    for klm = 2:numel(tfData)
        olapFmin = min(tfData(klm).FF);
        olapFmax = max(tfData(klm-1).FF);
        
        iD1 = logical(logical(tfData(klm-1).FF > olapFmin) .* logical(tfData(klm-1).FF < olapFmax));
        iD2 = logical(logical(tfData(klm).FF > olapFmin) .* logical(tfData(klm).FF < olapFmax));
        
        FFtrun1  = tfData(klm-1).FF(iD1);
        FFtrun2  = tfData(klm).FF(iD2);
        
        
        [~,mID1] = min(abs(angle(tfData(klm).TF(iD2)) - angle(tfData(klm-1).TF(iD1))));
        
        
        comboFF = [ tfData(klm-1).FF(  tfData(klm-1).FF <=  FFtrun1(mID1) ) tfData(klm).FF(  tfData(klm).FF >=  FFtrun2(mID1) ) ];
        comboTF = [ tfData(klm-1).TF(  tfData(klm-1).FF <=  FFtrun1(mID1) ) tfData(klm).TF(  tfData(klm).FF >=  FFtrun2(mID1) ) ];
        
        
        
        
        tfData(klm).FF = comboFF(1):dFnew:comboFF(end);
        tfData(klm).TF = interp1(comboFF,comboTF,tfData(klm).FF);
        tfData(klm).FRD = frd(tfData(klm).TF,2*pi*tfData(klm).FF);
        
    end
else
    comboFF  = tfData(1).FF;
    comboTF  = tfData(1).TF;
end

if plotToggle
    bodeplot(frd(tfData(end).TF,2*pi*tfData(end).FF),BO)
    set(findall(FIG,'type','line'),'linewidth',2)
    % highlight the final plot
    LINES = findobj(gcf,'type','line');
    LINES(end-numel(dataSets)).LineWidth=2;
    LINES(end-2*numel(dataSets)-1).LineWidth=2;
    if isa(dataSets,'string')
        dataSets = cellstr(dataSets);
        dataSets{end+1} = 'combined TF';
        legend(dataSets);
    else
        legend([dataSets,{'combined TF'}])
    end
end

comboFRD = frd(comboTF,2*pi*comboFF);

end
