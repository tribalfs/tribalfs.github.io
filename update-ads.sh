#!/usr/bin/env bash
# Forwarding wrapper for backward compatibility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/publish.sh" "$@"
