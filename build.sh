#!/bin/bash
set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cd /Users/yogi/Docker/appl.pdf-compressor
MON_IMAGE="jaihemme/appl.pdf-compressor"

# Vérifier qu'on est sur un tag
if ! git describe --tags --exact-match HEAD &>/dev/null; then
    echo -e "${RED}Warning: HEAD is not on a tag${NC}"
    echo "Current commit: $(git rev-parse --short HEAD)"
fi

# Récupérer les infos
GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
VERSION=${GIT_TAG#v}
GIT_COMMIT=$(git rev-parse --short HEAD)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

echo -e "${GREEN}Building Docker image${NC}"
echo "Version: ${VERSION}"
echo "Commit:  ${GIT_COMMIT}"
echo "Date:    ${BUILD_DATE}"
read -p "OK?"

# Sans --platform (build pour votre machine seulement)
#docker build -t app:latest .
# Sur Mac M1 → linux/arm64 uniquement
# Sur Mac Intel → linux/amd64 uniquement

# Avec --platform (build pour plusieurs architectures)
#docker build --platform linux/amd64,linux/arm64 -t app:latest .
# → 2 images créées (arm64 + amd64)
# → Docker choisit automatiquement la bonne selon le système

# Builder avec métadonnées complètes
docker build \
  --build-arg GIT_VERSION="${GIT_TAG}" \
  --build-arg GIT_COMMIT="${GIT_COMMIT}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  -t ${MON_IMAGE}:${GIT_TAG} \
  -t ${MON_IMAGE}:latest \
  .

echo -e "${GREEN}✓ Build successful${NC}"
echo "Images created:"
docker images ${MON_IMAGE} --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

###
