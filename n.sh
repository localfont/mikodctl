#!/usr/bin/env bash
# ============================================================
# fix_gomod_declarations.sh
# Alt modüllerin go.mod içindeki "module" satırlarını düzeltir.
# Sorun: go.mod'un module satırı hâlâ eski path'i söylüyor.
# ============================================================
set -euo pipefail

OLD="github.com/containerd/nerdctl"
NEW="github.com/localfont/mikodctl"

echo "================================================"
echo "  go.mod module declaration fix"
echo "================================================"

# Repodaki tüm go.mod dosyalarını bul
find . -name "go.mod" ! -path "./.git/*" | sort | while read -r modfile; do
  # "module" satırını kontrol et
  MODULE_LINE=$(grep "^module " "$modfile" || true)
  
  if echo "$MODULE_LINE" | grep -q "${OLD}"; then
    echo ""
    echo "  Düzeltiliyor: $modfile"
    echo "  Önce: $MODULE_LINE"
    
    # module satırını güncelle
    sed -i "s|^module ${OLD}|module ${NEW}|g" "$modfile"
    
    NEW_LINE=$(grep "^module " "$modfile")
    echo "  Sonra: $NEW_LINE"
    
    # Aynı dosyadaki require/replace bloklarını da güncelle
    sed -i "s|${OLD}|${NEW}|g" "$modfile"
    echo "  require/replace blokları da güncellendi."
  else
    echo "  OK (dokunulmadı): $modfile  →  $MODULE_LINE"
  fi
done

echo ""
echo "================================================"
echo "  Tüm .go dosyalarında kalan eski referanslar"
echo "================================================"
grep -r "${OLD}" . --include="*.go" --include="*.mod" \
  ! -path "./.git/*" 2>/dev/null \
  && echo "  ✗ Yukarıdakiler hâlâ eski path kullanıyor!" \
  || echo "  ✓ Temiz — eski path kalmadı."

echo ""
echo "================================================"
echo "  go mod tidy (her alt modül için)"
echo "================================================"

find . -name "go.mod" ! -path "./.git/*" | sort | while read -r modfile; do
  dir=$(dirname "$modfile")
  echo "  → $dir"
  (cd "$dir" && go mod tidy 2>&1) && echo "    OK" || echo "    HATA — manuel kontrol et"
done

echo ""
echo "Bitti. Şimdi dene: go build ./cmd/mikodctl/..."
