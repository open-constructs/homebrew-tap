# open-constructs/homebrew-tap

Homebrew tap for [Open Constructs](https://github.com/open-constructs) projects.

## Note for reviewers

**This tap repository does not exist on GitHub yet** — `https://github.com/open-constructs/homebrew-tap` returns 404 as of 2026-04-20. Before users can run the `brew tap` / `brew install` commands below, someone with org permissions needs to:

1. Create the `open-constructs/homebrew-tap` repo on GitHub (public, MIT or Apache-2.0 LICENSE, the `Formula/` directory at repo root).
2. Push `Formula/cdktn.rb` and this `README.md` to its default branch.
3. Verify `brew tap open-constructs/tap` resolves (Homebrew strips the `homebrew-` prefix when mapping tap names to repos).

The formula itself has been locally audit-clean (`brew audit --new --strict --online`) and install-verified against a temporary local tap. The content in this directory is a working copy ready to push.

## Install

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

**Stable** (`brew install cdktn`): installs the prebuilt [`cdktn-cli`](https://www.npmjs.com/package/cdktn-cli) npm tarball — ~400 MB, ~30 sec.

**Bleeding-edge** (`brew install --HEAD cdktn`): builds from the `cdk-terrain` main branch via `yarn build` (full monorepo, tsc + jsii) — ~1.5 GB, ~2 min.

### Runtime: Terraform or OpenTofu

`cdktn` shells out to a Terraform-compatible binary. Homebrew's core `terraform` formula was removed after Hashicorp relicensed it (BSL, August 2023), so this tap does not pin a choice — install whichever you prefer:

```sh
brew install hashicorp/tap/terraform   # upstream Terraform (BSL)
# — or —
brew install opentofu                  # OpenTofu (MPL-2.0) — community fork
```

If you use OpenTofu, tell cdktn to invoke the `tofu` binary:

```sh
export TERRAFORM_BINARY_NAME=tofu
```

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
You have a stale global npm install of `cdktn-cli` (or the placeholder package published to npm). Remove it with:

```sh
npm uninstall -g cdktn-cli
```

Then re-run `brew link cdktn`.

**Install size feels large for a CLI.** The stable (npm) path is ~400 MB and the `--HEAD` path is ~1.5 GB. Both ship the CLI's runtime `node_modules` because the CLI is a partial esbuild bundle that loads several dependencies (`cdktn`, `@cdktn/hcl2cdk`, `constructs`, `yargs`, ...) at runtime rather than inlining them.

## Testing locally from the tap source

To iterate on a formula change without pushing to GitHub, point Homebrew at a local clone of this repo:

```sh
git clone https://github.com/open-constructs/homebrew-tap.git
cd homebrew-tap

# Register this working copy as the `open-constructs/tap` tap.
# (If the tap is already tapped from GitHub, untap first: `brew untap open-constructs/tap`)
brew tap open-constructs/tap "$(pwd)"
```

Now `open-constructs/tap/cdktn` resolves to `./Formula/cdktn.rb` in your working copy. Edits to the file are picked up immediately — no commit, no push.

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

Builds from `github.com/open-constructs/cdk-terrain` `main`. Expect ~2 min and ~1.5 GB on disk.

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

Version bumps, bug reports, and PRs welcome. Please run the audit and both install paths above before opening a PR.
