use ".deps/sylvanc/peg"

class Changelog
  let unreleased: Release
  let released: Array[Release]

  new create(ast: AST) ? =>
    let children = ast.children.values()
    unreleased = Release(children.next() as AST)
    released = Array[Release](ast.size() - 1)
    for child in children do
      released.push(Release(child as AST))
    end

  new _create(unreleased': Release, released': Array[Release]) =>
    (unreleased, released) = (unreleased', released')

  fun ref create_release(version: String, date: String): Changelog^ ? =>
    unreleased.heading = "## [" + version + "] - " + date

    if (unreleased.fixed as Section).entries == "" then
      unreleased.fixed = None
    end
    if (unreleased.added as Section).entries == "" then
      unreleased.added = None
    end
    if (unreleased.changed as Section).entries == "" then
      unreleased.changed = None
    end

    _create(Release._unreleased(), released.>unshift(unreleased))

  fun string(): String iso^ =>
    let str = (recover String end)
      .>append(_Util.changelog_heading())
      .>append("\n")
      .>append(unreleased.string())
    for release in released.values() do
      str.append(release.string())
    end
    str

class Release
  var heading: String
  var fixed: (Section | None)
  var added: (Section | None)
  var changed: (Section | None)

  new create(ast: AST) ? =>
    let t = ast.children(0) as Token
    heading = t.source.trim(t.offset, t.offset + t.length)
    fixed = try Section(ast.children(1) as AST) else None end
    added = try Section(ast.children(2) as AST) else None end
    changed = try Section(ast.children(3) as AST) else None end

  new _unreleased() =>
    heading = "## [unreleased] - unreleased"
    fixed = Section._emtpy(Fixed)
    added = Section._emtpy(Added)
    changed = Section._emtpy(Changed)

  fun string(): String iso^ =>
    let str = recover String.>append(heading).>append("\n\n") end
    for section in [fixed; added; changed].values() do
      match section
      | let s: this->Section =>
        str.>append(s.string()).>append("\n\n")
      end
    end
    str

class Section
  let label: TSection
  let entries: String

  new create(ast: AST) ? =>
    label = (ast.children(0) as Token).label() as TSection
    entries =
      try
        let t = ast.children(1) as Token
        t.source.trim(t.offset, t.offset + t.length)
      else
        ""
      end

  new _emtpy(label': TSection) =>
    (label, entries) = (label', "")

  fun is_empty(): Bool => entries == ""

  fun string(): String =>
    recover
      String
        .>append("### ")
        .>append(label.text())
        .>append("\n\n")
        .>append(entries)
    end
