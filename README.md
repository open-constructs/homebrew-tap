# open-constructs/homebrew-tap

Homebrew tap for [Open Constructs](https://github.com/open-constructs) projects.

## Install

```sh
brew install open-constructs/tap/cdktn
```

The fully-qualified form works without a prior `brew tap`. If you plan to install other `open-constructs/tap` formulae later, you can tap once and install by short name:

```sh
brew tap open-constructs/tap
brew install cdktn
```

## Formulae

### `cdktn` — [CDK Terrain](https://github.com/open-constructs/cdk-terrain) CLI

Community fork of the deprecated `cdktf` (CDK for Terraform) formula.

- **Current version:** 0.22.1 (tracks the [`cdktn-cli`](https://www.npmjs.com/package/cdktn-cli) npm release)
- **Source:** [`open-constructs/cdk-terrain`](https://github.com/open-constructs/cdk-terrain)
- **License:** MPL-2.0
- **Dependencies:** `node@20`, `yarn` (build-time). A Terraform-compatible binary (`hashicorp/tap/terraform` or `opentofu`) is required at runtime but **not** enforced by the formula — see [Runtime: Terraform or OpenTofu](#runtime-terraform-or-opentofu).
- **Formula:** [`Formula/cdktn.rb`](./Formula/cdktn.rb)

**Stable** (`brew install cdktn`): installs the prebuilt [`cdktn-cli`](https://www.npmjs.com/package/cdktn-cli) npm tarball into `libexec` — around 390 MB installed.

**Bleeding-edge** (`brew install --HEAD cdktn`): builds from the `cdk-terrain` main branch via `yarn build` (full monorepo, tsc + jsii) — around 1.5 GB installed.

### Runtime: Terraform or OpenTofu

`cdktn` shells out to a Terraform-compatible binary at runtime. It's intentionally **not** a formula dependency so you can pick the binary that matches your licensing and workflow preferences:

- **Why no default?** Hashicorp relicensed Terraform from MPL-2.0 to the Business Source License (BSL) in August 2023. Homebrew-core subsequently dropped the `terraform` formula (the community fork `opentofu` replaced it for users who want to stay on an open-source license). CDK Terrain itself exists as a community fork of the [now-archived](https://github.com/hashicorp/terraform-cdk) `terraform-cdk` (CDKTF) project — we don't want to force tap users onto either side of that split.

Install whichever you prefer:

```sh
brew install hashicorp/tap/terraform   # upstream Terraform (BSL)
# — or —
brew install opentofu                  # OpenTofu (MPL-2.0) — open-source fork
```

If you use OpenTofu, point the cdktn CLI at the `tofu` binary via the `cdktf`-era env var that cdktn still honors:

```sh
export TERRAFORM_BINARY_NAME=tofu
```

(cdktn inherits `TERRAFORM_BINARY_NAME` from CDKTF for backwards compatibility with existing projects — no `CDKTN_*` alias is needed.)

### Migrating from `cdktf`

Homebrew's `cdktf` formula was deprecated by upstream and will be disabled on 2026-12-10. To switch:

```sh
brew uninstall cdktf
brew tap open-constructs/tap
brew install cdktn
```

The CLI binary renames `cdktf` → `cdktn`. Existing `cdktf.json` config files and `CDKTF_*` environment variables still work (see the upstream [CDKTN Rename notes](https://github.com/open-constructs/cdk-terrain/blob/main/CLAUDE.md#cdktn-rename)).

### Troubleshooting

**`brew install` fails at `brew link` with a conflict on `/opt/homebrew/bin/cdktn`:**
You have a stale global npm install of `cdktn-cli` on your PATH. Remove it with:

```sh
npm uninstall -g cdktn-cli
```

Then re-run `brew link cdktn`. (Note: [`cdktn-cli` on npm](https://www.npmjs.com/package/cdktn-cli) is the real, maintained CLI — same artifact Homebrew installs. If you prefer npm over Homebrew you can keep the npm install; the conflict only matters if you want both.)

**Install size feels large for a CLI.** The stable (npm) path is ~390 MB and the `--HEAD` path is ~1.5 GB. Both ship the CLI's runtime `node_modules` because the CLI is a partial esbuild bundle that loads several dependencies (`cdktn`, `@cdktn/hcl2cdk`, `constructs`, `yargs`, ...) at runtime rather than inlining them.

### Formula internals

A few non-obvious bits future maintainers should know about `Formula/cdktn.rb`:

- **`bare-*` prebuild prune.** The stable install block deletes non-native `prebuilds/*` directories from `bare-fs`, `bare-os`, and `bare-url` (transitive deps pulled in by the holepunch runtime). Without this, `brew audit --new --strict --online` flags the foreign-arch `.bare` binaries as "non-native binaries installed into cdktn's prefix." cdktn never loads them, so pruning is safe.
- **Stable vs `--HEAD` branches.** Stable installs the published npm tarball; `--HEAD` does a full monorepo `yarn install && yarn build` against `open-constructs/cdk-terrain`'s `main`. The `--HEAD` path also rewrites `"version": "0.0.0"` in `packages/cdktn-cli/package.json` so `cdktn --version` matches the formula version at build time.

## Testing locally from the tap source

To iterate on a formula change without a full GitHub round-trip, point Homebrew at a local clone of this repo. Modern Homebrew (≥5.x) **clones** the source path rather than symlinking, so there are two options:

### Option A — clone-and-pull (simplest, slowest iteration)

```sh
git clone https://github.com/open-constructs/homebrew-tap.git
cd homebrew-tap
brew untap open-constructs/tap 2>/dev/null || true
brew tap open-constructs/tap "$(pwd)"
```

Edit `Formula/cdktn.rb` in your clone, then `git add && git commit`, then tell the tapped copy to pull:

```sh
git -C /opt/homebrew/Library/Taps/open-constructs/homebrew-tap pull
```

Each edit needs a local commit + `git pull` before `brew audit` / `brew install` sees it.

### Option B — symlink the tap directory (fastest iteration)

Replace the tap clone with a symlink to your working tree so edits are picked up immediately — no commit, no pull:

```sh
brew untap open-constructs/tap 2>/dev/null || true
rm -rf /opt/homebrew/Library/Taps/open-constructs/homebrew-tap
ln -s "$(pwd)" /opt/homebrew/Library/Taps/open-constructs/homebrew-tap
```

When you're done, restore the real tap:

```sh
rm /opt/homebrew/Library/Taps/open-constructs/homebrew-tap
brew tap open-constructs/tap
```

### Audit

```sh
brew audit --new --strict --online open-constructs/tap/cdktn
```

`--new` applies stricter rules (used for formulae new to a tap). `--online` fetches the `url`/`head` to verify they resolve. Exit 0 means clean.

### Install — stable (npm)

```sh
brew install open-constructs/tap/cdktn
cdktn --version   # should print the formula's version
```

Add `--verbose` to see every step. Add `--build-from-source` to force the `def install` block to run locally (meaningless for this formula today since it has no bottles, but useful later).

### Install — `--HEAD` (source build from cdk-terrain main)

```sh
brew install --HEAD open-constructs/tap/cdktn
```

Builds from `github.com/open-constructs/cdk-terrain` `main`. Expect ~1.5 GB on disk.

### Run the formula's test block

```sh
brew test cdktn
```

Requires the formula to be `brew link`-ed. If linking is blocked by a conflict (see Troubleshooting above), either resolve the conflict or read the `test do` block in [`Formula/cdktn.rb`](./Formula/cdktn.rb) and invoke its assertions by hand against `/opt/homebrew/Cellar/cdktn/<version>/bin/cdktn`.

### Cleanup

```sh
brew uninstall cdktn
brew untap open-constructs/tap
```

## Contributing

Version bumps, bug reports, and PRs welcome.

### Version bump recipe

When a new `cdktn-cli` is published on npm:

```sh
# 1. Get the new tarball URL and its SHA256.
NEW_VERSION=$(npm view cdktn-cli@latest version)
curl -sL "https://registry.npmjs.org/cdktn-cli/-/cdktn-cli-${NEW_VERSION}.tgz" | shasum -a 256

# 2. Edit Formula/cdktn.rb — update `url` (the version number) and `sha256` to match.

# 3. Re-tap locally (Option B from "Testing locally" above), then:
brew audit --new --strict --online open-constructs/tap/cdktn
brew uninstall cdktn 2>/dev/null || true
brew install open-constructs/tap/cdktn
cdktn --version   # should print $NEW_VERSION
brew test open-constructs/tap/cdktn

# 4. Commit with message: "feat(cdktn): bump to <version>"
```

Things to watch for on a bump:
- **New transitive prebuilds.** If `brew audit` complains about non-native binaries other than the already-pruned `bare-*` set, extend the prune glob in `Formula/cdktn.rb`.
- **Node major bumps.** The formula pins `node@20`; if upstream moves to a newer LTS, update the `depends_on` and the `write_env_script` PATH.
- **`cdktf` → `cdktn` env-var renames.** cdktn currently honors `TERRAFORM_BINARY_NAME` (and other `CDKTF_*` vars) for CDKTF compatibility. If upstream adds `CDKTN_*` aliases, mention them in the runtime section above.

Please run the audit and both install paths before opening a PR.
