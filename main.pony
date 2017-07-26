use "files"
use "options"

actor Main
  new create(env: Env) =>
    // TODO use the new cli package
    // https://github.com/ponylang/ponyc/issues/1737
    let options = Options(env.args)
      .>add("edit", "e", None)

    try
      var edit = false
      for option in options do
        match option
        | ("edit", None) => edit = true
        | let err: ParseError =>
          err.report(env.err)
          error
        end
      end

      let args = Array[String]
      for arg in options.remaining().values() do
        args.push(arg.clone())
      end

      let filename = args(2)?
      let filepath =
        try
          FilePath(env.root as AmbientAuth, filename)?
        else
          env.err.print("unable to open: " + filename)
          return
        end
      let tool = ChangelogTool(env, filename, filepath)

      match args(1)?
      | "verify" => tool.verify()
      | "release" => tool.release(args(3)?, edit)
      | "unreleased" => tool.unreleased(edit)
      else error
      end
    else
      env.out.print(
        """
        changelog-tool COMMAND <changelog file> [...]

        Commands:
          verify       Verify that the given changelog is valid.
          release      Print a changelog that is prepared for release.
                       Example: `changelog-tool release CHANGELOG.md 0.13.1`
          unreleased   Add unreleased section to changelog if none exists.

        Options:
          --edit, -e   Edit the changelog file (release and unreleased only).
        """)
    end
