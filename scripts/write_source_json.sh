#!/usr/bin/env bash
# Genera el AltSource de LiveContainer (docs/source.json) a partir de una build.
# Lo usan tanto el job de build como el despliegue de solo-docs, para que el
# feed nunca se publique con datos viejos.
#
# Uso:
#   VERSION=1.58 BUILD=58 SIZE=2674465 DATE=2026-11-05 \
#     bash scripts/write_source_json.sh docs/source.json
set -euo pipefail

output="${1:-docs/source.json}"

: "${APP_NAME:?APP_NAME no está definido}"
: "${BUNDLE_ID:?BUNDLE_ID no está definido}"
: "${PAGES_URL:?PAGES_URL no está definido}"
: "${REPO:?REPO no está definido}"
: "${MIN_OS:?MIN_OS no está definido}"
: "${VERSION:?VERSION no está definido}"
: "${BUILD:?BUILD no está definido}"
: "${SIZE:?SIZE no está definido}"
: "${DATE:?DATE no está definido}"

mkdir -p "$(dirname "$output")"

RELEASE_URL="https://github.com/$REPO/releases/download/build-$BUILD/SafePlace.ipa"

cat > "$output" <<EOF
{
  "name": "$APP_NAME",
  "identifier": "$BUNDLE_ID.source",
  "sourceURL": "$PAGES_URL/source.json",
  "subtitle": "Builds personales de $APP_NAME",
  "description": "Builds automáticos de $APP_NAME para LiveContainer.",
  "iconURL": "$PAGES_URL/icon.png",
  "apps": [
    {
      "name": "$APP_NAME",
      "bundleIdentifier": "$BUNDLE_ID",
      "developerName": "Hihirams",
      "subtitle": "Guarda las pequeñas cosas que te ayudan",
      "localizedDescription": "App de iPhone para guardar hábitos, personas, lugares, música y autocuidado.",
      "iconURL": "$PAGES_URL/icon.png",
      "tintColor": "F5B07B",
      "category": "lifestyle",
      "versions": [
        {
          "version": "$VERSION",
          "buildVersion": "$BUILD",
          "date": "$DATE",
          "localizedDescription": "Build $BUILD ($DATE)",
          "downloadURL": "$RELEASE_URL",
          "size": $SIZE,
          "minOSVersion": "$MIN_OS"
        }
      ]
    }
  ]
}
EOF

echo "AltSource escrito en $output (versión $VERSION, build $BUILD, $SIZE bytes)."
