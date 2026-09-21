#!/bin/bash
set -e

# Navigate to script directory (tribalfs.github.io project root)
cd "$(dirname "$0")"

OUTPUT_FILE="app-ads.txt"
PUBLIC_OUTPUT="public/app-ads.txt"
TEMP_FILE="$(mktemp)"

# Configuration
ADMOB_PUB_ID="pub-3239920037413959"
LIFTOFF_PUB_ID="6a1b2fd986a0aae6f104b046"
MINTEGRAL_PUB_ID="70113"
UNITY_ORG_ID="126084542"

# Optional: Trigger Liftoff browser download if --fetch-liftoff or --open-liftoff passed
if [[ "$*" == *"--fetch-liftoff"* || "$*" == *"--open-liftoff"* ]]; then
    echo "Opening Liftoff download URL in browser..."
    open "https://publisher.vungle.com/vungleAdsTxt"
    echo "Waiting 3 seconds for vungle.txt to download..."
    sleep 3
fi

# Liftoff / Vungle app-ads.txt source selection:
# 1. Look for recently downloaded vungle*.txt or app-ads*.txt in ~/Downloads/
# 2. Look for local shared/liftoff-ads.txt
# 3. Fallback to hardcoded Base64 Data URI
DOWNLOADED_LIFTOFF="$(ls -t "$HOME/Downloads"/vungle*.txt "$HOME/Downloads"/app-ads*.txt 2>/dev/null | head -n 1 || true)"
if [ -f "$DOWNLOADED_LIFTOFF" ]; then
    echo "Found downloaded Liftoff app-ads file: $DOWNLOADED_LIFTOFF"
    LIFTOFF_SOURCE="$DOWNLOADED_LIFTOFF"
elif [ -f "shared/liftoff-ads.txt" ]; then
    LIFTOFF_SOURCE="shared/liftoff-ads.txt"
else
    LIFTOFF_SOURCE="${LIFTOFF_URL:-data:application/octet-stream;charset=utf-8;base64,dnVuZ2xlLmNvbSxbeW91clZ1bmdsZVB1Ymxpc2hlckFjY291bnRJRF0sRElSRUNULGMxMDdkNjg2YmVjZDJkNzcKMzNhY3Jvc3MuY29tLDAwMVBnMDAwMDE5N0tjS0lBVSxSRVNFTExFUixiYmVhMDZkOWM0ZDI4NTNjCkNvbnRleHR3ZWIuY29tLDU2Mjg1MixSRVNFTExFUiw8OWZmMTg1YTRjNGU4NTdj}"
fi

# Mintegral Documentation Markdown URL containing app-ads.txt records
MINTEGRAL_DOC_URL="https://cdn-mtg-markdown.rayjump.com/cdn-adn/v2/markdown_v2/docs/1789989465/index.md"

# Unity Ads file path selection:
if [ -n "$UNITY_URL" ]; then
    UNITY_SOURCE="$UNITY_URL"
elif [ -f "shared/unity-ads.txt" ]; then
    UNITY_SOURCE="shared/unity-ads.txt"
elif [ -f "$HOME/shared/unity-ads.txt" ]; then
    UNITY_SOURCE="$HOME/shared/unity-ads.txt"
else
    UNITY_SOURCE=""
fi

# Helper function to fetch or decode app-ads.txt entries from HTTP(S) URLs, data URIs, or files
fetch_ads_txt() {
    local source="$1"
    if [[ "$source" == data:*base64,* ]]; then
        local b64="${source#*base64,}"
        echo "$b64" | base64 --decode
    elif [[ "$source" == http://* || "$source" == https://* ]]; then
        curl -s -L "$source"
    elif [[ -f "$source" ]]; then
        cat "$source"
    else
        echo "$source"
    fi
}

mkdir -p public

echo "Updating $OUTPUT_FILE..."

{
    echo "# Merged app-ads.txt - Generated $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo ""

    # 1. Google AdMob
    echo "# Google AdMob"
    echo "google.com, $ADMOB_PUB_ID, DIRECT, f08c47fec0942fa0"
    echo ""

    # 2. Liftoff / Vungle
    echo "# Liftoff / Vungle"
    if [ -n "$LIFTOFF_SOURCE" ]; then
        fetch_ads_txt "$LIFTOFF_SOURCE" | sed \
            -e "s/\[yourVunglePublisherAccountID\]/$LIFTOFF_PUB_ID/g" \
            -e "s/<YOUR_VUNGLE_PUBLISHER_ACCOUNT_ID>/$LIFTOFF_PUB_ID/g" \
            -e "s/\[YOUR_PUBLISHER_ID\]/$LIFTOFF_PUB_ID/g"
    fi
    echo ""

    # 3. Mintegral
    echo "# Mintegral"
    fetch_ads_txt "$MINTEGRAL_DOC_URL" | \
        sed -n '/```/,/```/p' | \
        grep -v '^```' | \
        sed -e "s/your PublisherID/$MINTEGRAL_PUB_ID/g" -e "s/YOUR_PUBLISHER_ID/$MINTEGRAL_PUB_ID/g"
    echo ""

    # 4. Unity Ads
    echo "# Unity Ads"
    if [ -n "$UNITY_SOURCE" ]; then
        fetch_ads_txt "$UNITY_SOURCE" | sed \
            -e "s/\[yourUnityOrganizationID\]/$UNITY_ORG_ID/g" \
            -e "s/\[YOUR_ORG_ID\]/$UNITY_ORG_ID/g"
    else
        echo "unity.com, $UNITY_ORG_ID, DIRECT, 96cabb5fbdde37a7"
    fi
    echo ""

} > "$TEMP_FILE"

# Copy to root app-ads.txt and public/app-ads.txt
cp "$TEMP_FILE" "$OUTPUT_FILE"
cp "$TEMP_FILE" "$PUBLIC_OUTPUT"
rm -f "$TEMP_FILE"

echo "Successfully updated $OUTPUT_FILE!"

# Deploy options
if [[ "$1" == *"--github"* || "$1" == *"--push"* ]]; then
    echo "Deploying landing page & app-ads.txt to GitHub Pages..."
    git add app-ads.txt index.html shared/ boxscore/ 404.html .well-known/
    git commit -m "Update app-ads.txt & landing page [$(date -u '+%Y-%m-%d %H:%M:%S UTC')]" || true
    git push
elif [[ "$1" == *"--firebase"* ]]; then
    echo "Deploying to Firebase Hosting..."
    firebase deploy --only hosting
elif [[ "$1" != *"--no-deploy"* ]]; then
    echo "Deploying landing page & app-ads.txt to GitHub Pages..."
    git add app-ads.txt index.html shared/
    git commit -m "Update app-ads.txt & landing page [$(date -u '+%Y-%m-%d %H:%M:%S UTC')]" || true
    git push
fi
