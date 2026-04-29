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
  revision 5
  head "https://github.com/meshtastic/firmware.git", branch: "master"

  bottle do
    root_url "https://github.com/meshtastic/homebrew-tap/releases/download/meshtasticd-2.7.23_4"
    sha256 cellar: :any, arm64_tahoe:   "62233042fd73a7d111ff418309d80e1d5868c449a30c879ea4c7f6517e3e7548"
    sha256 cellar: :any, arm64_sequoia: "ef4e95cf9292448d11ed53182a19dd15fedc85aeac18c4f30b285067fc3d497e"
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

  resource "web" do
    url "https://github.com/meshtastic/web/releases/download/v2.6.7/build.tar"
    sha256 "a34f4360a0486543a698de20de533557492e763ab459fc27fcea95d0495144ed"
  end

  def install
    ENV["PLATFORMIO_CORE_DIR"] = buildpath/".platformio"
    ENV["PLATFORMIO_SETTING_ENABLE_TELEMETRY"] = "0"
    ENV["PLATFORMIO_SETTING_CHECK_PLATFORMIO_INTERVAL"] = "3650"
    ENV["PLATFORMIO_SETTING_CHECK_PRUNE_SYSTEM_THRESHOLD"] = "10240"
    system "platformio", "run", "-e", "native-macos"
    bin.install ".pio/build/native-macos/meshtasticd"
    (var/"lib/meshtasticd").mkpath
    (pkgetc/"config.d").mkpath
    (pkgetc/"available.d").mkpath
    (pkgetc/"available.d").install Dir["bin/config.d/*"]
    (pkgshare/"web").mkpath
    resource("web").stage do
      system "gzip", "-dr", "."
      (pkgshare/"web").install Dir["*"]
    end
    inreplace "bin/config-dist.yaml" do |s|
      s.gsub! "/etc/meshtasticd", pkgetc
      s.gsub! "/usr/share/meshtasticd", pkgshare
      s.gsub! "/var/log", var/"log"
    end
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
