#!/bin/bash

# ============================================================
# Contact Fixer - Production Security Key Generator
# ============================================================
# Generates secure keys for production deployment
# Usage: ./scripts/generate_prod_keys.sh
# ============================================================

set -e  # Exit on error

echo "=================================================="
echo "  Contact Fixer - Security Key Generator"
echo "=================================================="
echo ""
echo "Generating production security keys..."
echo ""

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    exit 1
fi

# Generate JWT Secret Key
echo "📝 Generating JWT_SECRET_KEY..."
JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

# Generate Fernet Encryption Key
echo "🔐 Generating ENCRYPTION_KEY..."
ENCRYPTION_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")

# Display keys
echo ""
echo "=================================================="
echo "  ✅ Keys Generated Successfully!"
echo "=================================================="
echo ""
echo "Copy these values to your production .env file:"
echo ""
echo "---------------------------------------------------"
echo "JWT_SECRET_KEY=$JWT_SECRET"
echo "ENCRYPTION_KEY=$ENCRYPTION_KEY"
echo "---------------------------------------------------"
echo ""

# Optional: Save to file
read -p "Save to keys.txt? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat > keys.txt << EOF
# Generated on: $(date)
# DO NOT COMMIT THIS FILE!

JWT_SECRET_KEY=$JWT_SECRET
ENCRYPTION_KEY=$ENCRYPTION_KEY
EOF
    
    # Secure the file
    chmod 600 keys.txt
    
    echo "✅ Keys saved to keys.txt (file secured with chmod 600)"
    echo "⚠️  Remember to delete this file after copying to .env"
fi

echo ""
echo "=================================================="
echo "  📋 Next Steps:"
echo "=================================================="
echo ""
echo "1. Copy the keys above to your .env file"
echo "2. Verify ENVIRONMENT=production in .env"
echo "3. Set file permissions: chmod 600 .env"
echo "4.  Never commit .env to version control"
echo ""
echo "For more info, see: docs/PRODUCTION_DEPLOYMENT.md"
echo ""
