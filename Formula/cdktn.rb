class Cdktn < Formula
  desc "CDK Terrain CLI (community fork of CDK for Terraform)"
  homepage "https://github.com/open-constructs/cdk-terrain"
  url "https://registry.npmjs.org/cdktn-cli/-/cdktn-cli-0.22.1.tgz"
  sha256 "8affd7a0ea66fc9fc6f38684d6cac077ef468541f881b23f3b6a2dcf4380a519"
  license "MPL-2.0"

  head "https://github.com/open-constructs/cdk-terrain.git", branch: "main"

  depends_on "yarn" => :build
  depends_on "node@20"

  def install
    if build.head?
      # Source build from cdk-terrain main. Mirrors what upstream's release
      # pipeline does: yarn install, full-workspace build (tsc + jsii), then
      # ship the monorepo so the CLI's partial esbuild bundle can resolve its
      # externals (cdktn core, @cdktn/hcl2cdk, etc.) from node_modules.
      system "yarn", "install", "--frozen-lockfile"

      # Upstream keeps "version": "0.0.0" in source; lerna bumps it only at
      # publish time. Inject the formula version so `cdktn --version` matches.
      inreplace "packages/cdktn-cli/package.json",
                /"version":\s*"0\.0\.0"/,
                "\"version\": \"#{version}\""

      system "yarn", "build"

      libexec.install "node_modules", "packages", "package.json", "yarn.lock"
      (bin/"cdktn").write_env_script libexec/"packages/cdktn-cli/bundle/bin/cdktn",
        PATH: "#{Formula["node@20"].opt_bin}:$PATH"
    else
      # Stable: install the prebuilt cdktn-cli npm package into libexec and
      # symlink its bin entrypoint into the formula's bin.
      system "npm", "install", *std_npm_args
      bin.install_symlink libexec.glob("bin/*")

      # Prune non-native prebuilds from bare-* transitive deps (holepunch
      # runtime, shipped via an indirect dep). brew audit --strict rejects
      # the foreign-arch .bare binaries inside an arm64/x86_64 install, and
      # the cdktn CLI never exercises them.
      os_arch = "#{OS.mac? ? "darwin" : "linux"}-#{Hardware::CPU.arm? ? "arm64" : "x64"}"
      libexec.glob("lib/node_modules/*/node_modules/bare-*/prebuilds/*").each do |d|
        d.rmtree if d.directory? && d.basename.to_s != os_arch
      end
    end
  end

  def caveats
    <<~EOS
      cdktn shells out to a Terraform-compatible binary at runtime. Homebrew's
      core `terraform` formula was removed after Hashicorp relicensed it (BSL,
      August 2023), so this formula does not force a choice. Install one of:

        brew install hashicorp/tap/terraform   # upstream Terraform (BSL)
        brew install opentofu                  # OpenTofu (MPL-2.0) — open-source fork

      If you use OpenTofu, point cdktn at the `tofu` binary:
        export TERRAFORM_BINARY_NAME=tofu

      On first use, `cdktn init` may download additional language toolchains
      (Python, Go, Java, .NET) depending on the target language of your project.

      For a bleeding-edge build from the cdk-terrain main branch:
        brew install --HEAD open-constructs/tap/cdktn
    EOS
  end

  test do
    system bin/"cdktn", "--help"
    assert_match version.to_s, shell_output("#{bin}/cdktn --version") if build.stable?
  end
end
