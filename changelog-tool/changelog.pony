use "peg"

class Changelog
  let heading: String
  var unreleased: (Release | None)
  embed released: Array[Release]

  new empty(heading': String) =>
    heading = heading'
    unreleased = None
    released = []

  new create(ast: AST) ? =>
    let children = ast.children.values()
    released = Array[Release]

    heading =
      if children.has_next() then
        match children.next()?
        | let t: Token => t.string()
        | NotPresent => ""
        else error
        end
      else
        ""
      end

    if ast.size() > 1 then
      unreleased = try Release(children.next()? as AST)? end
      for child in children do
        released.push(Release(child as AST)?)
      end
    else
      unreleased = None
    end

  fun ref create_release(version: String, date: String) =>
    match unreleased
    | let r: Release =>
      r.heading = "## [" + version + "] - " + date
    end

  fun ref create_unreleased() =>
    if unreleased is None then
      unreleased = Release._unreleased()
    end

  fun ref add_entry(section_name: String, entry: String) ? =>
    match unreleased
    | let r: Release => r.add_entry(section_name, entry)?
    end

  fun string(): String iso^ =>
    let str = (recover String end)
      .> append("# Change Log\n\n")
    if heading != "" then
      str
        .> append(heading)
        .> append("\n\n")
    end
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

  let _unreleased_heading: String = "## [unreleased] - unreleased"

  new create(ast: AST) ? =>
    heading = (ast.children(0)? as Token).string()
    fixed = try Section(ast.children(1)? as AST)? else None end
    added = try Section(ast.children(2)? as AST)? else None end
    changed = try Section(ast.children(3)? as AST)? else None end

  new _unreleased() =>
    heading = _unreleased_heading
    fixed = Section._empty(Fixed)
    added = Section._empty(Added)
    changed = Section._empty(Changed)

  fun ref add_entry(section_name: String, entry: String) ? =>
    let section =
      match section_name
      | "fixed" =>
        if fixed is None then fixed = Section._empty(Fixed) end
        fixed as Section
      | "added" =>
        if added is None then added = Section._empty(Added) end
        added as Section
      | "changed" =>
        if changed is None then changed = Section._empty(Changed) end
        changed as Section
      else error
      end
    section.entries.push("- " + entry)

  fun string(): String iso^ =>
    // In order to represent the empty sections of unreleased releases,
    // we must use the empty correspoding section when printing instead
    // of None, otherwise it will be ignored.
    let fixed' =
      match fixed
        | None if heading == _unreleased_heading => Section._empty(Fixed)
      else fixed
      end

    let added' =
      match added
    |   None if heading == _unreleased_heading => Section._empty(Added)
      else added
      end

    let changed' =
      match changed
      | None if heading == _unreleased_heading => Section._empty(Changed)
      else changed
      end

    let str = recover String .> append(heading) .> append("\n\n") end
    for section in [fixed'; added'; changed'].values() do
      match section
      | let s: Section box =>
        str .> append(s.string()) .> append("\n")
      end
    end
    str

class Section
  let label: TSection
  embed entries: Array[String]

  new create(ast: AST) ? =>
    label = (ast.children(0)? as Token).label() as TSection
    let es = ast.children(1)? as AST
    entries = Array[String](es.size())

    for entry in es.children.values() do
      try entries.push((entry as Token).string()) end
    end

  new _empty(label': TSection) =>
    (label, entries) = (label', Array[String])

  fun is_empty(): Bool => entries.size() == 0

  fun string(): String =>
    let entries' = recover String end
    for entry in entries.values() do
      entries'.append(entry)
    end
    recover
      String
        .> append("### ")
        .> append(label.text())
        .> append("\n\n")
        .> append(consume entries')
    end
