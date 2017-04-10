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
  var _verify: Bool = false

  new create(env: Env) =>
    _env = env
    let options = Options(_env.args)
      .> add("verify", "v", None, Optional)
      // TODO remove empty sections from unreleased, create new unreleased section (release)

    _filename =
      try _env.args(1)
      else usage(); return
      end

    for option in options do
      match option
      | ("verify", None) => _verify = true
      | let e: ParseError => e.report(_env.out); usage()
      end
    end

    if _verify then verify()
    else usage()
    end

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
      check_unreleased(ast)
      print(_filename + " is a valid changelog")
    end

  fun parse(): AST ? =>
    with
      file =
        try
          OpenFile(FilePath(_env.root as AmbientAuth, _filename)) as File
        else
          print("unable to open: " + _filename)
          error
        end
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
    else error
    end

  fun check_unreleased(ast: AST) ? =>
    // check that there is an unreleased section
    try
      (unreleased(ast).children(0) as Token).label as TUnreleased
    else
      print("no unreleased section found")
      error
    end

  fun unreleased(ast: AST): AST ? => ast.children(1) as AST

  fun print(str: String) => _env.out.print(str)
