#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")/../proyecto" && pwd)"
export BUNDLE_PATH="${GH_RUBY_BUNDLE_PATH:-$HOME/.local/share/gh-ruby-gems}"
if [ -d /opt/gh-node22/bin ]; then export PATH="/opt/gh-node22/bin:$PATH"; fi
bundle check || bundle install
case "${1:-build}" in
  build)
    bundle exec rails zeitwerk:check
    bundle exec rails db:prepare
    SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile
    ;;
  test)
    export RAILS_ENV=test
    if [ -z "${RAILS_TEST_DATABASE_PATH:-}" ]; then
      test_dir=$(mktemp -d "${TMPDIR:-/tmp}/proyectruby-tests.XXXXXX")
      export RAILS_TEST_DATABASE_PATH="$test_dir/test.sqlite3"
      trap 'rm -f "$test_dir/test.sqlite3" "$test_dir/test.sqlite3-wal" "$test_dir/test.sqlite3-shm"; rmdir "$test_dir"' EXIT
    fi
    bundle exec rails db:prepare
    bundle exec rails test
    ;;
  run)
    bundle exec rails db:prepare
    exec bundle exec rails server -b 127.0.0.1 -p "${PORT:-3000}"
    ;;
  *) echo "Usa build, test o run" >&2; exit 2 ;;
esac
