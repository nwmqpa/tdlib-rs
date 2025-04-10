#!/bin/bash

TOP_DIR=$(git rev-parse --show-toplevel)

CURRENT_TDLIB_VERSION=$(
    curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/tdlib/td/contents/CMakeLists.txt --silent \
    | jq .content -r | base64 -d | grep "TDLib VERSION" | cut -d ' ' -f 3
)

echo "Current version:" $CURRENT_TDLIB_VERSION

for commit_url in $(curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/tdlib/td/commits?path=CMakeLists.txt" --silent | jq -r '.[].url');
do
    COMMIT_VERSION=$(curl --silent -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "$commit_url" \
        | jq '.files[] | select(.filename == "CMakeLists.txt").patch' -r | sed -n '/^-project(TDLib VERSION [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]* LANGUAGES CXX C)/{
              n
              /^+project(TDLib VERSION \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\) LANGUAGES CXX C)/s//\1/p
              }')

    if [[ $COMMIT_VERSION == $CURRENT_TDLIB_VERSION ]]; then
        echo "Found commit with version $COMMIT_VERSION"
        COMMIT_SHA=$(echo $commit_url | cut -d '/' -f 8)
        echo "Commit SHA: $COMMIT_SHA"
        break
    fi
done

if [[ -z $COMMIT_SHA ]]; then
    echo "No commit found with version $CURRENT_TDLIB_VERSION"
    exit 1
fi

# Update bindings
echo "Updating bindings..."

curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/tdlib/td/contents/td/generate/scheme/td_api.tl?ref=$COMMIT_SHA" --silent \
    | jq .content -r | base64 -d > "$TOP_DIR/tdlib/tl/api.tl"

sed -i '' \
  -e "s/\"COMMIT_SHA\" = \".*\"/\"COMMIT_SHA\" = \"$COMMIT_SHA\"/" \
  -e "s/libtdjson:[0-9.]\+\(-[^\"]*\)\?/libtdjson:$COMMIT_VERSION\1/g" \
  $TOP_DIR/docker-bake.hcl

sed -i '' -E "s/(tdjson[[:space:]]*=[[:space:]]*\")[^\"]+\"/\1$COMMIT_VERSION\"/" $TOP_DIR/tdlib/Cargo.toml

current_version=$(sed -nE 's/^[[:space:]]*version[[:space:]]*=[[:space:]]*"([0-9]+)\.([0-9]+)\.([0-9]+)"/\1.\2.\3/p' "$TOP_DIR/tdlib/Cargo.toml")
major=$(echo "$current_version" | cut -d. -f1)
minor=$(echo "$current_version" | cut -d. -f2)
new_minor=$((minor + 1))
new_version="$major.$new_minor.0"

sed -i '' -E "s/^[[:space:]]*version[[:space:]]*=[[:space:]]*\"[0-9]+\.[0-9]+\.[0-9]+\"/version = \"$new_version\"/" "$TOP_DIR/tdlib/Cargo.toml"
