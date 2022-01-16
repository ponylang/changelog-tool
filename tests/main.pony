use "collections"
use "files"
use "peg"
use "ponytest"
use "../changelog-tool"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestParseVersion)
    test(_TestParseDate)
    test(_TestParseEntries)
    test(_TestParseHead)
    test(_TestParseChangelog)
    test(_TestRelease)

class iso _TestParseVersion is UnitTest
  fun name(): String => "parse version"

  fun apply(h: TestHelper) =>
    ParseTest(h, ChangelogParser.version()).run(
      [ ("0.0.0", "$(Version$0.0.0)")
        ("0.0", "$(Version$0.0)")
        ("1.23.9", "$(Version$1.23.9)")
        ("1.23", "$(Version$1.23)")
        ("0..0", "")
        (".0.0", "")
        ("0..", "")
        ("0", "")
      ])

class iso _TestParseDate is UnitTest
  fun name(): String => "parse date"

  fun apply(h: TestHelper) =>
    ParseTest(h, ChangelogParser.date()).run(
      [ ("2017-04-07", "$(Date$2017-04-07)")
        ("0000-00-00", "$(Date$0000-00-00)")
        ("0000-00-0", "")
        ("0000-0-00", "")
        ("000-00-00", "")
        ("00-0000-00", "")
      ])

class iso _TestParseEntries is UnitTest
  fun name(): String => "parse entries"

  fun apply(h: TestHelper) =>
    ParseTest(h, ChangelogParser.entries()).run(
      [ ("32-bit ARM port.", "")
        ( "- 32-bit ARM port.\n",
          "$(Entries$(Entry$- 32-bit ARM port.\n))" )
        ("- abc\n  - def\n\n", "$(Entries$(Entry$- abc\n  - def\n))")
        ( """
          - abc
            * def
              - ghi

            - jkl
          """,
          "$(Entries$(Entry$- abc\n  * def\n    - ghi\n))" )
        ( "- @fowles: handle regex empty match.\n",
          "$(Entries$(Entry$- @fowles: handle regex empty match.\n))" )
        ( "- Upgrade to LLVM 3.9.1 ([PR #1498](https://github.com/ponylang/ponyc/pull/1498))\n",
          "$(Entries$(Entry$- Upgrade to LLVM 3.9.1 ([PR #1498](https://github.com/ponylang/ponyc/pull/1498))\n))" )
        ( """
          * stuff

          * things



          - more things

          #
          """,
          "$(Entries$(Entry$* stuff\n)$(Entry$* things\n)$(Entry$- more things\n))"
        )
      ])

class iso _TestParseHead is UnitTest
  fun name(): String => "parse head"

  fun apply(h: TestHelper) =>
    ParseTest(h, ChangelogParser.head()).run(
      [ ( """
          # Change Log

          All notable changes to the Pony compiler and standard library will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).
          """,
          "$($All notable changes to the Pony compiler and standard library will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).)"
        )
        ( """
          # Change Log

          Some other text

          ## [unreleased] - unreleased
          """,
          "$($Some other text)"
        )
        ( """
          # Change Log

          Some other text that contains: `## [unreleased] - unreleased`

          ## [unreleased] - unreleased
          """,
          "$($Some other text that contains: `## [unreleased] - unreleased`)"
        )
        ( """
          # Change Log


          ## [unreleased] - unreleased
          """,
          "$()"
        )
        ( """
          # Change Log

          ## [unreleased] - unreleased
          """,
          "$()"
        )
      ])

