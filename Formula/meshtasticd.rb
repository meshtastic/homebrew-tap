class Meshtasticd < Formula
  desc "Meshtastic Node software for MacOS"
  homepage "https://github.com/meshtastic/firmware"
  # Use a commit hash from `master` where MacOS support is present.
  url "https://github.com/meshtastic/firmware/archive/9c72767c0133361131f27ca039455a81ec8d4a1e.tar.gz"
  version "2.7.23"
  sha256 "c0fa5e88ab038e3b98b64eb5c8c7c45e2b724055d45cb98eea4bc194a7ab50ed"
  license "GPL-3.0-only"
  # Update 'revision' when making changes so that updates work correctly.
  # Remove when bumping 'version'.
  revision 4
  head "https://github.com/meshtastic/firmware.git", branch: "master"

  bottle do
    root_url "https://github.com/meshtastic/homebrew-tap/releases/download/meshtasticd-2.7.23_3"
    sha256 cellar: :any, arm64_tahoe:   "f7098771d0d4db02bba161838fe701be9130e0ddd483472421413b4834f1f3d5"
    sha256 cellar: :any, arm64_sequoia: "9172c5129db87b808e33d2e7f3ebf688664e144b7c8655579ccd0563cac379f1"
  end

  depends_on "pkgconf" => :build
  depends_on "platformio" => :build
  depends_on "argp-standalone"
  depends_on "libusb"
  depends_on "libuv"
  # Only support MacOS 15+
  depends_on macos: :sequoia
  depends_on "openssl@3"
  depends_on "yaml-cpp"

  def install
    ENV["PLATFORMIO_CORE_DIR"] = buildpath/".platformio"
    ENV["PLATFORMIO_SETTING_ENABLE_TELEMETRY"] = "0"
    ENV["PLATFORMIO_SETTING_CHECK_PLATFORMIO_INTERVAL"] = "3650"
    ENV["PLATFORMIO_SETTING_CHECK_PRUNE_SYSTEM_THRESHOLD"] = "10240"
    system "platformio", "run", "-e", "native-macos"
    bin.install ".pio/build/native-macos/meshtasticd"
    (var/"lib/meshtasticd").mkpath
    (pkgetc/"available.d").mkpath
    (pkgetc/"available.d").install Dir["bin/config.d/*"]
    (pkgetc/"config.d").mkpath
    inreplace "bin/config-dist.yaml", "/etc/meshtasticd", pkgetc
    pkgetc.install "bin/config-dist.yaml" => "config.yaml"
  end

  service do
    run [opt_bin/"meshtasticd", "--config", etc/"meshtasticd/config.yaml", "--fsdir", var/"lib/meshtasticd"]
    keep_alive true
    log_path var/"log/meshtasticd.log"
    error_log_path var/"log/meshtasticd.log"
  end

  # The test will check if meshtasticd can be executed.
  # It will also check if the version is correctly displayed.
  test do
    assert_match version.to_s, shell_output("#{bin}/meshtasticd --version")
  end
end
