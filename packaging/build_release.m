function packageFile = build_release()
%BUILD_RELEASE Test RIFF and build its versioned MATLAB R2026b+ installer.
%   From the repository root: addpath('packaging'); build_release
%   Output: release/<VERSION>/RIFF.mltbx. VERSION is the package version.
%   Runtime functionality remains in src/fitTF.m; this is a maintainer tool.

    if isMATLABReleaseOlderThan('R2026b')
        error('RIFF:BuildRelease','Build this release with MATLAB R2026b or newer.');
    end
    root = fileparts(fileparts(mfilename('fullpath')));
    version = strtrim(fileread(fullfile(root,'VERSION')));
    assert(~isempty(regexp(version,'^\d+\.\d+\.\d+$','once')),...
        'RIFF:BuildVersion','VERSION must use major.minor.patch.');
    source = fullfile(root,'src');
    oldPath = path;
    cleanup = onCleanup(@()path(oldPath));
    addpath(source,fullfile(source,'utils'),'-begin');
    app = RIFF;
    appCleanup = onCleanup(@()delete(app));
    assert(strcmp(app.RIFTLabel.Text,['RIFF v',regexprep(version,'\.0$','')]),...
        'RIFF:AppVersion','App panel and VERSION disagree.');
    clear appCleanup

    fprintf('Release %s: check source -> run regression tests -> package\n',version);
    issues = checkcode(fullfile(source,'fitTF.m'),'-id');
    assert(~any(ismember({issues.id},{'PARSE','FXUP'})),...
        'RIFF:SourceCheck','Resolve source errors before packaging.');
    suite = testsuite(fullfile(root,'tests'));
    results = run(suite);
    disp(table(results));
    out = fullfile(root,'release',version);
    if ~isfolder(out), mkdir(out); end
    save(fullfile(out,'test_results.mat'),'results');
    assertSuccess(results);
    assert(all([results.Passed]),'RIFF:IncompleteTests','All release tests must pass.');

    % Stable identity inherited from RIFF's original App Installer.
    identifier = '4197d6b4-d3ad-4097-8545-ba348852dca6';
    files = [collectFiles(source);collectFiles(fullfile(root,'measured_TFs'));...
        collectFiles(fullfile(root,'tutorials'));...
        string(fullfile(root,{'README.md','LICENSE','VERSION','release_notes.md'}))';...
        collectFiles(fullfile(root,'benchmarks'))];
    opts = matlab.addons.toolbox.ToolboxOptions(root,identifier,...
        'ToolboxFiles',files,'ToolboxMatlabPath',{source,fullfile(source,'utils')});
    opts.ToolboxName = 'RIFF — Robust IIR Fitting & Filtering';
    opts.PackageName = 'riff';
    opts.ToolboxVersion = version;
    opts.AuthorName = 'Nikhil Mukund Menon';
    opts.Summary = 'Fit measured transfer functions with tfest/N4SID and SysID AAA, with interactive Bode plots and manual refinement.';
    opts.Readme = fullfile(root,'README.md');
    opts.MinimumMatlabRelease = 'R2026b';
    opts.MaximumMatlabRelease = '';
    opts.UseLicenseBSD = false; % Preserve the repository's GPL-3.0 license.
    opts.AppGalleryFiles = fullfile(source,'RIFF.mlapp');
    opts.ToolboxImageFile = fullfile(root,'tutorials','RIFF_pole_zero_editor.png');
    opts.ProductDependencies = ["Control System Toolbox","System Identification Toolbox",...
        "Optimization Toolbox","Global Optimization Toolbox",...
        "Signal Processing Toolbox","Curve Fitting Toolbox"];
    opts.Tags = ["system identification","transfer function","IIR","Bode","AAA"];
    packageFile = fullfile(out,'RIFF.mltbx');
    opts.OutputFile = packageFile;
    matlab.addons.toolbox.packageToolbox(opts);
    packageInfo = dir(packageFile);
    assert(isscalar(packageInfo) && packageInfo.bytes > 0,'RIFF:EmptyPackage','Package missing or empty.');
    fprintf('Built %s (%d bytes); %d tests passed.\n',packageFile,packageInfo.bytes,numel(results));
end

function files = collectFiles(folder)
    listing = dir(fullfile(folder,'**','*'));
    listing = listing(~[listing.isdir]);
    files = string(fullfile({listing.folder},{listing.name}))';
end
