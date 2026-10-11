function [comboTF,comboFF,BO,tfData,comboFRD] = combineTFs(varargin)
%COMBINETFS Combine SDF frequency-response measurements using fitTF's core.
%   [H,F] = combineTFs(FILES,DF) combines files in any order on a shared
%   frequency grid with maximum spacing DF Hz (default 0.25). Duplicate
%   frequencies and overlapping responses are averaged as complex values.
%   Unmeasured gaps are omitted; no extrapolation is performed.
%   FILES may also be structures with fields F (Hz) and TF (complex response).
%
%   [H,F,BO,DATA,G] = combineTFs(FILES,DF,BO,PLOT) also returns Bode options,
%   individual measurements and the combined FRD. PLOT defaults to true for
%   this legacy wrapper. Use fitTF('combine',FILES,DF) for a quiet core API.
%
%   See also fitTF, SDF_import, frd
narginchk(1,4);
args = varargin;
args(end+1:4) = {[]};
if isempty(args{4}), args{4} = true; end
source = fileparts(fileparts(mfilename('fullpath')));
oldPath = path;
cleanup = onCleanup(@()path(oldPath));
if ~strcmp(which('fitTF'),fullfile(source,'fitTF.m')), addpath(source,'-begin'); end
data = fitTF('combine',args{:});
comboTF = data.TF.'; comboFF = data.F'; BO = data.BodeOptions;
tfData = data.Measurements; comboFRD = data.FRD;
end
