#!/usr/bin/env bash
set -eu
shopt -s nullglob

source $BSYS6/exports/version.sh
source $BSYS6/exports/setup_signing.sh
$BSYS6/utils/require_command.sh curl jq
$BSYS6/utils/require_choco.sh

abort="false"
for required_var in "CI_JOB_TOKEN" "REPO_DEPLOY_TOKEN" "CODEBERG_TOKEN" "GH_TOKEN" "CHOCO_API_KEY" "MS_CLIENT_SECRET"; do
  if [ -z "${!required_var:-}" ]; then
    echo "Error: '$required_var' is not set" >&2
    abort="true"
  fi
done
if [ "$abort" == "true" ]; then
  echo "Notice: This script is only meant to be run on GitLab CI" >&2
  exit 1
fi

if curl -f --header "JOB-TOKEN: $CI_JOB_TOKEN" "$CI_API_V4_URL/projects/$CI_PROJECT_ID/releases/$FULL_VERSION"; then
  echo "Error: Release $FULL_VERSION already exists" >&2
  exit 1
fi

packages=()
packages_other=()

upload_to_registry() {
  echo "-> Uploading $1 to GitLab package registry" >&2
  package_url="$GL_API/packages/generic/librewolf/$FULL_VERSION/$1"
  curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file "$1" "$package_url" >&2
  echo >&2
  echo "$package_url"
}

upload_asset() {
  asset="$(echo "$1" | sed 's/^.\///')"
  sha256sum "$asset" >>"sha256sums.txt"
  packages+=("$(upload_to_registry "$asset")")
  if [ -f "$asset.sha256sum" ]; then
    packages_other+=("$(upload_to_registry "$asset.sha256sum")")
  fi
  if [ -n "${SIGNING_KEY_FPR:-}" ]; then
    echo "-> Creating and uploading signature for '$asset' with key '$SIGNING_KEY_FPR'" >&2
    gpg --local-user "$SIGNING_KEY_FPR" --detach-sign "$asset"
    if [ -f "$asset.sig" ]; then
      packages_other+=("$(upload_to_registry "$asset.sig")")
    fi
  fi
}

publish_release() {
  echo "-> Publishing release $FULL_VERSION" >&2

  description="## LibreWolf bsys6 Release v$FULL_VERSION\n\n"

  if [ "$(echo "$FULL_VERSION" | cut -d'-' -f2)" == "1" ]; then
    ffver=$(echo "$FULL_VERSION" | cut -d'-' -f1)
    description="$description- Upstream release, see the [Firefox $ffver Release Notes](https://www.mozilla.org/en-US/firefox/$ffver/releasenotes/)"
  fi

  if [ ! -z "${CI_PIPELINE_ID:-}" ]; then
    description="$description\n\n(Built on GitLab by pipeline [$CI_PIPELINE_ID](https://gitlab.com/librewolf-community/browser/bsys6/-/pipelines/$CI_PIPELINE_ID))"
  fi

  codeberg_description="$description\n"
  assets=""

  for package in "${packages[@]}"; do
    name="$(basename "$package")"
    assets="$(
      cat <<-EOF
$assets
{
  "name": "$name",
  "url": "$package",
  "link_type": "package"
},
EOF
    )"
    codeberg_description="$codeberg_description\n[$(basename "$package")]($package)"
  done

  for package in "${packages_other[@]}"; do
    name="$(basename "$package")"
    assets="$(
      cat <<-EOF
$assets
{
  "name": "$name",
  "url": "$package",
  "link_type": "other"
},
EOF
    )"
  done

  body="$(
    cat <<EOF
{
  "name": "$FULL_VERSION",
  "tag_name": "$FULL_VERSION",
  "ref": "master",
  "description": "$description",
  "assets": {
    "links": [
${assets:1:-1}
    ]
  }
}
EOF
  )"
  echo "$body"
  curl --header 'Content-Type: application/json' \
    --header "JOB-TOKEN: $CI_JOB_TOKEN" \
    --data "$body" \
    --request POST \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/releases"

  codeberg_description="$codeberg_description\n\n[View on GitLab](https://gitlab.com/librewolf-community/browser/bsys6/-/releases/$FULL_VERSION)"
  codeberg_body="$(
    cat <<EOF
{
  "name": "$FULL_VERSION",
  "tag_name": "$FULL_VERSION",
  "body": "$codeberg_description"
}
EOF
  )"
  curl --header 'Content-Type: application/json' \
    --header 'accept: application/json' \
    --data "$codeberg_body" \
    --request POST \
    "https://codeberg.org/api/v1/repos/librewolf/bsys6/releases?token=$CODEBERG_TOKEN"
}

push_nupkg() {
  echo "-> Pushing $1 to Chocolatey"
  "$MOZBUILD/chocolatey/choco" push "$1" --source https://push.chocolatey.org/ -k $CHOCO_API_KEY
}

