classdef RIFFReleaseTest < matlab.unittest.TestCase
    % Fresh-install startup and release metadata regression checks.
    properties
        Root
    end
    methods (TestClassSetup)
        function sources(testCase)
            testCase.Root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(testCase.Root,'src')));
        end
    end
    methods (TestMethodSetup)
        function temporaryFolder(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
    methods (Test)
        function emptyMeasurementFolder(testCase)
            app = RIFF;
            testCase.addTeardown(@()delete(app));
            app.UIFigure.Visible = 'off';
            testCase.verifyTrue(isfolder('measured_TFs'));
            testCase.verifyEmpty(app.ChooseTFListBox.Items);
            testCase.verifyEmpty(app.ChooseTFListBox_2.Items);
        end
        function oneTextMeasurementAndRefresh(testCase)
            mkdir('measured_TFs');
            copyfile(fullfile(testCase.Root,'measured_TFs','sample_TF.txt'),'measured_TFs');
            app = RIFF;
            testCase.addTeardown(@()delete(app));
            app.UIFigure.Visible = 'off';
            testCase.verifyEqual(string(app.ChooseTFListBox.Items),"sample_TF.txt");
            testCase.verifyEqual(string(app.ChooseTFListBox.Value),"sample_TF.txt");
            callback = app.RefreshButton.ButtonPushedFcn;
            callback(app.RefreshButton,[]);
            testCase.verifyEqual(string(app.ChooseTFListBox.Items),"sample_TF.txt");
            testCase.verifyEqual(string(app.ChooseTFListBox.Value),"sample_TF.txt");
            delete(fullfile('measured_TFs','sample_TF.txt'));
            callback(app.RefreshButton,[]);
            testCase.verifyEmpty(app.ChooseTFListBox.Items);
        end
        function oneSdfMeasurementAndRefresh(testCase)
            mkdir('measured_TFs');
            copyfile(fullfile(testCase.Root,'measured_TFs','N1_100mHz_100Hz.DAT'),'measured_TFs');
            app = RIFF;
            testCase.addTeardown(@()delete(app));
            app.UIFigure.Visible = 'off';
            testCase.verifyEqual(string(app.ChooseTFListBox_2.Items),"N1_100mHz_100Hz.DAT");
            testCase.verifyEqual(string(app.ChooseTFListBox_2.Value),"N1_100mHz_100Hz.DAT");
            callback = app.RefreshButton.ButtonPushedFcn;
            callback(app.RefreshButton,[]);
            testCase.verifyEqual(string(app.ChooseTFListBox_2.Items),"N1_100mHz_100Hz.DAT");
            testCase.verifyEqual(string(app.ChooseTFListBox_2.Value),"N1_100mHz_100Hz.DAT");
            delete(fullfile('measured_TFs','N1_100mHz_100Hz.DAT'));
            callback(app.RefreshButton,[]);
            testCase.verifyEmpty(app.ChooseTFListBox_2.Items);
        end
        function versionMatchesRelease(testCase)
            version = strtrim(fileread(fullfile(testCase.Root,'VERSION')));
            app = RIFF;
            testCase.addTeardown(@()delete(app));
            app.UIFigure.Visible = 'off';
            testCase.verifyEqual(app.RIFTLabel.Text,['RIFF v',regexprep(version,'\.0$','')]);
            reader = appdesigner.internal.serialization.FileReader(fullfile(testCase.Root,'src','RIFF.mlapp'));
            metadata = reader.readAppMetadata();
            testCase.verifyEqual(metadata.Version,version);
            testCase.verifyEqual(metadata.MinimumSupportedMATLABRelease,'R2026b');
        end
    end
end
