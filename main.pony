use "files"
use "options"
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
    let options = Options(_env.args)
      .> add("verify", "v", None, Optional)
      .> add("release", "r", None, Optional)

    _filename =
      try
        _env.args(1)
      else
        usage()
        return
      end

    (var f_verify, var f_release) = (false, false)

    for option in options do
      match option
      | ("verify", None) => f_verify = true
      | ("release", None) => f_release = true
      | let e: ParseError =>
        e.report(_env.out)
        usage()
        return
      end
    end

    if not (f_verify or f_release) then usage() end
    if f_verify then verify() end
    if f_release then release() end

  fun usage() =>
    print(
      """
      changelog-tools <changelog file> [OPTIONS]

      Options:
        --verify, -v     Verify that the changelog is valid.
      """)

  fun verify() =>
    print("verifying " + _filename + "...")

    try
      let ast = parse()
      print(_filename + " is a valid changelog")
    end

  fun release() =>
    try
      let ast = parse()
      let changelog = Changelog(ast)
      print(changelog.string())
    end

  fun parse(): AST ? =>
    with
      file = OpenFile(FilePath(_env.root as AmbientAuth, _filename)) as File
    do
      let source: String = file.read_string(file.size())
      match ChangelogParser().eof().parse(source)
      | (let n: USize, let ast': AST) =>
        //_env.out.print(recover val Printer(ast') end)
        ast'
      | (let offset: USize, let r: Parser) =>
        print(String.join(Error(_filename, source, offset, r)))
        error
      else
        print("unable to parse file: " + _filename)
        error
      end
    else
      print("unable to open: " + _filename)
      error
    end

  fun print(str: String) => _env.out.print(str)
