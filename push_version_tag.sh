#!/bin/bash

# Check if version parameter is provided
if [ -z "$1" ]; then
    echo "Error: Version number is required"
    echo "Usage: ./push_version_tag.sh <version>"
    exit 1
fi

VERSION=$1

# Create annotated tag
echo "Creating tag $VERSION..."
git tag -a $VERSION -m "Release version $VERSION"

# Push tag to remote
echo "Pushing tag $VERSION to remote..."
git push origin $VERSION

echo "Tag $VERSION created and pushed successfully!" 