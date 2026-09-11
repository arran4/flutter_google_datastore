#!/bin/bash
set -euo pipefail

# This script evaluates release policies, calculating the next semantic version
# or verifying the exact conditions required for release.

action=$1

if [[ "$action" == "verify_main_sha" ]]; then
    # Verify origin/main
    # Usage: ./scripts/release_policy.sh verify_main_sha <github_ref_name> <github_sha>
    ref_name=$2
    github_sha=$3
    if [[ "$ref_name" != "main" ]]; then
        echo "Error: Manual release preparation must run on main, got $ref_name"
        exit 1
    fi
    git fetch origin main
    main_sha=$(git rev-parse origin/main)
    if [[ "$main_sha" != "$github_sha" ]]; then
        echo "Error: Requested release against $github_sha but origin/main is at $main_sha"
        exit 1
    fi
    echo "Success: Main SHA verified"
elif [[ "$action" == "calculate_tag" ]]; then
    # Calculate the tag
    # Usage: ./scripts/release_policy.sh calculate_tag <release_version_override> <release_mode>
    override=$2
    mode=$3

    if [[ -n "$override" ]]; then
        TAG="${override#v}"
        TAG="v${TAG}"
        if ! [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
            echo "Error: Override $TAG is not a valid release tag shape."
            exit 1
        fi
    else
        case "$mode" in
            release-major) level="major"; suffix="" ;;
            release-minor) level="minor"; suffix="" ;;
            release-patch) level="patch"; suffix="" ;;
            release-test)  level="patch"; suffix="test" ;;
            release-rc)    level="patch"; suffix="rc" ;;
            release-alpha) level="patch"; suffix="alpha" ;;
            *) echo "Unsupported release mode: $mode" >&2; exit 1 ;;
        esac
        args=(--print-version-only "$level")
        [[ -n "$suffix" ]] && args+=("$suffix")
        TAG="$(git-tag-inc "${args[@]}")"
    fi
    echo "$TAG"
elif [[ "$action" == "idempotent_push" ]]; then
    # Usage: ./scripts/release_policy.sh idempotent_push <tag> <github_sha>
    tag=$2
    github_sha=$3

    # Check remote state for idempotency/retry
    remote_sha=$(git ls-remote --tags origin "refs/tags/$tag" | grep -v '{}$' | awk '{print $1}' || true)
    peeled_sha=$(git ls-remote --tags origin "refs/tags/$tag^{}" | awk '{print $1}' || true)
    if [[ -n "$peeled_sha" ]]; then
        remote_sha="$peeled_sha"
    fi

    if [[ -n "$remote_sha" ]]; then
        if [[ "$remote_sha" == "$github_sha" ]]; then
            echo "Tag $tag already exists on origin and points to correct SHA ($github_sha). Safely retrying publish."
        else
            echo "Error: Tag $tag already exists on origin but points to $remote_sha, not expected $github_sha."
            exit 1
        fi
    else
        # Final race guard: verify origin/main is STILL exactly github_sha right before tagging
        git fetch origin main
        current_main_sha=$(git rev-parse origin/main)
        if [[ "$current_main_sha" != "$github_sha" ]]; then
            echo "Race condition: origin/main advanced to $current_main_sha before tagging"
            exit 1
        fi

        # If local tag exists but wasn't pushed, delete to recreate fresh
        git tag -d "$tag" 2>/dev/null || true

        # Create and push the tag
        git tag "$tag"
        git push origin "$tag" || {
            # Race safe remote verification
            remote_sha=$(git ls-remote --tags origin "$tag" | awk '{print $1}')
            if [[ "$remote_sha" != "$github_sha" ]]; then
                echo "Race condition: tag pushed remotely with different SHA ($remote_sha)"
                exit 1
            fi
        }
    fi
else
    echo "Unknown action: $action"
    exit 1
fi
