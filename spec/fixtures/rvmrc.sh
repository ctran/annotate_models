# This file is a hybrid file meant for live debugging without going through an
# actual RSpec run, and for being used in an RSpec run.  To change it, change
# template..rvmrc and run 'rake templates:rebuild' which will do so for all
# templates in all build scenarios.
#
# ALSO, be sure NOT to commit any changes that happen in app/* or config/*
# when debugging this way as that will defeat the point of the automated tests!
#
# In fact, before running RSpec again after manual testing, you should run
# 'rake integration:clober' to reset modified files to their pristine state,
# and remove cruft that may interfere with the build.
if [ "$(type rvm | head -1)" != "rvm is a function" ]; then
  # First, make sure we're not in 'sh' mode (I.E. strict-superset-of-Bourne
  # mode), as RVM doesn't like this...
  shopt -u -o posix
  # Now, load RVM...
  source $HOME/.rvm/scripts/rvm
fi

# Now, switch to our preferred Ruby and gemset...
GEMSET=annotate_test_$(basename $(pwd) | perl -pse 's/\.//g')
rvm use --create ${rvm_ruby_string}@${GEMSET}

# Early-out when we just want to wipe the gemsets clean...
if [ "$SKIP_BUNDLER" != "1" ]; then
  # ... and make sure everything's up-to-date, that it'll use the right Gemfile,
  # etc.
  if [ $(which bundle) == "" ]; then
    gem install bundler
  fi
  export BUNDLE_GEMFILE=./Gemfile
  # The apparently superfluous --gemfile param is to work around some stupidness
  # in Bundler.  Specifically it gets very confused about BUNDLE_GEMFILE not
  # pointing at an absolute path.
  #
  # The special-case handling of bin being empty is to support debug workflows
  # where the gemset will in fact already be set up, but the binstubs get nuked.
  mkdir -p bin
  if [ $(($(ls bin | wc -l) + 0)) -eq 0 ]; then
    bundle install --binstubs=bin --gemfile ./Gemfile
  else
    bundle check || bundle install --binstubs=bin --gemfile ./Gemfile
  fi
fi
