class ClaudeStatusline < Formula
  desc "Status line for Claude Code showing account, profile, git, MCP and usage"
  homepage "https://github.com/gabrielbelli/claude-statusline"
  url "https://github.com/gabrielbelli/claude-statusline/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "365a6bc1cd5530a9b3b12bea9ebd64f26b214da9303fdae91ce4ed92f4421639"
  license "BSD-2-Clause"
  head "https://github.com/gabrielbelli/claude-statusline.git", branch: "master"

  # jq is a hard dependency: the script parses Claude Code's status line JSON
  # on stdin. git and docker are optional — those segments skip themselves when
  # the tool is absent, so they are deliberately not declared here.
  depends_on "jq"

  def install
    # Installed under a name you can type, so settings.json says
    # "claude-statusline" rather than an absolute path into a clone. A path
    # breaks the moment the repo moves; a command on PATH does not.
    bin.install "statusline.sh" => "claude-statusline"
    pkgshare.install "claude-statusline.conf.example"
    doc.install "README.md"
  end

  def caveats
    <<~EOS
      Point Claude Code at it by adding this to ~/.claude/settings.json:

        "statusLine": { "type": "command", "command": "claude-statusline" }

      Optional configuration — every value in it is the current default, so
      copying it changes nothing and you edit from a known-good file:

        cp #{opt_pkgshare}/claude-statusline.conf.example \\
           ~/.config/claude-statusline.conf

      The account, profile and telemetry segments report on claudio:

        brew install gabrielbelli/tap/claudio
    EOS
  end

  test do
    # Feeds the script the same shape Claude Code sends on stdin. Asserting on
    # the model name keeps the test independent of the machine: the directory,
    # git and account segments all vary by where it runs, and a test that
    # depends on the runner's home directory is a test that fails in CI.
    json = '{"workspace":{"current_dir":"/tmp"},"model":{"display_name":"Opus 5"}}'
    output = pipe_output(bin/"claude-statusline", json, 0)
    assert_match "Opus 5", output

    # Every segment is meant to be self-guarding, so empty input must still
    # produce a line and exit 0 rather than erroring.
    pipe_output(bin/"claude-statusline", "{}", 0)
  end
end
