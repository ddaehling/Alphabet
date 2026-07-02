# Letter art pipeline (3D glossy bubble letters)

The a–z letter images in `Alphabet/Assets.xcassets/*.imageset/*.png` are generated
3D glossy "balloon" letters with transparent backgrounds. Pipeline:

1. **Generate** each letter with the OpenAI Codex CLI image skill (`gpt-image-2`),
   passing the *original* letter PNG as a structural+colour reference and the prompt
   in `prompt.txt`. The model returns an opaque PNG (it bakes a checkerboard instead
   of real alpha).
2. **Cut out** the background with `cutout.swift` — uses Vision's foreground-subject
   mask to produce a clean transparent PNG (no fragile colour-keying).
3. **Measure** mean opaque luminance with `lum.swift` to decide which letters are
   "pale" (they get a soft dark rim halo on light themes — see
   `LetterPalette.paleArt`). Threshold used: luminance ≥ 0.73.

## Commands (build the Swift tools once)
```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun swiftc -O scripts/letter-art/cutout.swift -o /tmp/cutout
xcrun swiftc -O scripts/letter-art/lum.swift   -o /tmp/lum

SK="$HOME/.claude/skills/codex-image"   # or the plugin path to codex-image
for L in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
  node "$SK/scripts/codex-image.mjs" --cwd . --prompt-file scripts/letter-art/prompt.txt \
    --out "images/raw/$L.png" --size 1024x1024 \
    --input "Alphabet/Assets.xcassets/$L.imageset/$L.png" --replace
  /tmp/cutout "images/raw/$L.png" "Alphabet/Assets.xcassets/$L.imageset/$L.png"
done
/tmp/lum Alphabet/Assets.xcassets/*.imageset/*.png | sort -t$'\t' -k2 -rn
```
Requires Codex CLI authenticated with ChatGPT (`codex login status`).

## Note on the shipped cutouts

The letters currently in the asset catalog were background-removed with **Adobe
(Photoshop) `image_remove_background`** (select-subject), which gave cleaner edges than
the local Vision cutout on some letters (e.g. "I"). `cutout.swift` (Vision) remains here
as a zero-dependency fallback. To redo via Adobe: upload each raw PNG to Adobe CC
(`asset_initialize_file_upload` → PUT bytes → `asset_finalize_file_upload`), call
`image_remove_background` with the returned `presignedAssetUrl`, then download `outputUrl`.
The pristine opaque originals can be recovered from the Codex image-gen rollouts under
`~/.codex/sessions/` (generated PNG is the base64 at `payload.result`).
