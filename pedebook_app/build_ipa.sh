#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================="
echo "  🚀 Starting Pedebook iOS IPA Build Process"
echo "================================================="

cd "$PROJECT_DIR"

echo "📦 Running Flutter Build IPA (Release)..."
flutter build ipa --release --export-options-plist ios/ExportOptions.plist

IPA_FILE=$(find "$PROJECT_DIR/build/ios/ipa" -maxdepth 1 -name "*.ipa" | head -n 1)
if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
    echo "================================================="
    echo "  🎉 SUCCESS! IPA file created successfully:"
    echo "  📍 $IPA_FILE"
    echo "================================================="
else
    echo "❌ Build finished but IPA file not found in $PROJECT_DIR/build/ios/ipa"
    exit 1
fi
