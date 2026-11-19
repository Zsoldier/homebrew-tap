# Distributes a pre-built, Developer ID-signed, NOTARIZED .app (the menu bar app),
# while compiling the unsigned CLI + CoreAudio detector from source. Do NOT
# re-sign the downloaded .app — that would strip the notarization ticket.
class MicMusicPause < Formula
  desc "Pause Apple Music while your microphone is in use, then resume"
  homepage "https://github.com/Zsoldier/mic-music-pause"
  version "0.10.1"
  url "https://github.com/Zsoldier/mic-music-pause/archive/refs/tags/v0.10.1.tar.gz"
  sha256 "63af1ce0ce43258d1e6160f9655ff60fa436d4c4490e7d9c6ff123ecf6168abf"
  license "MIT"
  head "https://github.com/Zsoldier/mic-music-pause.git", branch: "main"

  depends_on :macos

  resource "app" do
    url "https://github.com/Zsoldier/mic-music-pause/releases/download/v0.10.1/mic-music-pause-0.10.1-macos.tar.gz"
    sha256 "e21d5c0a5f7cc243d6f39220cbc4e88ff6e4d23a93358669cc2b34a5147871b6"
  end

  def install
    # Unsigned pieces compiled from source (no signature required).
    system "xcrun", "swiftc", "-O", "-o", "micstate", "src/micstate.swift"
    libexec.install "micstate"
    bin.install "bin/mic-music-pause"

    # Install the pre-built, Developer ID-signed, notarized .app AS-IS.
    resource("app").stage do
      libexec.install "mic-music-pause.app"
    end

    (bin/"mic-music-pause-menubar").write <<~SH
      #!/bin/bash
      exec "#{opt_libexec}/mic-music-pause.app/Contents/MacOS/mic-music-pause-menubar" "$@"
    SH
    (bin/"mic-music-pause-menubar").chmod 0755
  end

  def caveats
    <<~EOS
      mic-music-pause is a menu bar app. Launch it now with:
        open "#{opt_libexec}/mic-music-pause.app"

      Then click its menu bar icon and enable "Start at login" so it launches
      automatically when you log in.
    EOS
  end

  test do
    assert_match "mic-music-pause", shell_output("#{bin}/mic-music-pause help")
    assert_predicate libexec/"micstate", :executable?
    assert_predicate libexec/"mic-music-pause.app/Contents/MacOS/mic-music-pause-menubar", :executable?
    # Verify the shipped app is properly signed & notarized (ticket stapled).
    system "/usr/bin/codesign", "--verify", "--strict", libexec/"mic-music-pause.app"
    system "/usr/bin/stapler", "validate", libexec/"mic-music-pause.app"
  end
end
