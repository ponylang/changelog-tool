use "debug"
use "files"
use "peg"
use "time"

class ChangelogTool
  let _env: Env
  let _filename: String
  let _filepath: FilePath

  new create(env: Env, filename: String, filepath: FilePath) =>
    (_env, _filename, _filepath) = (env, filename, filepath)

  fun verify() ? =>
    let ast = _parse()?
    let changelog = Changelog(ast)?
    Debug(recover Printer(ast) end)
    Debug(changelog.string())

  fun release(version: String, edit: Bool) ? =>
    _check_version(version)?
    let date = PosixDate(Time.seconds()).format("%Y-%m-%d")?
    let changelog: String =
      Changelog(_parse()?)?
        .> create_release(version, date)
        .string()
    _edit_or_print(edit, changelog)

  fun _check_version(version: String) ? =>
    let source = Source.from_string(version)
    match recover val ChangelogParser.version().parse(source) end
    | (_, let t: Token) => None
    else
      _env.out.print("invalid version number: '" + version + "'")
      _env.exitcode(1)
      error
    end

  fun unreleased(edit: Bool) =>
    try
      let changelog: String =
        Changelog(_parse()?)?
          .> create_unreleased()
          .string()
      _edit_or_print(edit, changelog)
    else
      _env.out.print("error")
    end

  fun _edit_or_print(edit: Bool, s: String) =>
    if edit then
      with file = File(_filepath) do
        file
          .> set_length(0)
          .> write(s)
          .> flush()
      end
    else
      _env.out.print(s)
    end

  fun _parse(): AST ? =>
    let source = Source(FilePath(_env.root as AmbientAuth, _filename)?)?
    match recover val ChangelogParser().parse(source) end
    | (_, let ast: AST) =>
      // _env.out.print(recover val Printer(ast) end)
      ast
    | (let offset: USize, let r: Parser val) =>
      let e = recover val SyntaxError(source, offset, r) end
      _env.out.writev(PegFormatError.console(e))
      _env.exitcode(1)
      error
    else
      _env.out.print("unable to parse file: " + _filename)
      _env.exitcode(1)
      error
    end
