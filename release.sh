#!/usr/bin/env bash
# release.sh — Cria tag de release e faz push para disparar o workflow de build
# Funciona em bash (Linux/macOS) e git-bash (Windows)

set -euo pipefail

REPO="shigake/Zion"

# Determinar versao: argumento ou game/VERSION
if [ -n "${1:-}" ]; then
  VERSION="$1"
else
  VERSION_FILE="$(dirname "$0")/game/VERSION"
  if [ ! -f "$VERSION_FILE" ]; then
    echo "Erro: game/VERSION nao encontrado e nenhuma versao fornecida como argumento."
    echo "Uso: ./release.sh [VERSAO]"
    exit 1
  fi
  VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
fi

TAG="v${VERSION}"

echo "=== Zion Release ==="
echo "Versao: ${VERSION}"
echo "Tag:    ${TAG}"
echo ""

# Validar que a tag nao existe localmente
if git tag -l "$TAG" | grep -q "$TAG"; then
  echo "Erro: Tag ${TAG} ja existe localmente."
  echo "Se quiser recriar, remova com: git tag -d ${TAG}"
  exit 1
fi

# Validar que a tag nao existe no remote
if git ls-remote --tags origin "refs/tags/${TAG}" | grep -q "$TAG"; then
  echo "Erro: Tag ${TAG} ja existe no remote."
  echo "Se quiser recriar, remova com: git push origin :refs/tags/${TAG}"
  exit 1
fi

# Verificar se ha mudancas nao commitadas
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo "Aviso: Existem mudancas nao commitadas. Commite antes de criar a release."
  exit 1
fi

# Criar tag e fazer push
echo "Criando tag ${TAG}..."
git tag -a "$TAG" -m "Release ${TAG}"

echo "Fazendo push da tag ${TAG}..."
git push origin "$TAG"

echo ""
echo "Tag ${TAG} criada e enviada com sucesso!"
echo ""
echo "O workflow de build sera disparado automaticamente."
echo "Acompanhe em: https://github.com/${REPO}/actions"
echo ""
echo "Quando pronto, a release estara em:"
echo "  https://github.com/${REPO}/releases/tag/${TAG}"
echo ""
echo "Link direto para a ultima release:"
echo "  https://github.com/${REPO}/releases/latest"
