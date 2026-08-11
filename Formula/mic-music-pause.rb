# Distributes a pre-built, Developer ID-signed, NOTARIZED .app (the menu bar app),
# while compiling the unsigned CLI + CoreAudio detector from source. Do NOT
# re-sign the downloaded .app — that would strip the notarization ticket.
class MicMusicPause < Formula
  desc "Pause Apple Music while your microphone is in use, then resume"
  homepage "https://github.com/Zsoldier/mic-music-pause"
  version "0.9.0"
  url "https://github.com/Zsoldier/mic-music-pause/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "2032e07db96bdf59328dba1fa9c7d62732695a95065cc00b6e4a1199caf17d40"
  license "MIT"
  head "https://github.com/Zsoldier/mic-music-pause.git", branch: "main"

  depends_on :macos

  resource "app" do
    url "https://github.com/Zsoldier/mic-music-pause/releases/download/v0.9.0/mic-music-pause-0.9.0-macos.tar.gz"
    sha256 "4d97ba8b8025da65adf999c4aee32bf5fbbe67d16fc7fa82ac394453d899bedd"
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
