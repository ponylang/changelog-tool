use "files"
use "itertools"

actor Main
  let help_text: String =
    """
    changelog-tool COMMAND <changelog file> [...]

    Commands:
      verify       Verify that the given changelog is valid.
      release      Print a changelog that is prepared for release.
                   Example: `changelog-tool release CHANGELOG.md 0.13.1`
      unreleased   Add unreleased section to changelog if none exists.

    Options:
      --edit, -e   Edit the changelog file (release and unreleased only).
    """

  new create(env: Env) =>
    // TODO use the cli package

    (let cmd, let filename) =
      try (env.args(1)?, env.args(2)?)
      else
        env.out.print(help_text)
        return
      end

    let filepath =
      try
        FilePath(env.root as AmbientAuth, filename)?
      else
        env.out.print("unable to open: " + filename)
        env.exitcode(1)
        return
      end
    let tool = ChangelogTool(env, filename, filepath)

    var edit = false
    for arg in Iter[String](env.args.values()).skip(3) do
      if (arg == "-e") or (arg == "--edit") then
        edit = true
        break
      end
    end

    match cmd
    | "verify" =>
      env.out.print("Verifying " + filename + "...")
      try
        tool.verify()?
        env.out.print(filename + " is a valid changelog.")
      else
        env.out.print(filename + " is not a valid changelog.")
        env.exitcode(1)
        return
      end
    | "release" =>
      let version =
        try env.args(3)?
        else
          env.out.print("A release version must be provided.")
          env.exitcode(1)
          return
        end
      try tool.release(version, edit)?
      else
        env.out.print("Unable to perform release prep.")
        env.exitcode(1)
        return
      end
    | "unreleased" => tool.unreleased(edit)
    else
      env.out.print(help_text)
      env.exitcode(1)
      return
    end
