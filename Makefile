# Makefile for GoboBSD BuildBase
# This is an improved structure to provide better build orchestration
# as suggested in the TODO list for better error checking

SHELL := /bin/sh
.SHELLFLAGS := -ec

# Environment variables
include create_env.inc

.PHONY: all create_scratch get_resources create_rootdir enter_chroot bootstrap setup_users bootstrap_finalize compile_packages create_bootdir create_cdrom clean check-env validate-env

# Default target
all: check-env create_scratch get_resources create_rootdir setup_users bootstrap bootstrap_finalize alien_integration setup_recipe_tools handle_additional_packages apply_patches organize_patches handle_zip_packages create_recipes compile_packages update_compile_conf verify_compilation installer_setup create_bootdir

# Check that environment is properly set up
check-env:
	@echo "Checking environment..."
	@if [ -z "$(DESTDIR)" ] || [ -z "$(ROOTDIR)" ] || [ -z "$(BOOTDIR)" ]; then \
		echo "Error: Environment variables not set. Please check create_env.inc"; \
		exit 1; \
	fi
	@echo "Environment variables are set correctly"

# Validate environment before building
validate-env: check-env
	@echo "Validating environment..."
	@if [ ! -f "./create_env.inc" ]; then \
		echo "Error: create_env.inc not found"; \
		exit 1; \
	fi
	@echo "Environment validation passed"

# Create scratch environment
create_scratch: validate-env
	@echo "Creating scratch environment..."
	@mkdir -p "$(DESTDIR)"
	@./create_scratch.sh
	@echo "Scratch environment created at $(DESTDIR)"

# Get required resources
get_resources: create_scratch
	@echo "Getting resources..."
	@if [ ! -d "./Sources" ]; then \
		echo "Error: Sources directory not found. Run create_scratch first."; \
		exit 1; \
	fi
	@./get_resources.sh
	@echo "Resources downloaded to ./Sources"

# Create root directory
create_rootdir: get_resources
	@echo "Creating root directory..."
	@mkdir -p "$(ROOTDIR)"
	@./create_rootdir.sh
	@echo "Root directory created at $(ROOTDIR)"

# Setup users
setup_users: create_rootdir
	@echo "Setting up users..."
	@if [ ! -d "Resources" ]; then \
		echo "Error: Resources directory not found"; \
		exit 1; \
	fi
	@cd Resources && ./01_setup_users.sh
	@echo "Users and groups set up"

# Bootstrap the system
bootstrap: setup_users
	@echo "Bootstrapping system..."
	@cd Resources && ./02_bootstrap.sh
	@echo "System bootstrapped"

# Finalize bootstrap
bootstrap_finalize: bootstrap
	@echo "Finalizing bootstrap..."
	@cd Resources && ./03_bootstrap_finalize.sh
	@echo "Bootstrap finalized"

# Compile packages
compile_packages: bootstrap_finalize
	@echo "Compiling packages inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./04_compile_packages.sh"
	@echo "Packages compiled successfully in chroot"

# Alien integration
alien_integration: compile_packages
	@echo "Setting up AlienVFS integration inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./07_alien_integration.sh"
	@echo "AlienVFS integration completed in chroot"

# Setup recipe tools for FreeBSD compatibility
setup_recipe_tools: alien_integration
	@echo "Setting up Recipe Tools, Recipe Viewer, and Review Panel for FreeBSD compatibility inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./11_setup_recipe_tools.sh"
	@echo "Recipe tools setup completed in chroot"

# Setup Lua-GoboLinux package with FreeBSD patches
setup_lua_gobolinux: setup_recipe_tools
	@echo "Setting up Lua-GoboLinux package with FreeBSD patches inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./12_setup_lua_gobolinux.sh"
	@echo "Lua-GoboLinux package setup completed in chroot"

# Prepare patches for GoboLinux Compile system
prepare_patches: setup_lua_gobolinux
	@echo "Preparing patches for GoboLinux Compile system inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./10_prepare_patches.sh"
	@echo "Patches prepared for GoboLinux Compile system in chroot"

# Organize patches for GoboLinux Compile system
organize_patches: prepare_patches
	@echo "Organizing patches for GoboLinux Compile system inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./13_organize_compile_patches.sh"
	@echo "Patches organized for GoboLinux Compile system in chroot"

# Handle ZIP packages and organize their patches
handle_zip_packages: organize_patches
	@echo "Handling ZIP packages and organizing patches inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./14_handle_zip_packages.sh"
	@echo "ZIP packages handled and patches organized in chroot"

# Handle additional GoboLinux packages for FreeBSD compatibility
handle_additional_packages: handle_zip_packages
	@echo "Handling additional GoboLinux packages for FreeBSD compatibility inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./12_handle_additional_packages.sh"
	@echo "Additional packages processed for FreeBSD compatibility in chroot"

