# Path of Building — developer entry points.
# macOS app targets require a sibling clone of PathOfBuilding-SimpleGraphic
# (branch feat/macos-build); override SG_DIR if yours lives elsewhere.

SG_DIR ?= $(HOME)/dev/thirdparty/PathOfBuilding-SimpleGraphic
SG_DIST := $(SG_DIR)/build/dist
BUILD_DIR := build/macos
APP_NAME := Path of Building.app
TEST_IMAGE := ghcr.io/pathofbuildingcommunity/pathofbuilding-tests:latest

.PHONY: test test-python manifest macos-runtime macos-app run-macos clean-macos

test:
	docker run --rm --platform linux/amd64 -e HOME=/tmp -v "$(CURDIR)":/workdir:ro -w /workdir $(TEST_IMAGE) busted --lua=luajit

test-python:
	python3 -m pytest tests/ -v

manifest:
	python3 update_manifest.py --in-place

$(SG_DIR)/CMakeLists.txt:
	@echo "error: SimpleGraphic clone not found at $(SG_DIR)"; \
	echo "  git clone https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic.git $(SG_DIR)"; \
	echo "  (then check out branch feat/macos-build and init submodules)"; \
	exit 1

macos-runtime: $(SG_DIR)/CMakeLists.txt
	cmake -B "$(SG_DIR)/build" -S "$(SG_DIR)" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 -DVCPKG_TARGET_TRIPLET=arm64-osx
	cmake --build "$(SG_DIR)/build"
	cmake --install "$(SG_DIR)/build" --prefix "$(SG_DIST)"

macos-app: macos-runtime
	SG_DIST="$(SG_DIST)" BUILD_DIR="$(BUILD_DIR)" POB_ROOT="$(CURDIR)" bash scripts/build-macos-app.sh

run-macos: macos-app
	open "$(BUILD_DIR)/$(APP_NAME)"

clean-macos:
	rm -rf "$(BUILD_DIR)"
