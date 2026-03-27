#!/bin/bash
# Setup Capacitor for iOS build
# Run this script to initialize Capacitor and create iOS project

echo "📱 Setting up Capacitor for iOS..."
echo "=================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js is not installed"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  Warning: iOS builds require macOS and Xcode"
    echo "Current OS: $OSTYPE"
    read -p "Continue setup anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Initialize npm project if package.json doesn't exist
if [ ! -f "package.json" ]; then
    echo "📦 Initializing npm project..."
    npm init -y
fi

# Install Capacitor
echo "📥 Installing Capacitor..."
npm install @capacitor/core @capacitor/cli
npm install @capacitor/ios

# Initialize Capacitor
echo "🔧 Initializing Capacitor..."
npx cap init "Work Log" "com.worklog.app" --web-dir=www

# Create www directory and placeholder
mkdir -p www
cat > www/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Work Log</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        h1 { margin-bottom: 1rem; }
        .info {
            background: rgba(255,255,255,0.1);
            padding: 1rem;
            border-radius: 10px;
            margin-top: 1rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Work Log App</h1>
        <p>Capacitor iOS Setup Complete!</p>
        <div class="info">
            <p>Next steps:</p>
            <ol style="text-align: left; display: inline-block;">
                <li>Deploy Flask backend to cloud server</li>
                <li>Update capacitor.config.json with server URL</li>
                <li>Run: npx cap add ios</li>
                <li>Run: npx cap open ios</li>
                <li>Build in Xcode</li>
            </ol>
        </div>
    </div>
    <script src="capacitor.js"></script>
</body>
</html>
EOF

# Create Capacitor config
echo "📝 Creating Capacitor configuration..."
cat > capacitor.config.json << 'EOF'
{
  "appId": "com.worklog.app",
  "appName": "Work Log",
  "webDir": "www",
  "bundledWebRuntime": false,
  "server": {
    "url": "http://localhost:5000",
    "cleartext": true
  },
  "ios": {
    "contentInset": "always",
    "scheme": "App"
  }
}
EOF

echo "⚠️  IMPORTANT: Update 'server.url' in capacitor.config.json"
echo "   Change from 'http://localhost:5000' to your cloud server URL"
echo ""

# Add iOS platform
echo "📱 Adding iOS platform..."
npx cap add ios

echo ""
echo "✅ Capacitor setup complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Deploy your Flask app to a cloud server (Railway, Heroku, etc.)"
echo "2. Update capacitor.config.json with your server URL"
echo "3. Open the iOS project: npx cap open ios"
echo "4. In Xcode: Select your team, build, and run"
echo ""
echo "For detailed instructions, see BUILD_IOS.md"
