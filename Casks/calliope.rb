cask "calliope" do
  version "0.1.0"
  sha256 "d3c139d6cb27adaf9ed1f0df1fa02da9000d848d89b22a29b523b0e2b955278c"

  url "https://github.com/gabrielbelli/calliope/releases/download/v#{version}/calliope-#{version}-arm64.tar.gz"
  name "Calliope"
  desc "Read any selection aloud on your own Mac, with a floating reader"
  homepage "https://github.com/gabrielbelli/calliope"

  # The capsule is NSGlassEffectView, which arrives in macOS 26. Declared
  # rather than discovered: without this the app installs and then refuses to
  # open, and LaunchServices says only "-10825".
  depends_on macos: ">= :tahoe"
  depends_on arch: :arm64

  app "Calliope.app"

  postflight do
    # AD-HOC SIGNED, SO THE QUARANTINE FLAG HAS TO GO. Nothing here is
    # notarised: the app is built on the machine that uses it and signed with
    # an ad-hoc identity, which macOS accepts for running and refuses for
    # distributing. brew marks every download com.apple.quarantine, and
    # Gatekeeper reads that flag on first launch -- so left on, it is the
    # "Apple could not verify" wall, and Homebrew 7 removed --no-quarantine as
    # an escape. Same treatment as the jailmachine cask in this tap.
    if system_command("/usr/bin/xattr", args: ["-h"]).exit_status == 0
      system_command "/usr/bin/xattr",
                     args: ["-dr", "com.apple.quarantine", "#{appdir}/Calliope.app"]
    end
    # TELL LAUNCHSERVICES IT EXISTS. Measured: until it knows, SMAppService
    # reports notFound for an app sitting in /Applications, so Settings' "Open
    # at login" reads as off and cannot be turned on. Moving a bundle into
    # place is not something it notices on its own.
    lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/" \
                 "LaunchServices.framework/Support/lsregister"
    system_command lsregister, args: ["-f", "#{appdir}/Calliope.app"] if File.executable?(lsregister)
  end

  uninstall quit:       "com.gabrielbelli.calliope",
            launchctl:  "com.gabrielbelli.calliope"

  # The runtime directory is logs, the spoken-text queue and a pid file; an
  # install.sh install also left a 337 MB model there. The preferences hold the
  # speed, the reader setting and the Calliope server's address.
  #
  # NOT THE KEYCHAIN. `zap` deletes files, and a credential is not a file --
  # com.gabrielbelli.calliope / calliope-server is removed in Keychain Access
  # if you want it gone.
  zap trash: [
    "~/.local/share/calliope",
    "~/.openclip/extensions/calliope.openclipext",
    "~/Library/Preferences/com.gabrielbelli.calliope-player.plist",
    "~/Library/Preferences/com.gabrielbelli.calliope.plist",
  ]

  caveats <<~EOS
    Open it once — there is no window and no Dock icon, just a menu bar item:

      open -g /Applications/Calliope.app

    Then select text anywhere and press Option-Command-S.

    The first press asks for Accessibility permission. There is no way to read
    another application's selection without it, and the app does nothing until
    you agree. macOS grants that permission to a particular copy of a program,
    so an upgrade asks again.

    Everything runs on this Mac: the model is inside the app, 82M parameters on
    the CPU, faster than realtime. Menu bar icon → Settings… can point it at a
    Calliope server as well, for engines this Mac has no business running —
    cloned voices, long documents, transcription. Leaving that switch off is
    the whole of the privacy story.
  EOS
end
