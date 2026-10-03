cask "earshot" do
  version "1.0.0"
  sha256 "701626d914e65fd7f2cbc4fcf05168bae90330bbf3c4719fe66da16a36642d67"

  url "https://github.com/gabrielbelli/earshot/releases/download/v#{version}/earshot-#{version}.zip"
  name "Earshot"
  desc "Headset battery, settings and audio switching in the menu bar"
  homepage "https://github.com/gabrielbelli/earshot"

  depends_on macos: :sonoma

  app "Earshot.app"

  # Same two steps as calliope.rb, which explains both at length: the app is ad-hoc signed, so the
  # quarantine flag has to go or Gatekeeper refuses it, and LaunchServices has to know the app
  # exists before SMAppService will turn on Open at Login.
  postflight_steps do
    run "/usr/bin/xattr",
        args: ["-dr", "com.apple.quarantine", "{{appdir}}/Earshot.app"]

    if_path_exists "/System/Library/Frameworks/CoreServices.framework/Frameworks/" \
                   "LaunchServices.framework/Support/lsregister" do
      run "/System/Library/Frameworks/CoreServices.framework/Frameworks/" \
          "LaunchServices.framework/Support/lsregister",
          args:         ["-f", "{{appdir}}/Earshot.app"],
          must_succeed: false
    end
  end

  uninstall quit: "com.gabrielbelli.Earshot"

  zap trash: "~/Library/Preferences/com.gabrielbelli.Earshot.plist"
end
