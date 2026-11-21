# Coolest Company in the Universe — GitHub Pages deployment

## Included
- `index.html`: the existing game with an accessible **Watch game trailer** button.
- `audio/theme.mp3`: game audio.
- `video/trailer.mp4`: web-optimized version of supplied trailer (~5.5 MB, 720p).
- `CNAME`: custom domain `www.coolestcompanyintheuniverse.com`.
- `.nojekyll`: serve assets as-is.

## Publish
1. In GitHub, create a public repository (or use your existing Pages repository).
2. Upload the *contents* of this ZIP to the repository root and commit to the `main` branch.
3. Under **Settings > Pages**, set **Deploy from a branch**, `main`, `/(root)`.
4. In **Settings > Pages > Custom domain**, confirm `www.coolestcompanyintheuniverse.com` and save.
5. At your domain registrar/DNS provider, set the `www` **CNAME** to `<YOUR-GITHUB-USERNAME>.github.io` (do NOT include the repository name); remove any conflicting existing `www` records. **Avoid changing unrelated email MX/TXT records.**
6. Wait for DNS and HTTPS certificate provisioning; enable **Enforce HTTPS** when GitHub offers it.
7. Test the game and trailer on both mobile and desktop at https://www.coolestcompanyintheuniverse.com.

**Existing website warning:** If this domain already serves a site, changing its DNS will move traffic away from that host. Back up and plan migration first.

## Trailer performance
The video has **no source attribute until a visitor presses Watch game trailer**, and the video has `preload="none"`. It is not downloaded or decoded during initial page load. The video is paused and unloaded when the modal closes. The game soundtrack is paused while the trailer plays and resumed afterward if previously active. The optimized 720p video is ~5.5 MB instead of ~39 MB.

## Important: commercial functionality is not included
This static site does not include the `/api` backend, payment processing, synchronized live multiplayer, registration verification, or email services. Do not accept payments or promise working paid multiplayer until those backend components are implemented and tested. The site copy may describe capabilities or event dates that are not yet operational.