class iso _TestParseChangelog is UnitTest
  fun name(): String => "parse CHANGELOG"

  fun apply(h: TestHelper) ? =>
    let p = recover val ChangelogParser() end
    let testfile = "CHANGELOG.md"

    with file = OpenFile(
      FilePath(h.env.root, testfile)) as File
    do
      let source: String = file.read_string(file.size())
      let source' = Source.from_string(source)
      match recover val p.parse(source') end
      | (let n: USize, let r: (AST | Token | NotPresent)) =>
        match r
        | let ast: AST =>
          let changelog = Changelog(ast)?
          h.assert_eq[String](source, changelog.string())
        else
          h.log(recover val _Printer(r) end)
          h.fail()
        end
      | (let offset: USize, let r: Parser val) =>
        let e = recover val SyntaxError(source', offset, r) end
        _Logv(h, PegFormatError.console(e))
        h.fail()
      end
    else
      h.fail()
    end

class iso _TestRelease is UnitTest
  fun name(): String => "release"

  fun apply(h: TestHelper) ? =>
    _ReleaseTest(h, ChangelogParser()).run(
      """
      # Change Log

      ## [unreleased] - unreleased

      ### Fixed

      - Fix invalid separator in PONYPATH for Windows. ([PR #32](https://github.com/ponylang/pony-stable/pull/32))

      ### Added


      ### Changed


      """,
      """
      # Change Log

      ## [0.0.0] - 0000-00-00

      ### Fixed

      - Fix invalid separator in PONYPATH for Windows. ([PR #32](https://github.com/ponylang/pony-stable/pull/32))

      """)?

    _ReleaseTest(h, ChangelogParser()).run(
      """
      # Change Log

      ## [unreleased] - unreleased

      ### Fixed

      - abc

      - def

      ### Added



      ### Changed

      ## [1.2.3] - 9999-99-99

      ### Added

      - yup

      """,
      """
      # Change Log

      ## [0.0.0] - 0000-00-00

      ### Fixed

      - abc
      - def

      ## [1.2.3] - 9999-99-99

      ### Added

      - yup

      """)?

    _ReleaseTestAfterAddingSomeEntries(h, ChangelogParser()).run(
      """
      # Change Log

      ## [unreleased] - unreleased

      ### Fixed

      ### Added

      ### Changed

      """,
      """
      # Change Log

      ## [0.0.0] - 0000-00-00

      ### Fixed

      - We made some fixes...
      - Oh, and we made a final one.

      ### Added

      - We added some stuff as well.

      ### Changed

      - And we changed a few things also.

      """)?

class ParseTest
  let _h: TestHelper
  let _parser: Parser

  new create(h: TestHelper, parser: Parser) =>
    (_h, _parser) = (h, parser)

  fun run(tests: Array[(String, String)]) =>
    for (source, expected) in tests.values() do
      _h.log("test: " + source)
      let source' = Source.from_string(source)
      match recover val _parser.parse(source') end
      | (_, let r: (AST | Token | NotPresent)) =>
        let result = recover val _Printer(r) end
        _h.log(recover Printer(r) end)
        _h.assert_eq[String](expected, result)
      | (let offset: USize, let r: Parser val) =>
        let e = recover val SyntaxError(source', offset, r) end
        _Logv(_h, PegFormatError.console(e))
        _h.assert_eq[String](expected, "")
      | (_, Skipped) => _h.log("skipped")
      | (_, Lex) => _h.log("lex")
      end
    end

class _ReleaseTest
  let _h: TestHelper
  let _parser: Parser

  new create(h: TestHelper, parser: Parser) =>
    (_h, _parser) = (h, parser)

  fun run(input: String, expected: String) ? =>
    let source = Source.from_string(input)
    match recover val _parser.parse(source) end
    | (let n: USize, let r: (AST | Token | NotPresent)) =>
      match r
      | let ast: AST =>
        _h.log(recover val _Printer(ast) end)
        // _h.log(Changelog(ast)?.string())
        let changelog = Changelog(ast)? .> create_release("0.0.0", "0000-00-00")
        let output: String = changelog.string()
        _h.log(output)
        _h.assert_eq[String](expected, output)
      else
        _h.log(recover val _Printer(r) end)
        _h.fail()
      end
    | (let offset: USize, let r: Parser val) =>
      let e = recover val SyntaxError(source, offset, r) end
      _Logv(_h, PegFormatError.console(e))
      _h.fail()
    end

class _ReleaseTestAfterAddingSomeEntries
  let _h: TestHelper
  let _parser: Parser

  new create(h: TestHelper, parser: Parser) =>
    (_h, _parser) = (h, parser)

  fun run(input: String, expected: String) ? =>
    let source = Source.from_string(input)
    match recover val _parser.parse(source) end
    | (let n: USize, let r: (AST | Token | NotPresent)) =>
      match r
      | let ast: AST =>
        _h.log(recover val _Printer(ast) end)
        let changelog = Changelog(ast)?
          .> add_entry("fixed", "We made some fixes...\n")?
          .> add_entry("fixed", "Oh, and we made a final one.\n")?
          .> add_entry("added", "We added some stuff as well.\n")?
          .> add_entry("changed", "And we changed a few things also.\n")?
          .> create_release("0.0.0", "0000-00-00")
        let output: String = changelog.string()
        _h.log(output)
        _h.assert_eq[String](expected, output)
      else
        _h.log(recover val _Printer(r) end)
        _h.fail()
      end
    | (let offset: USize, let r: Parser val) =>
      let e = recover val SyntaxError(source, offset, r) end
      _Logv(_h, PegFormatError.console(e))
      _h.fail()
    end

primitive _Logv
  fun apply(h: TestHelper, bsi: ByteSeqIter) =>
    let str = recover String end
    for bs in bsi.values() do
      str.append(
        match bs
        | let s: String => s
        | let a: Array[U8] val => String.from_array(a)
        end)
    end
    h.log(consume str)

primitive _Printer
  fun apply(p: ASTChild, depth: USize = 0, indent: String = "  ",
    s: String ref = String): String ref
  =>
    s.append("$(")
    s.append(p.label().text())

    match p
    | let ast: AST =>
      for child in ast.children.values() do
        _Printer(child, depth + 1, indent, s)
      end
    | let token: Token =>
      s.append("$")
      s.append(token.source.content, token.offset, token.length)
    end
    s.append(")")
    s
