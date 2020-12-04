#!/usr/bin/env bash

set -e

BRANCH="gh-pages"
FOLDER="_site"
BUILD_SCRIPT="bin/jekyll build"
CNAME="josephchoe.com"

if [ -z ${BASE_BRANCH+x} ]; then
  echo "(BASE_BRANCH is not set. Using \"master\" by default.)"
  base_branch="master"
else
  base_branch=$BASE_BRANCH
fi

# Initialize the repository path.
REPOSITORY_PATH="origin"

# Check to see if the remote exists prior to deploying.
# If the branch doesn't exist create here as an orphan.
if [ "$(git ls-remote --heads "$REPOSITORY_PATH" "$BRANCH" | wc -l)" -eq 0 ];
then
  echo "Creating remote branch ${BRANCH} as it doesn't exist..."
  git checkout $base_branch && \
  git checkout --orphan $BRANCH && \
  git rm -rf . && \
  touch README.md && \
  git add README.md && \
  git commit -m "Initial ${BRANCH} commit" && \
  git push $REPOSITORY_PATH $BRANCH
fi

# Check out the base branch to begin the deploy process.
git checkout $base_branch && \

# Build the project if a build script is provided.
echo
echo "Running build scripts..."
echo '= = ='

eval "$BUILD_SCRIPT" && \

if [ "$CNAME" ]; then
  echo "Generating a CNAME file in the $FOLDER directory..."
  echo $CNAME > $FOLDER/CNAME
fi

# Commit the data to Github.
echo
echo "Deploying to GitHub..."
echo '= = ='

git add -f $FOLDER && \

git commit -m "Deploy to ${BRANCH} from $base_branch" --quiet && \
git push $REPOSITORY_PATH `git subtree split --prefix $FOLDER $base_branch`:$BRANCH --force && \
git reset --hard HEAD^ && \

echo '- - -'
echo '(done)'
echo
