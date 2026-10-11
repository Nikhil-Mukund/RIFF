# Current RIFF walkthroughs

These three captioned MP4s show RIFF **v4.1.0** on MATLAB **R2026b**, using the
app's default 1299 × 693 window layout. They are genuine app captures assembled
as short scripted walkthroughs. Computation/rendering waits are omitted; the
videos are not wall-clock performance benchmarks. There is no audio.

| Demo | Length | Video size | Workflow |
|---|---:|---:|---|
| [Fit and inspect](demos/fitting.mp4?raw=true) | 32 s | 424 KiB | Preview the difficult measured response, smooth, fit with AAA + tfest, inspect broad and detailed views |
| [Join frequency bands](demos/measurements.mp4?raw=true) | 23 s | 338 KiB | Select three SDF measurements, join their bands, choose a fitting region |
| [Verify and refine](demos/refinement.mp4?raw=true) | 29.8 s | 331 KiB | Select intermediate trials, inspect parameters, zoom to/drag a pole, change gain, reset |

The README embeds full-width, looping **GIF previews** so the walkthroughs
animate on the repository's main page. The three previews total **2.53 MB**,
about 96% smaller than the previous **63.46 MB** GIF collection. Each preview
is 960 pixels wide at 6 fps, uses a 128-color palette, and retains the full
walkthrough and captions.

The full-resolution MP4s total **1.12 MB**. Encoding: H.264, 1280 pixels wide,
24 fps, yuv420p, fast-start metadata. Download them for playback controls and
higher resolution. JPG posters remain available for static previews. Exact
sizes and durations are in [manifest.json](demos/manifest.json).

The fitting and refinement examples use the bundled **`isolated_transmission.txt`**
instrument measurement, rather than a synthetic response. It has a deep notch
near 1 Hz, additional notches/resonances, a sharp resonance near 17.7 Hz, repeated
phase wraps, and a noisy high-frequency tail. The fitting overview stays at
**0.03–40 Hz**, except for a brief 0.5–2 Hz notch inspection before restoring the
broad view. The first three seconds of each clip preview its result; the setup
and controls follow.

The recorded settings are reproducible:

- Requested fitting band: **0.04–20 Hz**, spanning about 2.7 decades. RIFF's
  optimization also adjusts the band edges within its frequency search windows.
- Complex-response smoothing: **method 7, seven-sample moving mean**. Original
  and processed measurements are both visible in the fitting overview.
- Algorithms: **SysID AAA and N4SID-initialized tfest**, with stability enforced.
- Model search: **12–24 poles**, up to 23 zeros for tfest, **four FMINCON trials**,
  and the standard 20 function evaluations per trial. AAA uses a pole cap.
- Seed: **42**, with MATLAB's `twister` random generator.
- Recorded best fit: **tfest, 12 poles, GOF 47.60%**, over the optimized band
  **0.0331–22.317 Hz**. Exact values are in [fit-settings.json](demos/fit-settings.json).
  The winning weight is inverse magnitude. The mismatch at low frequencies
  and the noisy tail remain visible. This is RIFF's magnitude/phase score on
  the processed fitting region, not independent validation or a general claim
  about algorithm accuracy. Manual adjustment is demonstrated separately.

The joining example uses the three bundled `N1`, `N2`, and `N3` SDF measurements.
Its final view restores all joined bands after showing a temporary focus region.
It intentionally selects them out of frequency order. The importer can report
existing SDF metadata/window warnings for those legacy files; they remain visible
in MATLAB's Command Window.

The pole sequence sends real drag gestures through `matlab.uitest`, checks the
selected pole and conjugate position, and verifies reset restores the fitted
original. Zooming to the selected root makes small movements possible even when
other roots are far away. The recording illustrates inspection and reset, not
an improvement in GOF from manual adjustment.

## Reproduce

From the repository root in MATLAB R2026b with the required RIFF products:

```matlab
addpath('tutorials');
make_demos(fullfile(tempdir,'riff-demos'));
```

Then, with Python 3 and FFmpeg on PATH:

```sh
python3 tutorials/encode_demos.py /path/to/riff-demos tutorials/demos
```

The capture script uses a temporary working directory, copies the bundled input
files, and restores the MATLAB path, working folder, and random state afterward.
It leaves PNG frames, `frames.csv`, `recorded-fit.mat`, and `fit-settings.json`
in the chosen output folder for inspection. The JSON records the achieved score,
winning algorithm, order, and optimized band edges.
The encoder adds captions below the actual app image and creates MP4s, JPG
posters, and looping GIF previews.
Only the compact outputs and scripts ship; raw frames stay outside the repository.

The older specialized walkthroughs (BADS, delay estimation, filtering, and others)
remain in [v3.0's tutorials](https://github.com/Nikhil-Mukund/RIFF/tree/v3.0/tutorials).
Their layouts/defaults differ from the current app.

These broadband recordings were made with v4.1.0 and are available in the
current source checkout. The already-published v4.1.0 installer retains its
original compact recordings. The new column-mapping dialog is shown in
[the column-mapping screenshot](column_mapping.png); see the main README for
coherence weighting and command-line import examples.
