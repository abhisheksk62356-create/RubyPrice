ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Bootsnap's native path cache can't handle non-ASCII characters (e.g. an
# em dash) that may appear in this application's parent directory path on
# some systems, so it's opt-out via an environment variable rather than a
# hard requirement.
require "bootsnap/setup" unless ENV["DISABLE_BOOTSNAP"]
