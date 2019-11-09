use "itertools"
use "peg"

class Changelog
  let heading: String
  var unreleased: (Unreleased | None)
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
      unreleased = try Unreleased .> fill_ast(children.next()? as AST)? end
      for child in children do
        released.push(Release(child as AST)?)
      end
    else
      unreleased = None
    end

  fun ref create_release(version: String, date: String) =>
    match unreleased
    | let u: Unreleased =>
      released.unshift(u.release(
        "".join(["## ["; version; "] - "; date].values())))
      unreleased = None
      None
    end

  fun ref create_unreleased() =>
    if unreleased is None then
      unreleased = Unreleased
    end

  fun ref add_entry(section_name: String, entry: String) ? =>
    match unreleased
    | let u: Unreleased => u.add_entry(section_name, entry)?
    end

  fun string(): String iso^ =>
    "".join(
      [ "# Change Log\n\n"
        if heading == "" then "" else "".join([heading; "\n\n"].values()) end
        if unreleased is None then "" else unreleased end
        "".join(released.values())
      ].values())

class Unreleased
  let heading: String = "## [unreleased] - unreleased"
  var fixed: Section
  var added: Section
  var changed: Section

  new create() =>
    fixed = Section._empty(Fixed)
    added = Section._empty(Added)
    changed = Section._empty(Changed)

  fun ref fill_ast(ast: AST) ? =>
    if (ast.children(0)? as Token).string() != heading then error end
    try fixed = Section(ast.children(1)? as AST)? end
    try added = Section(ast.children(2)? as AST)? end
    try changed = Section(ast.children(3)? as AST)? end

  fun ref add_entry(section_name: String, entry: String) ? =>
    let section =
      match section_name
      | "fixed" => fixed
      | "added" => added
      | "changed" => changed
      else error
      end
    section.entries.push("".join(
      [ "- "; entry
        if entry.substring(-1) == "\n" then "" else "\n" end
      ].values()))

  fun ref release(heading': String): Release^ =>
    let rel = Release._empty(heading')
    if not fixed.is_empty() then rel.fixed = fixed end
    if not added.is_empty() then rel.added = added end
    if not changed.is_empty() then rel.changed = changed end
    rel

  fun string(): String iso^ =>
    Releases.show(heading, [fixed; added; changed].values())

class Release
  var heading: String
  var fixed: (Section | None)
  var added: (Section | None)
  var changed: (Section | None)

  new create(ast: AST) ? =>
    heading = (ast.children(0)? as Token).string()
    fixed = try Section(ast.children(1)? as AST)? else None end
    added = try Section(ast.children(2)? as AST)? else None end
    changed = try Section(ast.children(3)? as AST)? else None end

  new _empty(heading': String) =>
    heading = heading'
    fixed = None
    added = None
    changed = None

  fun string(): String iso^ =>
    Releases.show(heading, [fixed; added; changed].values())

primitive Releases
  fun show(heading: String, sections: Iterator[(Section box | None)])
    : String iso^
  =>
    "\n".join(
      [heading; ""]
        .> concat(Iter[(Section box | None)](sections)
          .filter_map[String]({(s)? => (s as Section box).string() }))
        .> push("")
        .values())

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

  fun string(): String iso^ =>
    "".join(
      [ "### "; label.text(); "\n\n"
        "".join(entries.values())
      ].values())
