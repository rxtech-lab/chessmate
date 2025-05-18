# Create variable name for the app name
APP_NAME="./output/output.xcarchive/Products/Applications/chessmate.app"
DMG_NAME="ChessMate.dmg"

# Exit on any error
set -e


# Remove existing DMG if it exists
if [ -f "$DMG_NAME" ]; then
  echo "Removing existing DMG file"
  rm "$DMG_NAME"
fi

# create dmg
create-dmg --overwrite "$APP_NAME" && mv *.dmg "$DMG_NAME"

echo "DMG created: $DMG_NAME"

# notarize the app
xcrun notarytool submit ./$DMG_NAME --verbose --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_ID_PWD" --wait

# staple the ticket
xcrun stapler staple $DMG_NAME

echo "All operations completed successfully!"
