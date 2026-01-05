#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/16_update_compile_conf.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Updating Compile.conf to use GoboBSD Recipes repository..."

# Create the Compile settings directory if it doesn't exist
mkdir -p "$ROOT/System/Settings/Compile"

# Create or update the Compile.conf file to point to the GoboBSD Recipes repository
COMPILE_CONF="$ROOT/System/Settings/Compile/Compile.conf"

# Check if the file exists, if not create it with default values
if [ ! -f "$COMPILE_CONF" ]; then
    echo "Creating Compile.conf with default settings..."
    cat > "$COMPILE_CONF" << 'EOF'
# GoboLinux Compile Configuration File
# For GoboBSD - Updated to use GoboBSD-specific recipe repository

# Recipe repository settings
compileRecipesRepository=https://github.com/xaturingAI/GoboBsdRecipes.git

# Author information for recipe submissions
compileRecipeAuthor="XaturingAI <xaturingai@example.com>"

# Recipe submission settings
compileSubmitToUpstream=false
compileSubmitToCustom=true

# Custom recipe directory
compileCustomRecipesDir=/System/Settings/Compile/CustomRecipes

# Recipe cache settings
compileRecipeCacheTimeout=86400

# System identification for recipes
compileSystemIdentifier=gobobsd

EOF
else
    echo "Updating existing Compile.conf..."

    # Backup the original file
    cp "$COMPILE_CONF" "$COMPILE_CONF.backup"

    # Update the recipe repository URL in the existing file
    if grep -q "compileRecipesRepository=" "$COMPILE_CONF"; then
        # Update existing repository URL
        sed -i.bak 's|compileRecipesRepository=.*github.com/gobolinux/Recipes.git|compileRecipesRepository=https://github.com/xaturingAI/GoboBsdRecipes.git|' "$COMPILE_CONF"
    else
        # Add the repository setting if it doesn't exist
        echo "" >> "$COMPILE_CONF"
        echo "# GoboBSD-specific recipe repository" >> "$COMPILE_CONF"
        echo "compileRecipesRepository=https://github.com/xaturingAI/GoboBsdRecipes.git" >> "$COMPILE_CONF"
    fi

    # Update the recipe author information
    if grep -q "compileRecipeAuthor=" "$COMPILE_CONF"; then
        # Update existing author information
        sed -i.bak 's|compileRecipeAuthor=.*|compileRecipeAuthor="XaturingAI <xaturingai@example.com>"|' "$COMPILE_CONF"
    else
        # Add the author setting if it doesn't exist
        echo "# Recipe author for GoboBSD" >> "$COMPILE_CONF"
        echo 'compileRecipeAuthor="XaturingAI <xaturingai@example.com>"' >> "$COMPILE_CONF"
    fi

    # Ensure other GoboBSD-specific settings are present
    if ! grep -q "compileSystemIdentifier=" "$COMPILE_CONF"; then
        echo "# System identification for GoboBSD" >> "$COMPILE_CONF"
        echo "compileSystemIdentifier=gobobsd" >> "$COMPILE_CONF"
    else
        sed -i.bak 's|^compileSystemIdentifier=.*|compileSystemIdentifier=gobobsd|' "$COMPILE_CONF"
    fi

    # Ensure recipe submission settings are appropriate for GoboBSD
    if ! grep -q "compileSubmitToCustom=" "$COMPILE_CONF"; then
        echo "# Recipe submission settings for GoboBSD" >> "$COMPILE_CONF"
        echo "compileSubmitToUpstream=false" >> "$COMPILE_CONF"
        echo "compileSubmitToCustom=true" >> "$COMPILE_CONF"
    else
        sed -i.bak 's|^compileSubmitToUpstream=.*|compileSubmitToUpstream=false|' "$COMPILE_CONF"
        sed -i.bak 's|^compileSubmitToCustom=.*|compileSubmitToCustom=true|' "$COMPILE_CONF"
    fi
fi

# Also update the global Scripts configuration if it exists
GLOBAL_CONF="$ROOT/System/Settings/Scripts.conf"
if [ -f "$GLOBAL_CONF" ]; then
    echo "Updating global Scripts configuration..."
    # Backup the original file
    cp "$GLOBAL_CONF" "$GLOBAL_CONF.backup"
    
    # Add or update recipe repository settings in the global config
    if ! grep -q "compileRecipesRepository\|gobobsd" "$GLOBAL_CONF"; then
        echo "" >> "$GLOBAL_CONF"
        echo "# GoboBSD-specific settings" >> "$GLOBAL_CONF"
        echo "compileRecipesRepository=https://github.com/xaturingAI/GoboBsdRecipes.git" >> "$GLOBAL_CONF"
        echo "compileSystemIdentifier=gobobsd" >> "$GLOBAL_CONF"
    fi
fi

# Create the CustomRecipes directory for GoboBSD-specific recipes
mkdir -p "$ROOT/System/Settings/Compile/CustomRecipes"

echo "Compile.conf updated to use GoboBSD Recipes repository:"
echo "  https://github.com/xaturingAI/GoboBsdRecipes.git"
echo ""
echo "The Compile system will now use GoboBSD-specific recipes instead of GoboLinux recipes."
echo "This ensures separation between GoboLinux and GoboBSD recipe collections."