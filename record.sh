#!/bin/bash

scenario="${1?Specify a scenario name}"
tomeetck="${2?Specify the location of the cloned tomee-tck repository}"

[ -d "$tomeetck" ] || {
    echo "Directory does not exist: $tomeetck"
    exit 1
}

shift #scenario
shift #tomeetck

# The remaining arguments will be passed directly to the
# real runtests command from tomeetck.  The only thing we
# need to do to those is scan them first to find the name
# of the test being executed.

# Find the name of the test being executed
for n in "$@"; do
    [[ "$n" == com.sun.* ]] && test="$n"
done

# If we didn't find the test name, fail
[ -n "$test" ] || {
    echo "No com.sun.* tests specified in args"
    exit 1
}

# Make the scenario/test directory
# Delete and remake if it exists
dest="$PWD/$scenario/$test"

[ -d "$dest" ] && rm -rf "$dest"
mkdir -p "$dest"

# Now run the actual test and collect the output
(cd "$tomeetck" &&
     ./runtests "$@" 2>&1 | tee "$dest/output.txt"
) 

# Copy all the *.log files into our destination
rsync -zarv --prune-empty-dirs \
      --include "*/"  --include="*.log" --exclude="*" \
      "$tomeetck/" "$dest"

# Immediately do a git add to protect our results
# from the `git clean -fd` that the fake runtests
# script does. Its common users will try the fake
# runtests script shortly after this.
git add "$dest"
git status
