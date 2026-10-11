#!/usr/bin/env python3
"""Encode make_demos.m frames as captioned H.264 videos and looping GIF previews.

Usage: python3 tutorials/encode_demos.py /tmp/riff-demos tutorials/demos
Requires ffmpeg on PATH. Source screenshots stay in the temporary frame folder.
"""
import argparse
import csv
import json
import shutil
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('frames', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
ffmpeg = shutil.which('ffmpeg')
if not ffmpeg:
    raise SystemExit('Install ffmpeg and put it on PATH before encoding.')
args.output.mkdir(parents=True, exist_ok=True)
shutil.copyfile(args.frames / 'fit-settings.json', args.output / 'fit-settings.json')
rows = list(csv.DictReader((args.frames / 'frames.csv').open()))
metadata = []
# Prefer an explicit installed font to avoid fontconfig cache dependencies.
fonts = [Path('/System/Library/Fonts/Supplemental/Arial.ttf'),
         Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')]
font = next((path for path in fonts if path.is_file()), None)
font_option = f"fontfile='{font}':" if font else ''
for clip in dict.fromkeys(row['Clip'] for row in rows):
    frames = [row for row in rows if row['Clip'] == clip]
    marker = {'fitting':'Best fit:', 'refinement':'Inspect the manual response',
              'measurements':'Preview the combined response'}[clip]
    result_frame = next(frame for frame in frames if marker in frame['Caption'])
    # Lead each looping preview with its result so the README immediately
    # shows the broadband response. The setup/controls follow this short peek.
    frames.insert(0, dict(result_frame, Seconds='3',
                          Caption='Result preview | setup and controls follow'))
    timeline, captions, elapsed = [], [], 0.0
    for index, row in enumerate(frames):
        frame = (args.frames / row['File']).resolve()
        quoted = str(frame).replace("'", "'\\''")
        duration = float(row['Seconds'])
        timeline += [f"file '{quoted}'", f'duration {duration}']
        # Identical captions on sequential drag frames share one time span.
        if captions and captions[-1]['text'] == row['Caption']:
            captions[-1]['end'] += duration
        else:
            captions.append(dict(text=row['Caption'], start=elapsed, end=elapsed+duration))
        elapsed += duration
    timeline.append(timeline[-2])
    playlist = args.frames / f'{clip}.concat'
    playlist.write_text('\n'.join(timeline)+'\n')
    filters = ['scale=1280:-2', 'pad=iw:ih+76:0:0:color=0x151a22',
               'fps=24', 'tpad=stop_mode=clone:stop_duration=2']
    for index, caption in enumerate(captions):
        caption_file = (args.frames / f'{clip}-caption-{index}.txt').resolve()
        caption_file.write_text(caption['text'])
        filters.append(
            f"drawtext={font_option}expansion=none:textfile='{caption_file}':fontcolor=white:fontsize=21:"
            f"x=22:y=h-49:enable='gte(t,{caption['start']})*lt(t,{caption['end']})'"
        )
    video = args.output / f'{clip}.mp4'
    subprocess.run([ffmpeg, '-y', '-v', 'error', '-f', 'concat', '-safe', '0',
                    '-i', str(playlist), '-vf', ','.join(filters), '-t', str(elapsed),
                    '-r', '24', '-c:v', 'libx264', '-preset', 'slow', '-crf', '27',
                    '-pix_fmt', 'yuv420p', '-an', '-movflags', '+faststart', str(video)], check=True)
    # Select genuine result frames, rather than hard-coding walkthrough times.
    poster_caption = next(caption for caption in captions if marker in caption['text'])
    poster_time = poster_caption['start'] + min(1, (poster_caption['end']-poster_caption['start'])/2)
    poster = args.output / f'{clip}.jpg'
    subprocess.run([ffmpeg, '-y', '-v', 'error', '-ss', str(poster_time), '-i', str(video),
                    '-frames:v', '1', '-q:v', '3', str(poster)], check=True)
    # GitHub README image embeds animate GIFs; repository MP4 links are downloads.
    # Sparse UI changes compress well with a palette and transparent delta frames.
    preview = args.output / f'{clip}.gif'
    subprocess.run([ffmpeg, '-y', '-v', 'error', '-i', str(video),
                    '-filter_complex',
                    'fps=6,scale=960:-2:flags=lanczos,split[a][b];'
                    '[a]palettegen=max_colors=128:stats_mode=diff[p];'
                    '[b][p]paletteuse=dither=none:diff_mode=rectangle',
                    '-loop', '0', str(preview)], check=True)
    metadata.append(dict(clip=clip, duration_seconds=round(elapsed,2),
                         bytes=video.stat().st_size, preview_bytes=preview.stat().st_size,
                         preview_width=960, preview_fps=6))
    print(f'{video}: {elapsed:.1f} s, {video.stat().st_size/1024:.0f} KiB', flush=True)
(args.output / 'manifest.json').write_text(json.dumps(metadata, indent=2)+'\n')
