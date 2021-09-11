#!/bin/bash
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
cd SCRIPT_DIR
ssh citadel citadel:glyph_deploy
