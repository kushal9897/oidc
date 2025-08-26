#!/bin/bash

echo "Starting ngrok to expose Vault..."

# Start ngrok in background
ngrok http 8200 > /dev/null &
NGROK_PID=$!

# Wait for ngrok to start
sleep 3

# Get ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')

if [ -z "$NGROK_URL" ]; then
    echo "❌ Failed to get ngrok URL"
    exit 1
fi

echo "✅ Vault is accessible at: $NGROK_URL"
echo ""
echo "📝 Add this as a GitHub secret:"
echo "   Name: VAULT_ADDR"
echo "   Value: $NGROK_URL"
echo ""
echo "Run: gh secret set VAULT_ADDR --body \"$NGROK_URL\""
echo ""
echo "Ngrok PID: $NGROK_PID" > ngrok.pid