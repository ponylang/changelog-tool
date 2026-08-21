use "itertools"
use "peg"

class Changelog
  """
  A parsed changelog with an optional unreleased section and a list of
  releases.
  """

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
      unreleased =
        match try children.next()? as AST end
        | let child: AST =>
          if _IsUnreleased(child) then
            Unreleased .> fill_ast(child)?
          end
        end
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
  """
  The unreleased section of a changelog, containing fixed, added, and
  changed subsections.
  """

  let heading: String = "## [unreleased] - unreleased"
  var fixed: Section
  var added: Section
  var changed: Section

  new create() =>
    fixed = Section._empty(Fixed)
    added = Section._empty(Added)
    changed = Section._empty(Changed)

  fun ref fill_ast(ast: AST) ?
  =>
    """
    Populate fixed, added, and changed sections from a parsed AST.
    """
    if (ast.children(0)? as Token).string() != heading then error end
    match _ParseSection(ast, 1)?
    | let s: Section => fixed = s
    end
    match _ParseSection(ast, 2)?
    | let s: Section => added = s
    end
    match _ParseSection(ast, 3)?
    | let s: Section => changed = s
    end

  fun ref add_entry(section_name: String, entry: String) ? =>
    _ValidatePRCount(entry)?
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

  fun ref release(heading': String): Release^
  =>
    """
    Convert this unreleased section into a release with the given
    heading.
    """
    let rel = Release._empty(heading')
    if not fixed.is_empty() then rel.fixed = fixed end
    if not added.is_empty() then rel.added = added end
    if not changed.is_empty() then rel.changed = changed end
    rel

  fun string(): String iso^ =>
    Releases.show(heading, [fixed; added; changed].values())

class Release
  """
  A single versioned release entry with optional Fixed, Added, and
  Changed sections.
  """

  var heading: String
  var fixed: (Section | None)
  var added: (Section | None)
  var changed: (Section | None)

  new create(ast: AST) ? =>
    heading = (ast.children(0)? as Token).string()
    fixed = _ParseSection(ast, 1)?
    added = _ParseSection(ast, 2)?
    changed = _ParseSection(ast, 3)?

  new _empty(heading': String) =>
    heading = heading'
    fixed = None
    added = None
    changed = None

  fun string(): String iso^ =>
    Releases.show(heading, [fixed; added; changed].values())

primitive Releases
  """
  Renders a release heading followed by its sections as a string.
  """

  fun show(
    heading: String,
    sections: Iterator[(Section box | None)])
    : String iso^
  =>
    "\n".join(
      [heading; ""]
        .> concat(Iter[(Section box | None)](sections)
          .filter_map[String]({(s)? => (s as Section box).string() }))
        .> push("")
        .values())

class Section
  """
  A changelog subsection (Fixed, Added, or Changed) containing a
  list of entries.
  """

  let label: TSection
  embed entries: Array[String]

  new create(ast: AST) ? =>
    label = (ast.children(0)? as Token).label() as TSection
    match try ast.children(1)? as AST end
    | let es: AST =>
      entries = Array[String](es.size())
      for entry in es.children.values() do
        let s: String val = try (entry as Token).string() else error end
        _ValidatePRCount(s)?
        entries.push(s)
      end
    else
      entries = Array[String]
    end

  new _empty(label': TSection) =>
    (label, entries) = (label', Array[String])

  fun is_empty(): Bool => entries.size() == 0

  fun string(): String iso^ =>
    "".join(
      [ "### "; label.text(); "\n\n"
        "".join(entries.values())
      ].values())

primitive _ParseSection
  fun apply(ast: AST, index: USize): (Section | None) ? =>
    match try ast.children(index)? end
    | let child: AST => Section(child)?
    else
      None
    end

primitive _ValidatePRCount
  fun apply(s: String box) ? =>
    let lower: String val = s.lower()
    let total = lower.count("[pr #") + lower.count("[pr#")
    if (total > 1) or (total > s.count("[PR #")) then error end

primitive _IsUnreleased
  fun apply(ast: AST): Bool =>
    try
      (ast.children(0)? as Token).string() == Unreleased.heading
    else
      false
    end
