cask "calliope" do
  version "0.1.1"
  sha256 "362b7696a6aa7bfc42f77f18db175862a84adc1575b70610faf461b05e5be785"

  url "https://github.com/gabrielbelli/calliope/releases/download/v#{version}/calliope-#{version}-arm64.tar.gz"
  name "Calliope"
  desc "Reads selected text aloud locally, in a floating reader"
  homepage "https://github.com/gabrielbelli/calliope"

  depends_on arch: :arm64
  # The capsule is NSGlassEffectView, which arrives in macOS 26. Declared
  # rather than discovered: without this the app installs and then refuses to
  # open, and LaunchServices says only "-10825".
  depends_on macos: :tahoe

  app "Calliope.app"

  # postflight_steps, not postflight: Homebrew 7 renamed the stanza and the old
  # name now fails `brew style`. The block takes install-step DSL calls only --
  # no arbitrary Ruby -- so the two things that have to happen are `run` calls.
  # jailmachine.rb in this tap still uses the old name; it is GoReleaser output
  # and changes when GoReleaser does.
  postflight_steps do
    # AD-HOC SIGNED, SO THE QUARANTINE FLAG HAS TO GO. Nothing here is
    # notarised: the app is built on the machine that uses it and signed with
    # an ad-hoc identity, which macOS accepts for running and refuses for
    # distributing. brew marks every download com.apple.quarantine and
    # Gatekeeper reads that flag on first launch -- so left on, it is the
    # "Apple could not verify" wall, and Homebrew 7 removed --no-quarantine as
    # an escape. Same treatment as jailmachine in this tap.
    run "/usr/bin/xattr",
        args: ["-dr", "com.apple.quarantine", "{{appdir}}/Calliope.app"]

    # TELL LAUNCHSERVICES IT EXISTS. Measured: until it knows, SMAppService
    # reports notFound for an app sitting in /Applications, so Settings' "Open
    # at login" reads as off and cannot be turned on. Moving a bundle into
    # place is not something it notices on its own. Guarded because the path is
    # undocumented and has moved between releases before.
    #
    # must_succeed: false, AND THIS FAILED A REAL INSTALL. lsregister answered
    # -10822 -- "failed to scan ... from spotlight" -- and because the step was
    # fatal, Homebrew tore down an upgrade that had already put a working app
    # in place. A convenience is not worth an install: without this the
    # checkbox reads as off until macOS notices the app by itself, which it
    # does the first time somebody opens it.
    if_path_exists "/System/Library/Frameworks/CoreServices.framework/Frameworks/" \
                   "LaunchServices.framework/Support/lsregister" do
      run "/System/Library/Frameworks/CoreServices.framework/Frameworks/" \
          "LaunchServices.framework/Support/lsregister",
          args:         ["-f", "{{appdir}}/Calliope.app"],
          must_succeed: false
    end
  end

  # quit only. SMAppService registers the login item under a label it
  # generates -- application.com.gabrielbelli.calliope.<hash> -- not under the
  # bundle identifier, so a launchctl stanza naming the identifier would match
  # nothing and read as though it did. Removing the app is what unregisters it.
  uninstall quit: "com.gabrielbelli.calliope"

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
