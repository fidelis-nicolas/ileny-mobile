# CI/CD operations

All changes go through a short-lived `feat/`, `fix/`, or `chore/` branch and a pull request.
The default branch is `main`. CI must pass on the PR's merge commit before squash merging.
These pipeline branches deliberately exclude unrelated commits on existing feature branches.

## Repository protection

GitHub currently rejects protection updates for the private backend and frontend repositories
with a plan-related HTTP 403. The public mobile repository supports enforced protection.
An eligible plan/account is required for private-repository enforcement. Do not change
repository visibility as a workaround. The workflows support a future Enterprise move;
update owner/package paths and installed host image allowlists during that move.

The exact proposed policy is `.github/branch-protection.json`. Once eligible, a repository
administrator can apply it using an already authenticated GitHub CLI:

```sh
gh api --method PUT repos/fidelis-nicolas/ileny-mobile/branches/main/protection --input .github/branch-protection.json
```

Zero mandatory approvals supports the current solo-maintainer setup; PRs and passing checks
are still required. Increase approvals to one when a second maintainer is available.
Enable squash merging, disable other merge methods, and delete merged branches.

For a local guard, install the included pre-push hook with
`git config --local core.hooksPath .githooks` after this branch is merged into your checkout.
The hook rejects direct pushes, force pushes, and deletions targeting `main` or `master`.
Local hooks can be bypassed and cannot replace GitHub branch protection.

## Validation and maintenance

Actions are pinned to full commit SHAs. Dependabot proposes weekly action updates through PRs.
PR jobs have read-only repository access and never receive deployment or signing credentials.
Workflow changes should be checked with actionlint before merging.

## Mobile release flow

CI pins Flutter 3.44.4 / Dart 3.12.2 to match the project's SDK constraint and existing
toolchain. It enforces the committed lockfile, runs analysis and widget tests, builds an
Android debug APK, and builds iOS without code signing on a macOS runner. Test builds use
an explicit non-production API URL. Coverage is uploaded as a workflow artifact. Existing
informational style lints are non-blocking; analyzer errors and warnings still fail CI.

Signed releases are manually triggered from `main` after the complete CI workflow succeeds.
Android produces an APK and Play AAB with checksums and commit metadata. iOS produces a
signed IPA using an ephemeral keychain. These workflows produce reviewable artifacts;
they do not submit to Google Play, App Store Connect, or Firebase Distribution.

Create `staging` and `production` environments, restricted to `main`. Add independent
reviewers when supported by the account plan. Each needs `API_BASE_URL`, an explicit HTTPS
URL ending in `/api/v1`. Use a sandbox backend for staging. Keep app version names in
`pubspec.yaml`; supply a unique increasing build number above all previously uploaded builds.

Android environment secrets:

| Secret | Content |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64 of the existing upload keystore |
| `ANDROID_KEY_PROPERTIES` | Java properties containing `storePassword`, `keyAlias`, `keyPassword` |

Use Java-properties escaping for passwords containing backslashes or control characters.
The workflow forces `storeFile=upload-keystore.jks`, refuses missing signing properties,
and removes the keystore after the build. Never substitute a new upload key for an existing
store app without following the store's key rotation process.

iOS production environment secrets:

| Secret | Content |
| --- | --- |
| `IOS_CERTIFICATE_BASE64` | Base64 Apple Distribution certificate with private key (P12) |
| `IOS_CERTIFICATE_PASSWORD` | P12 import password |
| `IOS_PROFILE_BASE64` | Base64 App Store provisioning profile for `app.ileny.mobile` |
| `IOS_EXPORT_OPTIONS_BASE64` | Base64 reviewed ExportOptions.plist matching the team/profile |

Apple membership, certificate/profile validity, Xcode signing team configuration, and store
access must already exist. No credentials are generated. macOS jobs cannot be verified on
Windows; review their GitHub run before release. Store upload automation can be added once
distribution destinations, existing access, and release tracks are established.

Before first release, merge and validate any outstanding app changes through their own PRs.
The existing `firebase-app-distribution` branch is not bundled into this pipeline PR.
