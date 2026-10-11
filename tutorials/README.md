# Current RIFF walkthroughs

These three captioned MP4s show RIFF **v4.0.1** on MATLAB **R2026b**, using the
app's default 1299 × 693 window layout. They are genuine app captures assembled
as short scripted walkthroughs. Computation/rendering waits are omitted; the
videos are not wall-clock performance benchmarks. There is no audio.

| Demo | Length | Video size | Workflow |
|---|---:|---:|---|
| [Fit and inspect](demos/fitting.mp4) | 23 s | 242 KiB | Select CSV data, preview, AAA + tfest, inspect embedded plots |
| [Join frequency bands](demos/measurements.mp4) | 20 s | 212 KiB | Select three SDF measurements, join their bands, choose a fitting region |
| [Verify and refine](demos/refinement.mp4) | 26.8 s | 244 KiB | Select intermediate trials, inspect parameters, zoom to/drag a pole, change gain, reset |

The MP4s total **0.71 MB**, compared with **63.46 MB** for the previous GIF
collection (about 99% smaller). JPG thumbnails load in the README; videos play
on demand. Encoding: H.264, 1280 pixels wide, 24 fps, yuv420p, fast-start metadata.
Exact sizes and durations are in [manifest.json](demos/manifest.json).

The fit/refinement example uses a reproducible synthetic response with a small
perturbation. Its GOF is illustrative, not a claim about instrument accuracy.
The joining example uses the three bundled `N1`, `N2`, and `N3` SDF measurements.
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
It leaves PNG frames and `frames.csv` in the chosen output folder for inspection.
The encoder adds captions below the actual app image and creates MP4s/posters.
Only the compact outputs and scripts ship; raw frames stay outside the repository.

The older specialized walkthroughs (BADS, delay estimation, filtering, and others)
remain in [v3.0's tutorials](https://github.com/Nikhil-Mukund/RIFF/tree/v3.0/tutorials).
Their layouts/defaults differ from the current app.
