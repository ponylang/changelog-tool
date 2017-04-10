use ".deps/sylvanc/peg"

primitive ChangelogParser
  fun apply(): Parser val =>
    recover
      let heading = L(
        """
        # Change Log

        All notable changes to the Pony compiler and standard library will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).
        """)
      
      heading * -L("\n").many1() * release(false) * release().many()
    end

  fun release(released: Bool = true): Parser val =>
    recover
      let heading = 
        if not released then
          L("## [unreleased] - unreleased").term(TUnreleased)
        else
          (L("## [") * version() * L("] - ") * date()).term()
        end

      heading * -L("\n").many1()
        * section[Fixed](released).opt()
        * section[Added](released).opt()
        * section[Changed](released).opt()
    end

  fun section[S: Section](released: Bool): Parser val =>
    recover
      let heading = (L("### ") * L(S.text())).term(S)
      let entries =
        if released then entry().many1()
        else entry().many() // allow empty sections in unreleased
        end
      heading * -L("\n\n") * entries * -L("\n").many1()
    end

  fun version(): Parser val =>
    recover
      let frac = L(".") * digits()
      (digits() * frac * frac).term(TVersion)
    end

  fun date(): Parser val =>
    recover
      let digits4 = digit() * digit() * digit() * digit()
      let digits2 = digit() * digit()
      (digits4 * L("-") * digits2 * L("-") * digits2).term(TDate)
    end

  fun entry(): Parser val =>
    recover
      let chars = R(' ').many1()
      (L("- ") * chars * (L("\n") * chars).many()).term(TEntry)
    end

  fun digits(): Parser val => recover digit().many1() end

  fun digit(): Parser val => recover R('0', '9') end

primitive TUnreleased is Label fun text(): String => "Unreleased"

trait Section is Label
primitive Fixed is Section fun text(): String => "Fixed"
primitive Added is Section fun text(): String => "Added"
primitive Changed is Section fun text(): String => "Changed"

primitive TVersion is Label fun text(): String => "Version"
primitive TDate is Label fun text(): String => "Date"
primitive TEntry is Label fun text(): String => "Entry"
