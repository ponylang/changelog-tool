use "cli"
use "files"
use peg = "peg"
use "time"

primitive Info
  fun version(): String => Version()
  fun default_filename(): String => "CHANGELOG.md"
  fun project_repo(): String => "https://github.com/ponylang/changelog-tool"

  fun default_heading(): String =>
    " ".join(
      [ "All notable changes to this project will be documented in this file."
        "This project adheres to [Semantic Versioning](http://semver.org/)"
        "and [Keep a CHANGELOG](http://keepachangelog.com/)."
      ].values())

actor Main
  let _env: Env

  new create(env: Env) =>
    _env = consume env

    try
      match CommandParser(spec()?).parse(_env.args, _env.vars)
      | let c: Command => run(_env.root, c)
      | let h: CommandHelp => print(h.help_string())
      | let e: SyntaxError =>
        print(e.string())
        _env.exitcode(1)
      end
    else
      err("invalid command spec")
      please_report()
    end

  fun spec(): CommandSpec ? =>
    let edit = OptionSpec.bool("edit", "Modify the changelog file", 'e', false)
    CommandSpec.parent(
      "changelog-tool",
      "",
      [ OptionSpec.string(
        "file", "Path of the changelog", 'f', Info.default_filename())
      ],
      [ CommandSpec.leaf("version", "Show the version and exit")?
        CommandSpec.leaf("new", "Create an new, empty changelog")?
        CommandSpec.leaf("verify", "Verify that a changelog is valid")?
        CommandSpec.leaf(
          "get",
          "Print the changelog sections for a selected release",
          [],
          [ArgSpec.string("selection")])?
        CommandSpec.leaf(
          "unreleased",
          "Add unreleased section to changelog if none exists",
          [edit])?
        CommandSpec.leaf(
          "release",
          " ".join(
            [ "Print a changelog that is prepared for release."
              "e.g. `changelog-tool release 0.13.1`"
            ].values()),
          [edit],
          [ArgSpec.string("version")])?
	CommandSpec.leaf(
	  "add",
	  "Add a new entry at the end of the section",
	  [edit],
	  [ ArgSpec.string("section")
      ArgSpec.string("entry")
	  ])?
      ])?
      .> add_help("help", "Print this message and exit")?

  fun run(auth: AmbientAuth, cmd: Command) =>
    var filename = cmd.option("file").string()
    if filename == "" then filename = Info.default_filename() end
    let path = FilePath(auth, filename)

    match cmd.fullname()
    | "changelog-tool/version" => print("changelog-tool " + Info.version())
    | "changelog-tool/new" => cmd_new(path, filename)
    | "changelog-tool/verify" => cmd_verify(path, filename)
    | "changelog-tool/get" =>
      cmd_get(path, filename, cmd.arg("selection").string())
    | "changelog-tool/unreleased" =>
      cmd_unreleased(path, filename, cmd.option("edit").bool())
    | "changelog-tool/release" =>
      cmd_release(
        path, filename, cmd.arg("version").string(), cmd.option("edit").bool())
    | "changelog-tool/add" =>
      cmd_add(
        path, filename, cmd.arg("section").string(),
        cmd.arg("entry").string(),cmd.option("edit").bool())
    else
      err("unknown command: " + cmd.fullname())
      please_report()
    end

  fun cmd_new(filepath: FilePath, filename: String) =>
    if filepath.exists() then
      err(filename + " already exists")
      return
    end

    let file = File(filepath)
    file.write(Changelog.empty(Info.default_heading()).string())

  fun cmd_verify(filepath: FilePath, filename: String) =>
    try
      Changelog(parse(filepath, filename)?)?
      print(filename + " is a valid changelog.")
    else
      err(filename + " is not a valid changelog.")
    end

  fun cmd_get(filepath: FilePath, filename: String, selection: String) =>
    let changelog =
      try
        Changelog(parse(filepath, filename)?)?
      else
        err(filename + " is not a valid changelog.")
        return
      end

    match changelog.unreleased
    | let u: Unreleased =>
      if u.heading.contains(selection) then
        print(u.string())
        return
      end
    end

    for release in changelog.released.values() do
      if release.heading.contains(selection) then
        print(release.string())
        return
      end
    end

    err("\"" + selection + "\" was not found in any changelog release headings")

  fun cmd_unreleased(filepath: FilePath, filename: String, edit: Bool) =>
    try
      edit_or_print(
        filepath,
        edit,
        Changelog(parse(filepath, filename)?)?
          .> create_unreleased()
          .string())
    else
      err("unable to construct changelog from input")
    end

  fun cmd_release(
    filepath: FilePath,
    filename: String,
    version: String,
    edit: Bool)
  =>
    try
      check_version(version)?
      let date = PosixDate(Time.seconds()).format("%Y-%m-%d")?
      edit_or_print(
        filepath,
        edit,
        Changelog(parse(filepath, filename)?)?
          .> create_release(version, date)
          .string())
    else
      err("unable to perform release preparation")
    end

  fun cmd_add(
    filepath: FilePath,
    filename: String,
    section: String,
    entry: String,
    edit: Bool)
  =>
    try
      edit_or_print(
        filepath,
        edit,
        Changelog(parse(filepath, filename)?)?
          .> create_unreleased()
          .> add_entry(section, entry)?
          .string())
    else
      err("unable add a new changelog entry")
    end

  fun parse(filepath: FilePath, filename: String): peg.AST ? =>
    let source = peg.Source(filepath)?
    match recover val ChangelogParser().parse(source) end
    | (_, let ast: peg.AST) =>
      ast
    | (let offset: USize, let r: peg.Parser val) =>
      let e = recover val peg.SyntaxError(source, offset, r) end
      _env.out.writev(peg.PegFormatError.console(e))
      error
    else
      err("unable to parse file: " + filename)
      error
    end

  fun edit_or_print(filepath: FilePath, edit: Bool, s: String) =>
    if edit then
      File(filepath)
        .> set_length(0)
        .> write(s)
        .> flush()
    else
      print(s)
    end

  fun check_version(version: String) ? =>
    let source = peg.Source.from_string(version)
    match recover val ChangelogParser.version().parse(source) end
    | (_, let _: peg.Token) => None
    else
      err("invalid version: '" + version + "'")
      error
    end

  fun print(message: String) =>
    _env.out.print(message)

  fun err(message: String) =>
    _env.exitcode(1)
    print("error: " + message)

  fun please_report() =>
    print("Please open an issue at " + Info.project_repo())
