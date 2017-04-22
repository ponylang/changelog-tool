use "files"
use "time"
use ".deps/sylvanc/peg"

class ChangelogTool
  let _env: Env
  let _filename: String
  let _filepath: FilePath

  new create(env: Env, filename: String, filepath: FilePath) =>
    (_env, _filename, _filepath) = (env, filename, filepath)

  fun verify() =>
    _env.out.print("verifying " + _filename + "...")
    try
      let ast = _parse()
      _env.out.print(_filename + " is a valid changelog")
    end

  fun release(version: String, edit: Bool) =>
    try
      _check_version(version)
      let date = Date(Time.seconds()).format("%Y-%m-%d")
      let changelog: String = Changelog(_parse())
        .create_release(version, date)
        .string()
      _edit_or_print(edit, changelog)
    else
      _env.err.print("unable to perform release prep")
    end

  fun _check_version(version: String) ? =>
    // chack if version is valid
    let source = Source.from_string(version)
    match recover val ChangelogParser.version().parse(source) end
    | (_, let t: Token) => None
    else
      _env.err.print("invalid version number: '" + version + "'")
      error
    end

  fun unreleased(edit: Bool) =>
    try
      let changelog: String = Changelog(_parse())
        .create_unreleased()
        .string()
      _edit_or_print(edit, changelog)
    else
      _env.out.print("error")
    end

  fun _edit_or_print(edit: Bool, s: String) =>
    if edit then
      with file = File(_filepath) do
        file
          .>write(s)
          .>flush()
      end
    else
      _env.out.print(s)
    end

  fun _parse(): AST ? =>
    let source = Source(FilePath(_env.root as AmbientAuth, _filename))
    match recover val ChangelogParser().parse(source) end
    | (_, let ast: AST) =>
      //_env.out.print(recover val Printer(ast) end)
      ast
    | (let offset: USize, let r: Parser val) =>
      let e = recover val SyntaxError(source, offset, r) end
      _env.err.writev(PegFormatError.console(e))
      error
    else
      _env.err.print("unable to parse file: " + _filename)
      error
    end
