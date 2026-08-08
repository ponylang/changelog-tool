use "peg"

trait val TSection is Label
  """
  A changelog section label (Fixed, Added, or Changed).
  """

primitive Fixed is TSection
  """
  Fixed section label.
  """
  fun text(): String => "Fixed"

primitive Added is TSection
  """
  Added section label.
  """
  fun text(): String => "Added"

primitive Changed is TSection
  """
  Changed section label.
  """
  fun text(): String => "Changed"

primitive TRelease is Label
  """
  Release AST node label.
  """
  fun text(): String => "Release"

primitive TVersion is Label
  """
  Version AST node label.
  """
  fun text(): String => "Version"

primitive TDate is Label
  """
  Date AST node label.
  """
  fun text(): String => "Date"

primitive TEntries is Label
  """
  Entries AST node label.
  """
  fun text(): String => "Entries"

primitive TEntry is Label
  """
  Entry AST node label.
  """
  fun text(): String => "Entry"
