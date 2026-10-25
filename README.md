# JUST 1€ — France 2026–2027

A public GitHub Pages archive with private editor login, camera/photo upload, and Supabase-backed records.

## What's in this starter

- Public responsive archive, search, unit-type filter, record details, object and price evidence images.
- Editor login via Supabase Auth (email/password), with editor allowlist and RLS.
- iPhone-compatible camera input, place/terms/units, geolocation (optional), draft/publish, and deletion.
- Public archive reads only published observations; drafts are visible only to authenticated editors.
- The site loads in **preview mode** until Supabase is configured.

## Setup (about 15–30 minutes, accounts required)

1. Create a **Supabase** project. In SQL Editor, execute `schema.sql` **once** in a new project. This script assumes the policies do not already exist.
2. In **Authentication > Users**, create/invite your own email/password user. Copy the user's UUID.
3. In SQL Editor run: `insert into public.editors(user_id) values ('YOUR-AUTH-USER-UUID');` replacing the placeholder. Only this account may edit. Disable open public signups if not needed.
4. In **Project Settings > API**, copy the Project URL and **publishable/anon** key. Edit `config.js` to insert those two values. **Never** put a `service_role`/secret key or your password in client-side files.
5. Create a GitHub repository, upload the files from this folder to the repository root, and enable **Settings > Pages > Deploy from branch > main / (root)**. Visit the Pages URL after deployment.
6. Click **EDIT**, sign in, capture two photos, enter item and place, then save. Records start as drafts unless you check Publish.

## Important limitations / next iteration

- **Photo storage is public**: the Supabase bucket is public and a draft photo's URL can be viewed by anyone who obtains the URL, even though drafts are not listed publicly. Do not upload sensitive/private photographs. For truly private drafts, use a private bucket plus authenticated access/signed URLs in a later version.
- Photos are uploaded directly from the browser; there is no offline queue yet. Upload requires connectivity. iOS may save photos as HEIC; browser compatibility can vary.
- The initial archive stores observations independently. `offers` and `offer_id` exist in the schema for later manual deduplication/episode management, but **this first version does not yet provide an OFFER linking interface**. Counts of offers are provisional and currently count unlinked observations as offers.
- There is no ZIP export/backup in this first version; use Supabase backups/export until the next release. Avoid treating this as the sole permanent archive.
- Records can be published/unpublished/deleted by an editor. Editing existing metadata and replacing photos will be added next.
- Location coordinates are stored in the private table but excluded from the public archive view. Store/location names and notes ARE public when published; don't put private details in them.
- The public archive is limited to the most recent 500 records in this starter; pagination is a next step.
- Browser camera inputs use the native camera/file picker; they do not provide a continuous custom live camera view.
- This is a working starter project, **not a deployed site**. A GitHub repository and Supabase project must be connected/configured by the owner.

## Architecture

- `index.html` / `style.css` — public archive and modal editor interface
- `app.js` — Supabase authentication, archive listing, image uploads, record creation
- `config.js` — public project URL/key (not passwords)
- `schema.sql` — database tables, policies, public view, storage bucket
- `manifest.webmanifest` — home-screen metadata

## Security

The edit button is not the security boundary. Supabase Auth and Postgres RLS policies restrict writes and draft reads. The `editors` allowlist must be populated by the project owner in the Supabase dashboard. Do not expose secrets in GitHub.