# Apply patches to source code before compilation
apply_patches: handle_additional_packages
	@echo "Applying patches to source code inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./09_apply_patches.sh"
	@echo "Patches applied to source code in chroot"

# Create recipes for GoboLinux Compile system
create_recipes: apply_patches
	@echo "Creating recipes for GoboLinux Compile system inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./11_create_recipes.sh"
	@echo "Recipes created for GoboLinux Compile system in chroot"

# Compile packages
compile_packages: create_recipes
	@echo "Compiling packages inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./04_compile_packages.sh"
	@echo "Packages compiled successfully in chroot"

# Update Compile configuration to use GoboBSD Recipes repository
update_compile_conf: compile_packages
	@echo "Updating Compile.conf to use GoboBSD Recipes repository inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./16_update_compile_conf.sh"
	@echo "Compile.conf updated to use GoboBSD Recipes repository in chroot"

# Verify package compilation and patch application
verify_compilation: update_compile_conf
	@echo "Verifying package compilation and patch application inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./15_verify_compilation.sh"
	@echo "Package compilation and patch application verified in chroot"

# Installer setup
installer_setup: verify_compilation
	@echo "Setting up GoboLinux Installer with FreeBSD patches inside chroot..."
	@./enter_chroot.sh "/bin/sh" "-c" "cd /Users/root/bootstrap && ./08_installer_setup.sh"
	@echo "GoboLinux Installer setup completed in chroot"

# Create boot directory
create_bootdir: installer_setup
	@echo "Creating boot directory..."
	@mkdir -p "$(BOOTDIR)"
	@./create_bootdir.sh
	@echo "Boot directory created at $(BOOTDIR)"

# Create CDROM image
create_cdrom: create_bootdir
	@echo "Creating CDROM image..."
	@if [ ! -f "./goboBSD.iso" ]; then \
		./create_cdrom.sh goboBSD.iso; \
		echo "CDROM image created: goboBSD.iso"; \
	else \
		echo "CDROM image goboBSD.iso already exists. Remove it first if you want to recreate it."; \
	fi

# Enter chroot (interactive step)
enter_chroot: create_rootdir
	@echo "Entering chroot environment..."
	@./enter_chroot.sh

# Build only the system (without creating CDROM)
build-system: all

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@./remove_rootdir.sh 2>/dev/null || true
	@rm -rf "$(DESTDIR)" 2>/dev/null || true
	@rm -rf "$(ROOTDIR)" 2>/dev/null || true
	@rm -rf "$(BOOTDIR)" 2>/dev/null || true
	@rm -f goboBSD.iso 2>/dev/null || true
	@echo "Build artifacts cleaned"

# Clean everything including sources
clean-all: clean
	@echo "Cleaning sources..."
	@rm -rf ./Sources 2>/dev/null || true
	@echo "All build artifacts and sources cleaned"

# Force rebuild of specific components
force-create-scratch:
	@echo "Force creating scratch environment..."
	@./remove_rootdir.sh 2>/dev/null || true
	@rm -rf "$(DESTDIR)" 2>/dev/null || true
	@mkdir -p "$(DESTDIR)"
	@./create_scratch.sh

force-get-resources:
	@echo "Force getting resources..."
	@rm -rf ./Sources 2>/dev/null || true
	@mkdir -p ./Sources
	@./get_resources.sh

# Help target
help:
	@echo "GoboBSD BuildBase Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Build complete system (default)"
	@echo "  build-system     - Build system without creating CDROM"
	@echo "  create_scratch   - Create scratch environment"
	@echo "  get_resources    - Download required resources"
	@echo "  create_rootdir   - Create root directory structure"
	@echo "  setup_users      - Setup users and groups"
	@echo "  bootstrap        - Bootstrap the system"
	@echo "  bootstrap_finalize - Finalize bootstrap"
	@echo "  compile_packages - Compile packages using GoboLinux Compile"
	@echo "  create_bootdir   - Create boot directory"
	@echo "  create_cdrom     - Create CDROM image"
	@echo "  enter_chroot     - Enter chroot environment (interactive)"
	@echo "  clean            - Clean build artifacts"
	@echo "  clean-all        - Clean build artifacts and sources"
	@echo "  force-create-scratch - Force recreate scratch environment"
	@echo "  force-get-resources - Force redownload resources"
	@echo "  check-env        - Check environment variables"
	@echo "  validate-env     - Validate environment setup"
	@echo "  help             - Show this help"
	@echo ""
	@echo "Environment variables (from create_env.inc):"
	@echo "  DESTDIR=$(DESTDIR)"
	@echo "  ROOTDIR=$(ROOTDIR)"
	@echo "  BOOTDIR=$(BOOTDIR)"