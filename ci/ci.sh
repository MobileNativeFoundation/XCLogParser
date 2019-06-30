#!/bin/sh

# Source Helper Functions
source "$(dirname "$0")/helpers.sh"

# Only install tools when running on travis
if [ -n "$TRAVIS_BUILD_ID" ]; then
  heading "Installing Tools"
  brew install swiftlint
  gem install xcpretty
fi

has_command swiftlint || fail "SwiftLint must be installed"
has_command xcpretty || fail "xcpretty must be installed"

#
# Fail fast with swiftlint
#
heading "Linting"

swiftlint lint --no-cache --strict || \
  fail "swiftlint failed"

#
# Build in release mode
#
heading "Building"
set -o pipefail && rake build[release] | xcpretty || \
  fail "Release Build Failed"

#
# Run Tests
#
heading "Running Tests"

set -o pipefail && rake test | xcpretty || \
  fail "Test Run failed"
