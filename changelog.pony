use ".deps/sylvanc/peg"

class Changelog
  let unreleased: Release
  embed released: Array[Release]

  new create(ast: AST) ? =>
    unreleased = Release(ast.extract() as AST)
    released = Array[Release](ast.size() - 1)
    for child in (ast.children(1) as AST).children.values() do
      released.push(Release(child as AST))
    end

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
  let heading: String
  let fixed: (Section | None)
  let added: (Section | None)
  let changed: (Section | None)

  new create(ast: AST) ? =>
    let t = ast.children(0) as Token
    heading = t.source.trim(t.offset, t.offset + t.length)
    fixed = try Section(ast.children(1) as AST) else None end
    added = try Section(ast.children(2) as AST) else None end
    changed = try Section(ast.children(3) as AST) else None end

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
    label = (ast.children(0) as Token).label as TSection
    entries =
      try
        let t = ast.children(1) as Token
        t.source.trim(t.offset, t.offset + t.length)
      else
        ""
      end

  fun is_empty(): Bool => entries == ""

  fun string(): String =>
    recover
      String
        .>append("### ")
        .>append(label.text())
        .>append("\n\n")
        .>append(entries)
    end
