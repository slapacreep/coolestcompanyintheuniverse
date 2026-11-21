# Coolest Company — Supabase multiplayer lobby prototype

## Quick setup

1. Supabase Dashboard → **Authentication → Providers → Anonymous Sign-Ins** → enable (the exact menu may vary).
2. Supabase Dashboard → **SQL Editor** → paste and run the entire `supabase-setup.sql` file. Use a fresh project. This file creates two `cc_*` tables, secure RPCs, row-level security, and Realtime publication entries.
3. Upload **the extracted contents** of this folder to a **GitHub Pages staging repository** (do not replace your live domain before testing). For staging, remove `CNAME` so GitHub Pages doesn't claim your production domain. Change links only when ready for production.
4. Open your site over HTTPS, press **Practise free**, enter a name, share the unique URL. A second private browser/device can join. Both see the roster. Host chooses a team/logo and clicks Start. Both browsers enter a *locally simulated* game on the same countdown.
5. Test a second browser and mobile; check the browser console if a room fails. If you see “Anonymous sign-ins disabled,” enable that provider. If you see “function not found,” run SQL and refresh.

## Winner reveal and spectating
- The round-end presentation expands to a full-arena view with **one single, giant winning team logo** (not repeating tile badges), whether your squad won or lost.
- A locally eliminated practice player keeps watching the remaining match rather than being automatically shown a game-over dialog. This does **not** synchronize spectating across devices; multiplayer spectator camera switching needs the live game-state backend.

## Implemented
- Actual hosted rooms, unique invite tokens, Supabase anonymous identities, 4-person roster, live changes plus periodic refresh, host-only team editing and synchronized countdown.
- Player names, 4 player marker colours in lobby, upload team badge (96×96 compressed), preselected companies (Qatar Airways, Amazon, Meta, X, NVIDIA, China, United Kingdom, etc.), share links and manual reminder.
- Existing game, trailer, audio controls and legacy paid flow kept. The original standalone practice engine launches on each participant's device.

## Not yet real multiplayer
- Gameplay **physics, player positions, combat, spectating, teammate markers and scores are NOT synchronized** across devices. Local player score uploads are user-submitted and **not prize-safe**.
- Voice chat not implemented: needs a LiveKit server/token endpoint or another WebRTC signalling service. Do not claim teammate voice is live.
- Paid entry is unchanged, and checkout receipts do not grant Supabase room access. No verified payment webhook or entitlement gates.
- Personal uploaded logos are displayed in the practice match; never upload sensitive images. Membership is link-based. Anonymous sessions can be reset by clearing browser storage.
- Browser-based session timing is approximate across client clocks. Match-start signal is server-timestamped, but clocks may differ slightly.

## Security
Supabase client publishable key is public by design. **Never put an `sb_secret_` key in this repository.** RLS allows reads only for members; all mutations use narrowly checked RPCs. Room invite tokens are bearer capabilities: do not share them publicly. Anonymous sign-ins are for prototype only. Add rate limits, abuse controls and a verified auth mechanism before commercial release.

## Live URL
For `https://www.coolestcompanyintheuniverse.com`, retain `CNAME` when ready to use production. For preview/staging remove `CNAME` and use `https://YOURNAME.github.io/REPO/`.
