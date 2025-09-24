#!/bin/bash
set -e

require_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo "[ABORT] $2 is not installed or not in PATH" >&2
        exit 1
    fi
    echo "[INFO] $2 found."
}

main() {
    local ZIPFILE="v8_12.9.202.28_v1.0.zip"
    local V8_URL="https://github.com/xls/V8-libraries/releases/download/v8_12.9.202.28_v1.0/v8_12.9.202.28_v1.0.zip"

    require_cmd git "Git"
    require_cmd scons "scons"
    require_cmd curl "curl"
    require_cmd tar "tar"

    local GROOT=""
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [[ -f "$SCRIPT_DIR/SConstruct" ]]; then
        GROOT="$SCRIPT_DIR/"
    elif [[ -f "SConstruct" && -d "modules" ]]; then
        GROOT="$(pwd)/"
    elif [[ -f "godot/SConstruct" ]]; then
        GROOT="$(pwd)/godot/"
    elif [[ -d "godot" ]]; then
        GROOT="$(pwd)/godot/"
    else
        if [[ -d "godot" ]]; then
            echo "[INFO] godot repo already present, skipping clone."
        else
            git clone -b 4.6-dev --recursive https://github.com/xls/godot || {
                echo "[ABORT] git clone godot" >&2
                exit 1
            }
        fi
        GROOT="$(pwd)/godot/"
    fi

    # Normalize path
    GROOT="$(cd "$GROOT" && pwd)/"
    echo "[INFO] Repo root: $GROOT"

    if [[ ! -d "$GROOT/modules" ]]; then
        mkdir -p "$GROOT/modules" || {
            echo "[ABORT] mkdir modules" >&2
            exit 1
        }
    fi

    pushd "$GROOT/modules" || {
        echo "[ABORT] cd modules" >&2
        exit 1
    }

    if [[ -d "GodotJS" ]]; then
        echo "[INFO] GodotJS repo already present, skipping clone."
    else
        git clone -b 4.5-dev --recursive https://github.com/xls/GodotJS || {
            echo "[ABORT] git clone GodotJS" >&2
            exit 1
        }
    fi

    pushd "GodotJS" || {
        echo "[ABORT] cd GodotJS" >&2
        exit 1
    }

    if [[ -d "v8" ]]; then
        echo "[INFO] v8 folder already present, skipping V8 download/extract."
    else
        curl -L -o "$ZIPFILE" "$V8_URL" || {
            echo "[ABORT] Downloading $ZIPFILE" >&2
            exit 1
        }
        tar -xf "$ZIPFILE" || {
            echo "[ABORT] Extracting $ZIPFILE" >&2
            exit 1
        }
        rm "$ZIPFILE" || {
            echo "[ABORT] Deleting $ZIPFILE" >&2
            exit 1
        }
    fi

    if [[ -f "package.json" ]]; then
        if command -v pnpm &> /dev/null; then
            echo "[INFO] GodotJS - pnpm install"
            pnpm install || {
                echo "[ABORT] pnpm install" >&2
                exit 1
            }
            echo "[INFO] GodotJS - pnpm build"
            pnpm build || {
                echo "[ABORT] pnpm build" >&2
                exit 1
            }
        else
            echo "[INFO] pnpm not found, skipping pnpm install"
        fi
    else
        echo "[WARN] No package.json in $(pwd), skipping npm/pnpm install."
    fi

    popd
    popd

    # Add node_modules/.bin to PATH if it exists
    if [[ -d "$GROOT/modules/GodotJS/node_modules/.bin" ]]; then
        export PATH="$GROOT/modules/GodotJS/node_modules/.bin:$PATH"
    fi
    
    if command -v pnpm &> /dev/null; then
        echo "[INFO] pnpm on PATH for SCons:"
        command -v pnpm
    fi

    do_cli
}

do_cli() {
    echo "[INFO] Building Godot (default CLI)..."
    pushd "$GROOT"
    
    # Detect platform and build accordingly
    case "$(uname)" in
        Darwin*)
            # macOS
            scons platform=macos || {
                echo "[ABORT] scons build" >&2
                popd
                exit 1
            }
            ;;
        Linux*)
            # Linux
            scons platform=linuxbsd || {
                echo "[ABORT] scons build" >&2
                popd
                exit 1
            }
            ;;
        *)
            echo "[WARN] Unknown platform $(uname), using default platform"
            scons || {
                echo "[ABORT] scons build" >&2
                popd
                exit 1
            }
            ;;
    esac
    
    echo "[DONE] Godot executables are in ./bin"
    if [[ -d "bin" ]]; then
        pushd "bin"
        echo "[INFO] Now in $(pwd)"
        popd
    else
        echo "[WARN] ./bin directory not found. Staying in $(pwd)."
    fi
    
    popd
}

# Call main function
main "$@"

echo "[SUCCESS] All steps completed."