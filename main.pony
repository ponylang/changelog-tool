use "files"
use "options"
use "time"
use ".deps/sylvanc/peg"

/*
1. have a part that can validate a changelog file

2. have a part that can remove entries after validating

we want to use part 1 when CI runs

to not allow “invalid” changelogs through

because otherwise removal will go boom

also

look now our CHANGELOG is a langauge
  
lulz
*/

actor Main
  let _env: Env
  var _filename: String = ""

  new create(env: Env) =>
    _env = env
    // TODO use the new cli package
    // https://github.com/ponylang/ponyc/issues/1737
    let options = Options(_env.args)
      .>add("edit", "e", None)

    try
      var edit = false
      for option in options do
        match option
        | ("edit", None) => edit = true
        | let err: ParseError =>
          err.report(_env.err)
          error
        end
      end

      let args = Array[String]
      for arg in options.remaining().values() do
        args.push(arg.clone())
      end

      _filename = args(2)
      match args(1)
      | "verify" => verify()
      | "release" => release(args(3), edit)
      else error
      end
    else
      _env.out.print(
        """
        changelog-tool COMMAND <changelog file> [...]

        Commands:
          verify       Verify that the given changelog is valid.
          release      Print a changelog that is prepared for release.
                       Example: `changelog-tool release CHANGELOG.md 0.13.1`

        Options:
          --edit, -e   Edit the changelog file (release only).
        """)
      return
    end

  fun verify() =>
    _env.out.print("verifying " + _filename + "...")
    try
      let ast = parse()
      _env.out.print(_filename + " is a valid changelog")
    end

  fun release(version: String, edit: Bool) =>
    try
      check_version(version)
      let ast = parse()
      let date = Date(Time.seconds()).format("%Y-%m-%d")
      let changelog = Changelog(ast)
        .create_release(version, date)
      let changelog_str: String = changelog.string()

      if edit then
        with
          file = File(FilePath(_env.root as AmbientAuth, _filename))
        do
          file
            .>write(changelog_str)
            .>flush()
        end
      else
        _env.out.print(changelog_str)
      end
    else
      _env.err.print("unable to perform release prep")
    end

  fun check_version(version: String) ? =>
    // chack if version is valid
    match ChangelogParser.version().parse(version)
    | (_, let t: Token) => None
    else
      _env.err.print("invalid version number: '" + version + "'")
      error
    end

  fun parse(): AST ? =>
    with
      file = OpenFile(FilePath(_env.root as AmbientAuth, _filename)) as File
    do
      let source: String = file.read_string(file.size())
      match ChangelogParser().eof().parse(source, 0, true, NoParser)
      | (_, let ast: AST) =>
        //_env.out.print(recover val Printer(ast) end)
        ast
      | (let offset: USize, let r: Parser) =>
        _env.err.writev(
          Error(_filename, source, offset, "SYNTAX", r.error_msg()))
        error
      else
        _env.err.print("unable to parse file: " + _filename)
        error
      end
    else
      _env.err.print("unable to open: " + _filename)
      error
    end
