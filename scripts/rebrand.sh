#!/bin/bash

echo "🔧 Rebranding: nerdctl → mikodctl"

# Binary adı
sed -i 's/nerdctl/mikodctl/g' Makefile 2>/dev/null || true

# Go modül
sed -i 's|github.com/containerd/nerdctl|github.com/localfont/mikodctl|g' go.mod

# Go kaynak kodları
find . -name "*.go" -type f -exec sed -i 's|github.com/containerd/nerdctl|github.com/localfont/mikodctl|g' {} \;
find . -name "*.go" -type f -exec sed -i 's/"nerdctl"/"mikodctl"/g' {} \;

# Dokümantasyon
find . -name "*.md" -type f -exec sed -i 's/nerdctl/mikodctl/g' {} \;
find . -name "*.md" -type f -exec sed -i 's/Nerdctl/Mikodctl/g' {} \;

echo "✅ Tamamlandı!"