push_msix() {
  echo "-> Pushing $1 to the Microsoft Store"
  echo "Obtaining access token"
  ms_access_token="$(curl -X POST https://login.microsoftonline.com/8e129239-9e0b-4c0d-ac63-792a85bcc57f/oauth2/token --header "Content-Type: application/x-www-form-urlencoded" --data "grant_type=client_credentials&client_id=cd3474b9-1bed-44e3-970c-7040dad00df7&client_secret=$MS_CLIENT_SECRET&scope=https://api.store.microsoft.com/.default" | jq -r '.access_token')"
}

gh_request() {
  response="$(curl -s -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github.v3+json" "$@")"
  if [ "$(echo "$response" | jq 'type')" == "object" ]; then
    if [ "$(echo "$response" | jq 'has("message")')" == "true" ]; then
      echo "Error with GitHub API: $(echo "$response" | jq -r '.message')" >&2
      exit 1
    fi
    if [ "$(echo "$response" | jq 'has("errors")')" == "true" ]; then
      echo "Error(s) with GitHub API:" >&2
      echo "$pr_response" | jq -r '.errors | .[].message' >&2
      exit 1
    fi
  fi
  echo "$response"
}

gh_prepare_repo() {
  username=$(gh_request "https://api.github.com/user" | jq -r .login)
  if ! curl -sf -H "Authorization: token $GH_TOKEN" "https://api.github.com/repos/$username/$2" >/dev/null; then
    printf "Forking $1/$2...\r"
    gh_request -X POST "https://api.github.com/repos/$1/$2/forks" >/dev/null
    echo "Forked $1/$2 to $username/$2"
  fi
  CLONEDIR="$WORKDIR/$2"
  if [ ! -d "$CLONEDIR/.git" ]; then
    git clone https://github.com/$username/$2.git "$CLONEDIR"
    (
      cd "$CLONEDIR"
      git remote add upstream https://github.com/$1/$2.git
      git config user.name "LibreWolf"
      git config user.email "bsys6@librewolf.net"
      git config commit.gpgSign "false"
    )
  fi
  (
    cd "$CLONEDIR"
    git fetch upstream
    git switch -C bsys6_automation
    git reset --hard upstream/master
  )
}

gh_submit_pr() {
  username=$(gh_request "https://api.github.com/user" | jq -r .login)
  (
    cd "$CLONEDIR"
    git add .
    git commit -m "$3"
    git remote set-url --push origin https://$username:$GH_TOKEN@github.com/$username/$2.git
    git push origin bsys6_automation --force
  )
  printf "Creating pull request...\r"
  pr_response=$(gh_request "https://api.github.com/repos/$1/$2/pulls" -d "{\"head\":\"$username:bsys6_automation\",\"base\":\"master\",\"title\":\"$3\",\"body\":\"(This pull-request was auto-generated, ping @maltejur)\"}")
  echo "Pull request created: $(echo "$pr_response" | jq -r .html_url)"
}

submit_winget() {
  gh_prepare_repo "microsoft" "winget-pkgs"
  echo "-> Sumbitting $1 as a pull request to winget-pkgs"
  wingetdir="$CLONEDIR/manifests/l/LibreWolf/LibreWolf/$FULL_VERSION"
  mkdir "$wingetdir"
  export WINGET_FILE="$GL_API/packages/generic/librewolf/$FULL_VERSION/$1"
  export WINGET_CHECKSUM="$(cat "${1}.sha256sum")"
  envsubst '$FULL_VERSION $WINGET_FILE $WINGET_CHECKSUM' \
    <"$BSYS6/../assets/winget/LibreWolf.LibreWolf.installer.yaml.in" \
    >"$wingetdir/LibreWolf.LibreWolf.installer.yaml"
  envsubst '$FULL_VERSION' \
    <"$BSYS6/../assets/winget/LibreWolf.LibreWolf.locale.en-US.yaml.in" \
    >"$wingetdir/LibreWolf.LibreWolf.locale.en-US.yaml"
  envsubst '$FULL_VERSION' \
    <"$BSYS6/../assets/winget/LibreWolf.LibreWolf.yaml.in" \
    >"$wingetdir/LibreWolf.LibreWolf.yaml"
  gh_submit_pr "microsoft" "winget-pkgs" "Update LibreWolf.LibreWolf to v$FULL_VERSION"
}

for file in $(find -name "*.exe" -o -name "*.zip" -o -name "*.tar.bz2" -o -name "*.msix" -o -name "*.dmg"); do
  upload_asset "$file"
done

packages_other+=("$(upload_to_registry "sha256sums.txt")")

publish_release

for file in $(find -name "*windows-x86_64-nupkg.nupkg"); do
  push_nupkg "$file"
done

for file in $(find -name "*windows-x86_64-setup.exe"); do
  submit_winget "$file"
done
