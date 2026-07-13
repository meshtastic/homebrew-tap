class Meshtasticd < Formula
  desc "Meshtastic Daemon-Node for MacOS"
  homepage "https://github.com/meshtastic/firmware"
  url "https://github.com/meshtastic/firmware/archive/refs/tags/v2.7.26.54e0d8d.tar.gz"
  version "2.7.26"
  sha256 "78eb9769a5c8b9646110ef37a5f19a453ce94848ff7ee77e366cf17217a2be78"
  license "GPL-3.0-only"
  # Update 'revision' when making changes so that updates work correctly.
  # Remove when bumping 'version'.
  head "https://github.com/meshtastic/firmware.git", branch: "master"

  bottle do
    root_url "https://github.com/meshtastic/homebrew-tap/releases/download/meshtasticd-2.7.23_8"
    sha256 cellar: :any, arm64_tahoe:   "5b1a8bb44e303e6fb9aa208ec8834d8ef71e90023860067c7cad4e4f88bc41fe"
    sha256 cellar: :any, arm64_sequoia: "c10d795014dc518ebb94a16935d3d6d811674df0260c7f41e3004ebc2fb90347"
  end

  depends_on "pkgconf" => :build
  depends_on "platformio" => :build
  depends_on "argp-standalone"
  depends_on "libusb"
  depends_on "libuv"
  # Only support MacOS 15+
  depends_on macos: :sequoia
  depends_on "openssl@3"
  depends_on "orcania"
  depends_on "ulfius"
  depends_on "yaml-cpp"
  depends_on "yder"

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
    (pkgetc/"ssl").mkpath
    (pkgshare/"web").mkpath
    resource("web").stage do
      system "gzip", "-dr", "."
      (pkgshare/"web").install Dir["*"]
    end
    inreplace "bin/config-dist.yaml" do |s|
      s.gsub! "/etc/meshtasticd", pkgetc
      s.gsub! "/usr/share/meshtasticd", "#{HOMEBREW_PREFIX}/share/meshtasticd"
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
