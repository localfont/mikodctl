#!/usr/bin/env bash
# ============================================================
# fix_multimodule.sh
# rename_to_mikodctl.sh sonrasında kalan
# "github.com/localfont/mikodctl" referanslarını temizler.
#
# Sorun: nerdctl v2 multi-module yapısı kullanıyor:
#   - github.com/containerd/nerdctl/v2/...   → go.mod'da ayrı module
#   - github.com/containerd/nerdctl/mod/tigron/...  → ayrı module
# Script bunları localfont/mikodctl altına taşır.
#
# Kullanım: repo kökünde çalıştır
#   bash fix_multimodule.sh
# ============================================================
set -euo pipefail

OLD_ORG="github.com/localfont/mikodctl"   # yanlış kalan
NEW_ORG="github.com/localfont/mikodctl"    # doğru hedef

echo "================================================"
echo "  Multi-module import fix başlıyor"
echo "  ${OLD_ORG} → ${NEW_ORG}"
echo "================================================"

# ─── Adım 1: Tüm .go dosyalarında kalan yanlış import'lar ──
echo ""
echo "[1/5] .go dosyaları taranıyor..."

AFFECTED=$(grep -rl "${OLD_ORG}" . \
  --include="*.go" \
  --exclude-dir=".git" \
  2>/dev/null || true)

if [ -z "$AFFECTED" ]; then
  echo "  .go dosyasında sorun yok."
else
  echo "$AFFECTED" | while read -r f; do
    sed -i "s|${OLD_ORG}|${NEW_ORG}|g" "$f"
    echo "  düzeltildi: $f"
  done
fi

# ─── Adım 2: go.mod dosyaları (root + alt modüller) ────────
echo ""
echo "[2/5] go.mod dosyaları güncelleniyor..."

find . -name "go.mod" ! -path "./.git/*" | while read -r f; do
  if grep -q "${OLD_ORG}" "$f"; then
    sed -i "s|${OLD_ORG}|${NEW_ORG}|g" "$f"
    echo "  düzeltildi: $f"
  fi
done

# ─── Adım 3: go.sum dosyaları ──────────────────────────────
echo ""
echo "[3/5] go.sum dosyaları güncelleniyor..."

find . -name "go.sum" ! -path "./.git/*" | while read -r f; do
  if grep -q "${OLD_ORG}" "$f"; then
    sed -i "s|${OLD_ORG}|${NEW_ORG}|g" "$f"
    echo "  düzeltildi: $f"
  fi
done

# ─── Adım 4: Diğer config/yaml/toml dosyaları ─────────────
echo ""
echo "[4/5] Diğer dosyalar (yaml/toml/json/sh) güncelleniyor..."

find . \( \
    -name "*.yaml" -o -name "*.yml" \
    -o -name "*.toml" -o -name "*.json" \
    -o -name "*.sh" -o -name "*.md" \
  \) \
  ! -path "./.git/*" \
  | while read -r f; do
    if grep -q "${OLD_ORG}" "$f"; then
      sed -i "s|${OLD_ORG}|${NEW_ORG}|g" "$f"
      echo "  düzeltildi: $f"
    fi
  done

# ─── Adım 5: go mod tidy (tüm go.mod'lar için) ─────────────
echo ""
echo "[5/5] go mod tidy çalıştırılıyor..."

if command -v go &>/dev/null; then
  # Root go.mod
  go mod tidy && echo "  root: go mod tidy OK"

  # Alt modüller (v2/, mod/tigron/ vs.)
  find . -name "go.mod" \
    ! -path "./go.mod" \
    ! -path "./.git/*" \
    | while read -r modfile; do
      dir=$(dirname "$modfile")
      echo "  alt modül: $dir"
      (cd "$dir" && go mod tidy) && echo "    → OK"
    done
else
  echo "  UYARI: 'go' bulunamadı — go mod tidy manuel çalıştırılmalı."
fi

# ─── Kontrol raporu ────────────────────────────────────────
echo ""
echo "================================================"
echo "  Kontrol: kalan yanlış referanslar"
echo "================================================"

REMAINING=$(grep -r "${OLD_ORG}" . \
  --include="*.go" \
  --include="*.mod" \
  ! -path "./.git/*" \
  2>/dev/null || true)

if [ -z "$REMAINING" ]; then
  echo "  ✓ Temiz! Hiç '${OLD_ORG}' kalmadı."
else
  echo "  ✗ Hâlâ kalan referanslar:"
  echo "$REMAINING"
fi

echo ""
echo "  Sonraki adım: go build ./cmd/mikodctl/..."
