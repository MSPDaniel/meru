FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie
ARG MERU_VERSION=3.63.2
ARG TARGETARCH=amd64
ENV TITLE="Meru" PIXELFLUX_WAYLAND=false
RUN set -eux; \
    test "$TARGETARCH" = amd64; \
    apt-get update; apt-get install -y --no-install-recommends curl ca-certificates python3 libnss3 libatk-bridge2.0-0 libgtk-3-0 libasound2 libgbm1 libsecret-1-0 xdg-utils; \
    python3 - "$MERU_VERSION" <<'PY'
import json,sys,urllib.request
version=sys.argv[1]
url=f'https://api.github.com/repos/zoidsh/meru/releases/tags/v{version}'
req=urllib.request.Request(url,headers={'User-Agent':'meru-builder','Accept':'application/vnd.github+json'})
with urllib.request.urlopen(req,timeout=30) as r: release=json.load(r)
assets=[a for a in release['assets'] if a['name'].lower().endswith('.deb') and 'arm64' not in a['name'].lower() and 'aarch64' not in a['name'].lower()]
if len(assets)!=1: raise SystemExit(f'Expected one amd64 .deb asset; found {[a["name"] for a in assets]}')
asset=assets[0]
print('Downloading official asset:',asset['name'])
req=urllib.request.Request(asset['browser_download_url'],headers={'User-Agent':'meru-builder'})
with urllib.request.urlopen(req,timeout=180) as r,open('/tmp/meru.deb','wb') as f:
    while chunk:=r.read(1024*1024):f.write(chunk)
PY
RUN apt-get install -y --no-install-recommends /tmp/meru.deb && rm -f /tmp/meru.deb && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY root/ /
RUN chmod +x /defaults/autostart
EXPOSE 3001
VOLUME /config
