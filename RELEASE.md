# Release Process

## Prerequisites

- Push access to the `master` branch
- Access to the repository's branch protection rulesets (Settings > Rules > Rulesets)
- The npm package is published automatically via [trusted publishers (OIDC)](https://docs.npmjs.com/trusted-publishers)

## Steps

### 1. Disable branch protection

Go to **Settings > Rules > Rulesets** and disable the branch protection ruleset for `master`.

This is required because the build workflow commits pre-built binaries directly to `master`.

### 2. Bump the version

Update the version in `package.json` and push to `master`:

```bash
# edit package.json to set the new version, then:
git add package.json
git commit -m "<new-version>"
git push origin master
```

### 3. Create a GitHub Release

Go to **Releases > Draft a new release** on GitHub:

- Create a new tag matching the version (e.g. `2.6.0`)
- Set the target to `master`
- Add release notes
- Publish the release

This triggers two workflows:

- **Build the binary** (`build.yml`) — compiles `yara.node` for Linux (Node 20/22/24) and macOS (x64 + arm64, Node 20/22/24), then commits the `.tar.gz` binaries to `master`
- **Publish to npm** (`npmpublish.yml`) — publishes the package to npm

### 4. Wait for builds to complete

Monitor the **Actions** tab. The build jobs (9 in total) will each commit a binary to the `binaries/` directory on `master`. This takes a few minutes.

> **Note:** The npm publish job runs in parallel with the build jobs. This means the package is published to npm before the pre-built binaries are available on GitHub. Users who install during this window will fall back to building from source. The binaries become available once all build jobs finish committing.

### 5. Verify

Once all build jobs have completed:

- Check that the `binaries/` directory on `master` contains `.tar.gz` files for the new version
- Check that the test workflows (triggered by the binary commits) pass
- Verify the package on npm: `npm view @automattic/yara version`

### 6. Re-enable branch protection

Go back to **Settings > Rules > Rulesets** and re-enable the branch protection ruleset for `master`.

## Troubleshooting

### Build jobs fail with "protected branch hook declined"

The branch protection ruleset was not disabled before creating the release. Disable it, then re-run the failed jobs from the Actions tab.

### Tests fail after version bump but before release

This is expected. After bumping the version, `npm install` tries to download binaries for the new version, which don't exist yet. The tests will pass after the release builds complete and commit the new binaries.
