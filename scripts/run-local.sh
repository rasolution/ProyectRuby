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
    RAILS_ENV=test bundle exec rails db:prepare
    bundle exec rails test test/integration/local_smoke_test.rb
    ;;
  run)
    bundle exec rails db:prepare
    exec bundle exec rails server -b 127.0.0.1 -p "${PORT:-3000}"
    ;;
  *) echo "Usa build, test o run" >&2; exit 2 ;;
esac
