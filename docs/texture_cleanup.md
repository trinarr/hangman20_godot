# Texture usage cleanup

The production source/config audit retains 160 textures. El Tigre's seven state
scenes, their nested scene and all 56 textures are protected, including the unused
standalone portrait in `img/_______405...png`. No El Tigre image was modified.
Application launcher assets, both locales' logos, theme icon catalogs, paper,
rewards, live character frames and UI icons remain.

Nine obsolete PNGs and their import descriptors were removed:

- Six long-button slices (`user_main_button_21_*` and `user_main_button_23_*`).
- Two round-button backgrounds (`user_round_button_36` and `user_round_button_38`).
- The unused standalone Lucky portrait (`img/_______3...png`).

The PNG sources totaled 172,681 bytes. This is source size, not an APK estimate.
The historical art-upscale manifest now lists only its surviving 148 images.
The GPU button regression verifies procedural states against calibrated palette
values, so it no longer needs legacy image fixtures.

Run `python3 tools/audit_texture_usage.py` to check production image references,
launcher settings and explicit El Tigre protection. It never deletes files.
Editor-history manifests, documentation and tests are not runtime roots. Literal
references in legacy scripts are retained conservatively because such resources
may still be preloaded. Dynamic texture templates require manual review.
