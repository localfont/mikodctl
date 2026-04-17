#!/usr/bin/env bash
# ============================================================
# rename_to_mikodctl.sh
# nerdctl fork'unu mikodctl olarak yeniden adlandırır.
# Kullanım: repo kök dizininde çalıştır → bash rename_to_mikodctl.sh
# ============================================================
set -euo pipefail

OLD="nerdctl"
NEW="mikodctl"
OLD_MODULE="github.com/containerd/nerdctl"
NEW_MODULE="github.com/localfont/mikodctl"
OLD_UPPER="Nerdctl"
NEW_UPPER="Mikodctl"
OLD_LABEL="NerdctlID\|NerdctlDefaultNetwork\|nerdctl/"
# (label sabitlerini ayrıca işleyeceğiz)

echo "========================================"
echo "  nerdctl → mikodctl rename başlıyor"
echo "========================================"

# ─── 1. go.mod: module path ───────────────────────────────
echo "[1/8] go.mod module path güncelleniyor..."
sed -i "s|${OLD_MODULE}|${NEW_MODULE}|g" go.mod go.sum 2>/dev/null || true

# ─── 2. Tüm .go dosyalarında import path'leri ─────────────
echo "[2/8] .go import path'leri güncelleniyor..."
find . -name "*.go" \
  ! -path "./.git/*" \
  -exec sed -i "s|${OLD_MODULE}|${NEW_MODULE}|g" {} +

# ─── 3. Tüm .go dosyalarında binary/komut adı referansları ─
echo "[3/8] .go içindeki binary adı referansları güncelleniyor..."

# Küçük harf "nerdctl" → "mikodctl"
find . -name "*.go" \
  ! -path "./.git/*" \
  -exec sed -i "s/\"${OLD}\"/\"${NEW}\"/g" {} +

# Cobra Use/Short/Long string içindeki nerdctl
find . -name "*.go" \
  ! -path "./.git/*" \
  -exec sed -i "s/\b${OLD}\b/${NEW}/g" {} +

# Büyük harf başlangıçlı (Nerdctl → Mikodctl) — Go struct/type isimleri
find . -name "*.go" \
  ! -path "./.git/*" \
  -exec sed -i "s/${OLD_UPPER}/${NEW_UPPER}/g" {} +

# ─── 4. pkg/ içindeki özel label sabitleri ────────────────
echo "[4/8] pkg/ label sabitleri güncelleniyor..."
# Örnek: labels.NerdctlID → labels.MikodctlID
#        "nerdctl/bypass4netns" annotation → "mikodctl/bypass4netns"
find ./pkg -name "*.go" \
  ! -path "./.git/*" \
  -exec sed -i \
    -e "s/NerdctlID/MikodctlID/g" \
    -e "s/NerdctlDefaultNetwork/MikodctlDefaultNetwork/g" \
    -e "s|nerdctl/bypass4netns|mikodctl/bypass4netns|g" \
    -e "s|nerdctl-default|mikodctl-default|g" \
    {} +

# ─── 5. Shell completion scriptleri ──────────────────────
echo "[5/8] Shell completion dosyaları güncelleniyor..."

# completion.go ve completion_linux.go içindeki hardcode adlar
find . \( -name "completion.go" -o -name "completion_linux.go" \) \
  ! -path "./.git/*" \
  -exec sed -i "s/${OLD}/${NEW}/g" {} +

# Eğer /etc/bash_completion.d/ yolu hardcode yazılmışsa
find . -name "*.go" \
  ! -path "./.git/*" \
  -exec sed -i \
    -e "s|bash_completion.d/${OLD}|bash_completion.d/${NEW}|g" \
    -e "s|zsh/site-functions/_${OLD}|zsh/site-functions/_${NEW}|g" \
    {} +

# ─── 6. Dizin yeniden adlandırmaları ─────────────────────
echo "[6/8] Dizinler yeniden adlandırılıyor..."

# cmd/nerdctl → cmd/mikodctl
if [ -d "cmd/${OLD}" ]; then
  mv "cmd/${OLD}" "cmd/${NEW}"
  echo "  cmd/${OLD} → cmd/${NEW}"
fi

# cmd/mikodctl/completion klasörü varsa (bazı branch'lerde ayrı dizin)
# Bu zaten yukarıda mv ile taşındı, ekstra işlem gerekmez.

# ─── 7. Makefile, goreleaser, CI dosyaları ───────────────
echo "[7/8] Build ve CI dosyaları güncelleniyor..."

for f in \
  Makefile \
  .goreleaser.yml \
  .goreleaser.yaml \
  .github/workflows/*.yml \
  .github/workflows/*.yaml \
  Dockerfile \
  docs/*.md \
  README.md \
  CHANGELOG.md \
  contrib/nerdctl.fish \
  contrib/nerdctl.zsh \
  contrib/*.bash \
  contrib/*.sh \
  extras/rootless/containerd-rootless-setuptool.sh \
  extras/rootless/containerd-rootless.sh
do
  # glob expand etmek için eval değil, find kullan
  [ -f "$f" ] && sed -i "s/${OLD}/${NEW}/g" "$f" && echo "  güncellendi: $f"
done

# contrib/ altındaki tüm dosyalar
find ./contrib -type f 2>/dev/null | while read -r f; do
  sed -i "s/${OLD}/${NEW}/g" "$f"
done

# ─── 8. go mod tidy ──────────────────────────────────────
echo "[8/8] go mod tidy çalıştırılıyor..."
if command -v go &>/dev/null; then
  go mod tidy
  echo "  go mod tidy tamamlandı."
else
  echo "  UYARI: 'go' bulunamadı, go mod tidy manuel çalıştırılmalı."
fi

echo ""
echo "========================================"
echo "  Rename tamamlandı!"
echo "  Kontrol et: grep -r 'nerdctl' . --include='*.go' | grep -v '.git'"
echo "========================================"
