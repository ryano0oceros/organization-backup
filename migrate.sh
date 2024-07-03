#!/bin/bash

# Check if organization name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <organization>"
  exit 1
fi

# Check if GitHub token is provided
if [ -z "$2" ]; then
  echo "Usage: $0 <organization> <github_token>"
  exit 1
fi

# Step 1: Set the organization name and GitHub token from input parameters
ORG_NAME=$1
GITHUB_TOKEN=$2

# Step 2: Authenticate with GitHub CLI using the provided token
echo $GITHUB_TOKEN | gh auth login --with-token

# Step 3: Populate the repositories.json file
gh repo list $ORG_NAME | awk '{print $1}' | jq -R -s 'split("\n") | map(select(length > 0)) | {lock_repositories: false, exclude_attachments: false, repositories: .}' > repositories.json

# Step 4: Make the initial POST request and capture the response
response=$(gh api -X POST /orgs/$ORG_NAME/migrations \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  --input repositories.json)

# Step 5: Extract the ID from the response
migration_id=$(echo $response | jq -r '.id')

# Step 6: Wait until the migration state is "exported"
echo "Waiting for the migration to complete..."
while true; do
  migration_status=$(curl -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/orgs/$ORG_NAME/migrations/$migration_id | jq -r '.state')
  if [ "$migration_status" = "exported" ]; then
    break
  fi
  echo "Migration status: $migration_status. Waiting for 10 seconds..."
  sleep 10
done

# Step 7: Use the ID in the first curl command
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/orgs/$ORG_NAME/migrations/$migration_id

# Step 8: Clone each repository, fetch all branches, pull updates, and create a zip file
echo "Cloning each repository, fetching all branches, pulling updates, and creating a zip file..."
mkdir -p "$ORG_NAME-repos"
for repo in $(jq -r '.repositories[]' repositories.json); do
  repo_name=$(basename $repo)
  git clone "https://github.com/$ORG_NAME/$repo_name.git" "$ORG_NAME-repos/$repo_name"
  if [ $? -eq 0 ]; then
    echo "Cloned repository: $repo_name"
    cd "$ORG_NAME-repos/$repo_name"
    git fetch --all
    git pull
    cd ../..
  else
    echo "Failed to clone repository: $repo_name"
  fi
done

# Step 9: Zip all repositories at the organization level
echo "Creating a zip file for all repositories..."
zip -r "${ORG_NAME}.zip" "$ORG_NAME-repos"
echo "Created zip file: ${ORG_NAME}.zip"

# Step 10: Clean up
rm -rf "$ORG_NAME-repos"

# Step 11: Wait for the download to complete
echo "Waiting for the downloads to complete..."
sleep 5  # Adjust the time as needed to ensure the downloads complete

# Step 12: Unlock the repositories using curl command (commented out if not needed)
# echo "Unlocking the repositories..."
# for repo in $(jq -r '.repositories[]' repositories.json); do
#   repo_name=$(basename $repo)
#   curl -L \
#     -X DELETE \
#     -H "Accept: application/vnd.github+json" \
#     -H "Authorization: Bearer $GITHUB_TOKEN" \
#     -H "X-GitHub-Api-Version: 2022-11-28" \
#     https://api.github.com/orgs/$ORG_NAME/migrations/$migration_id/repos/$repo_name/lock
#   echo "Unlocked repository: $repo"
# done

# echo "All repositories have been unlocked."
