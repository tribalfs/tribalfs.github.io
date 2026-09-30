#!/bin/bash
set -e

# Navigate to script directory (tribalfs.github.io project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OUTPUT_FILE="app-ads.txt"
PUBLIC_OUTPUT="public/app-ads.txt"
TEMP_FILE="$(mktemp)"

# Configuration
ADMOB_PUB_ID="pub-3239920037413959"
LIFTOFF_PUB_ID="6a1b2fd986a0aae6f104b046"
MINTEGRAL_PUB_ID="70113"
UNITY_ORG_ID="126084542"

# Liftoff / Vungle app-ads.txt source selection:
# Direct REST API endpoint hosted by Liftoff / Vungle
LIFTOFF_API_URL="https://pub-ctrl-api.vungle.com/api/v1/adstxt/vungle"
SHARED_LIFTOFF="${SCRIPT_DIR}/shared/liftoff-ads.txt"

# Search for any manually downloaded Liftoff vendor file across common machine download locations:
DOWNLOADED_LIFTOFF=""
if [ -n "$LIFTOFF_FILE" ] && [ -f "$LIFTOFF_FILE" ]; then
    DOWNLOADED_LIFTOFF="$LIFTOFF_FILE"
else
    DOWNLOADED_LIFTOFF="$(ls -t \
        "$HOME/Downloads"/vungle*.txt "$HOME/Downloads"/vungleAdsTxt*.txt "$HOME/Downloads"/app-ads*.txt \
        "$HOME/Desktop"/vungle*.txt "$HOME/Desktop"/vungleAdsTxt*.txt \
        /tmp/vungle*.txt 2>/dev/null | head -n 1 || true)"
fi

if [ -f "$DOWNLOADED_LIFTOFF" ]; then
    if [ ! -f "$SHARED_LIFTOFF" ] || [ "$DOWNLOADED_LIFTOFF" -nt "$SHARED_LIFTOFF" ]; then
        echo "Updating shared/liftoff-ads.txt from downloaded file: $DOWNLOADED_LIFTOFF"
        mkdir -p "${SCRIPT_DIR}/shared"
        cp "$DOWNLOADED_LIFTOFF" "$SHARED_LIFTOFF"
    fi
fi

LIFTOFF_SOURCE="${LIFTOFF_URL:-$LIFTOFF_API_URL}"

# Mintegral Documentation Markdown URL containing app-ads.txt records
MINTEGRAL_DOC_URL="https://cdn-mtg-markdown.rayjump.com/cdn-adn/v2/markdown_v2/docs/1789989465/index.md"

# Unity Ads file path selection:
SHARED_UNITY="${SCRIPT_DIR}/shared/unity-ads.txt"
if [ -n "$UNITY_URL" ]; then
    UNITY_SOURCE="$UNITY_URL"
elif [ -f "$SHARED_UNITY" ]; then
    UNITY_SOURCE="$SHARED_UNITY"
elif [ -f "$HOME/shared/unity-ads.txt" ]; then
    UNITY_SOURCE="$HOME/shared/unity-ads.txt"
else
    UNITY_SOURCE=""
fi

# Helper function to fetch or decode app-ads.txt entries from HTTP(S) URLs, data URIs, or files
fetch_ads_txt() {
    local source="$1"
    if [[ "$source" == "https://pub-ctrl-api.vungle.com/"* ]]; then
        local content
        content="$(curl -s -L "$source" | python3 -c "import sys, json; print(json.load(sys.stdin).get('value', ''))" 2>/dev/null || true)"
        if [ -n "$content" ]; then
            echo "$content"
        elif [ -f "$SHARED_LIFTOFF" ]; then
            cat "$SHARED_LIFTOFF"
        fi
    elif [[ "$source" == data:*base64,* ]]; then
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
