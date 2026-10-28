# Meru Webtop — GHCR / Unraid

Runs the official Meru Linux x64 release in LinuxServer Selkies with browser access, using Webtop `CUSTOM_USER` and `PASSWORD`. The existing working Dockerfile and X11 autostart are retained. Project icon in `assets/meru-icon.png` is a **custom project icon**, not the official Meru trademark.

## Automatic GitHub build and publish

1. Create the public GitHub repository **MSPDaniel/meru** and upload this project's contents to the repository root, including the hidden `.github/workflows/docker-publish.yml` file. Do **not** upload `.env`.
2. The workflow runs daily at **09:17 UTC** and queries the official `zoidsh/meru` GitHub API `/releases/latest` endpoint. GitHub may delay scheduled workflows, and schedules run only on the default branch. Drafts and prereleases are excluded; the workflow also verifies that the release includes an amd64 `.deb` installer.
3. If `ghcr.io/mspdaniel/meru:<version>` already exists, the scheduled build is skipped. Otherwise GitHub Actions builds and publishes both `:<version>` and `:latest` for Linux amd64.
4. A push changing the Dockerfile, startup scripts, or workflow also checks for the newest stable release. To rebuild an existing version after changing Dockerfile/scripts, use **Actions → Build and publish Meru → Run workflow → Force rebuild**.
5. Manual workflow runs can specify an exact stable `meru_version` or leave it blank for the latest stable release.
6. The first published GHCR package may be private. In GitHub package settings set **Visibility → Public** so Unraid can pull without credentials. Repository Actions workflow permissions must permit package publishing.
7. **Unraid does not update itself automatically.** To receive new versions, configure your Unraid template or Compose image to `ghcr.io/mspdaniel/meru:latest`, then pull/update the container through Unraid. Version-pinned deployments need a manual tag change.

The included `assets/meru-icon.png` is a custom navy square with a blue-and-white envelope, **not** the official Meru logo. The Unraid XML points to this icon on the repository's `main` branch.

## Unraid XML template

1. Once the repository is public, confirm the [raw Unraid template](https://raw.githubusercontent.com/MSPDaniel/meru/main/unraid/meru.xml) is accessible.
2. In Unraid Docker tab choose **Add Container**. If available, use **Template repositories** or copy `unraid/meru.xml` into `/boot/config/plugins/dockerMan/templates-user/my-meru.xml` and select the template from **Add Container**. Existing Unraid versions may have different template import UI.
3. Set the `Repository` to your GHCR image tag, choose a **new strong password**, and keep host port `3011` / container port `3001`. Appdata: `/mnt/user/appdata/meru`.
4. **Do not run the Compose container and the XML container simultaneously**: both use the name `meru` and host port `3011`. Stop and remove the Compose-created container first, but **do not delete** `/mnt/user/appdata/meru`.
5. Open `https://UNRAID-IP:3011` on LAN. Keep Authelia/NPM for internet access.

## Alternative: pull using Compose

```bash
cp .env.example .env
# Edit .env, set GHCR_OWNER, BIND_IP, WEBTOP_USER, WEBTOP_PASSWORD
# Stop and remove existing local Compose service first, preserving /mnt/user/appdata/meru
# Then:
docker compose pull
docker compose up -d
```

## Local build remains supported

```bash
docker compose -f compose.build.yaml build --progress=plain
docker compose -f compose.build.yaml up -d
```

The `MERU_VERSION` build argument is passed to the Dockerfile, which downloads the official `.deb` from `https://github.com/zoidsh/meru/releases` through the GitHub release API. Only amd64 is supported. The build uses the upstream `.deb`, not a prepackaged binary in this repository.

## Security and maintenance

- Webtop username/password protect the HTTPS entry point; use Authelia as an additional protection for internet access.
- `seccomp:unconfined` is retained from the tested Compose config but reduces isolation; reassess later.
- Change any passwords previously pasted into logs/chats; never commit `.env`.
- GitHub Packages visibility and Actions permissions must allow publishing; repository Settings → Actions → General → Workflow permissions may need read/write.
- The first GitHub-hosted build is not yet verified, even though the equivalent local image built and ran on Unraid.
- Do not store the repository/build files inside `/mnt/user/appdata/meru`, because that directory is mounted into the container as `/config`.

## Official Meru icon

The Unraid XML uses `assets/meru-icon.png`, extracted **unchanged** from the official upstream Linux amd64 `.deb` package by the GitHub Actions workflow. The first successful workflow run downloads the release, selects a Meru PNG application icon, and commits it to this repository. The custom placeholder icon has been removed. If the upstream package does not contain a recognizable PNG, the workflow fails rather than silently using a substitute.

The workflow needs **Actions → General → Workflow permissions → Read and write permissions** enabled if repository settings restrict `GITHUB_TOKEN` write access. Branch protection may also prevent the bot from committing the icon.
