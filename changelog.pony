use "peg"

class Changelog
  let heading: String
  var unreleased: (Release | None)
  embed released: Array[Release]

  new create(ast: AST) ? =>
    let children = ast.children.values()
    released = Array[Release]

    heading = (children.next()? as Token).string()
    if ast.size() > 1 then
      unreleased = try Release(children.next()? as AST)? end
      for child in children do
        released.push(Release(child as AST)?)
      end
    else
      unreleased = None
    end

  fun ref create_release(version: String, date: String) ? =>
    match unreleased
    | let r: Release =>
      r.heading = "## [" + version + "] - " + date

      if (r.fixed as Section).entries == "" then
        r.fixed = None
      end
      if (r.added as Section).entries == "" then
        r.added = None
      end
      if (r.changed as Section).entries == "" then
        r.changed = None
      end
    else
      this
    end

  fun ref create_unreleased() =>
    if unreleased is None then
      unreleased = Release._unreleased()
    end

  fun string(): String iso^ =>
    let str = (recover String end)
      .> append(heading)
      .> append("\n")
    if unreleased isnt None then str.append(unreleased.string()) end
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
    let t = ast.children(0)? as Token
    heading = t.source.content.trim(t.offset, t.offset + t.length)
    fixed = try Section(ast.children(1)? as AST)? else None end
    added = try Section(ast.children(2)? as AST)? else None end
    changed = try Section(ast.children(3)? as AST)? else None end

  new _unreleased() =>
    heading = "## [unreleased] - unreleased"
    fixed = Section._empty(Fixed)
    added = Section._empty(Added)
    changed = Section._empty(Changed)

  fun string(): String iso^ =>
    let str = recover String .> append(heading) .> append("\n\n") end
    for section in [fixed; added; changed].values() do
      match section
      | let s: this->Section =>
        str .> append(s.string()) .> append("\n\n")
      end
    end
    str

class Section
  let label: TSection
  let entries: String

  new create(ast: AST) ? =>
    label = (ast.children(0)? as Token).label() as TSection
    entries =
      try
        let t = ast.children(1)? as Token
        t.source.content.trim(t.offset, t.offset + t.length)
      else
        ""
      end

  new _empty(label': TSection) =>
    (label, entries) = (label', "")

  fun is_empty(): Bool => entries == ""

  fun string(): String =>
    recover
      String
        .> append("### ")
        .> append(label.text())
        .> append("\n\n")
        .> append(entries)
    end
