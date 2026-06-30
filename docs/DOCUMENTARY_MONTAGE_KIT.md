# Documentary Montage Kit

This kit is the zero-key/no-GPU production layer for documentary montage work.
It gives the agent a consistent place to find free footage sources, local BGM,
social templates, and reusable brief presets.

## What It Enables

- Build real-footage videos without video-generation APIs.
- Prefer local royalty-free BGM before any paid/generated music.
- Target TikTok, Reels, Shorts, square feed, or YouTube landscape from one brief.
- Add user-owned scripts and footage without changing pipeline code.
- Keep source choices auditable and repeatable across projects.

## Folders

Create these folders locally as needed:

```text
footage_library/
├── documentary/
└── broll/

music_library/

scripts/
└── documentary_montage/
```

Suggested organization:

```text
footage_library/broll/
├── cities/
├── weather/
├── work/
├── nature/
└── archive/

music_library/
├── elegiac/
├── urgent/
├── reverent/
├── wry/
└── dreamlike/
```

These directories are local working libraries for user-owned or royalty-free
material. Keep license notes beside tracks and footage when possible.

## Inspect The Kit

```bash
make documentary-kit
make documentary-kit-assets
```

The first command prints source/template metadata. The second also checks local
footage, music, and script library file counts.

## Templates

Templates live in `content_kits/documentary_montage.yaml`.

| Template | Use |
|----------|-----|
| `tiktok_vertical` | Fast vertical mood pieces with safe caption zones. |
| `instagram_reels` | Vertical social cuts with phrase captions. |
| `youtube_shorts` | 60-second vertical explainers or news-poems. |
| `instagram_square` | Feed-native 1:1 edits. |
| `youtube_landscape` | 16:9 documentary shorts and essays. |

Use template names in prompts:

```text
Create a documentary montage using template=youtube_shorts, tone=urgent,
source_mix=zero_key, narration=piper, and BGM from music_library.
```

## Recommended Zero-Key Sources

No API key:

- `archive_org`
- `nasa`
- `wikimedia`
- `coverr`
- `mixkit`
- `dareful`
- `nara`
- `loc`
- `pond5_pd`
- `esa`
- `jaxa`
- `noaa`

Free developer key:

- `pexels`
- `pixabay_video`
- `unsplash`

## Adding BGM

Put tracks in `music_library/`, ideally grouped by tone:

```text
music_library/elegiac/slow-piano.mp3
music_library/urgent/minimal-pulse.wav
music_library/dreamlike/tape-loop.m4a
```

The pipeline should prefer:

1. User-provided track path.
2. Matching local `music_library/` tone folder.
3. Any usable local BGM.
4. Explicit opt-out only if the user asks for no music.

## Adding Scripts

Put source briefs or narration drafts in:

```text
scripts/documentary_montage/
```

Recommended brief shape:

```yaml
topic: "What a city does before sunrise"
template: youtube_shorts
tone: elegiac
duration_seconds: 60
narration: piper
music: local
sources_allowed:
  - archive_org
  - nasa
  - wikimedia
  - coverr
end_tag: "THE DAY BEGINS BEFORE US."
beats:
  - "Empty roads under sodium light"
  - "Workers preparing shops"
  - "First trains and buses"
  - "Windows turning on one by one"
```

## Development Notes

- Keep `content_kits/documentary_montage.yaml` data-only.
- Put reusable loading logic in `lib/documentary_kit.py`.
- Stage directors should read the kit before inventing source mixes.
- New stock providers should still be implemented as adapters under
  `tools/video/stock_sources/`.
- New Remotion visual treatments should extend `CinematicRenderer` or add a
  dedicated renderer family behind `video_compose`.
