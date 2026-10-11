# Building a RIFF release

Use MATLAB R2026b or newer with RIFF's required products and RF Toolbox (the test
suite also compares the optional RF backend). Close any running RIFF windows.

1. Update `VERSION` (semantic version), the app panel label, and the app's metadata.
2. Update the README and release notes. Keep the older R2023b release available.
3. From the repository root, run:

   ```matlab
   addpath('packaging');
   packageFile = build_release();
   ```

The build checks the version/source, runs the full suite, and only packages if
all tests pass. It creates `release/<VERSION>/RIFF.mltbx` and `test_results.mat`.
The installer registers RIFF in the Apps gallery, adds `src` and `src/utils` to
the MATLAB path, and declares MATLAB R2026b as its minimum release. It keeps the
original add-on UUID and GPL-3.0 license. RF Toolbox remains optional for users.

Files are explicitly collected from `src`, `measured_TFs`, `tutorials`, and
`benchmarks`, plus the README, license, version, and release notes. Working
folders, local Simulink build caches, `.git`, and test output do not ship.

Before publishing, use a test installation with no existing RIFF package.
Install the built artifact in a fresh MATLAB `-batch` session using
the following command:

```matlab
mpminstall(packageFile,Temporary=true, ...
    Prompt=false,PathPosition="begin");
```

Verify that `which RIFF` and `which fitTF` resolve to the installed package. Test
an AAA fit, native preview, Verify, and manual editing from that installation.
Do not combine a temporary test with version replacement on a working
installation: replacement can remove the previous package files even though
the new registration is session-only. Back up an existing installation before
performing upgrade tests.

Create the release tag on the tested commit, push the commit and tag, and publish
a non-prerelease GitHub release with `RIFF.mltbx` and its `SHA256SUMS.txt`. Keep
build outputs out of Git; the source archive is supplied by GitHub. Never move
an existing published release tag.
