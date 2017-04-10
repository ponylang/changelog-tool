use ".deps/sylvanc/peg"

/*
1. have a part that can validate a changelog file

2. have a part that can remove entries after validating

we want to use part 1 when CI runs

to not allow “invalid” changelogs through

because otherwise removal will go boom

also

look now our CHANGELOG is a langauge
  
lulz
*/

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
          L("## [unreleased] - unreleased")
        else
          (L("## [") * version() * L("] - ") * date()).term()
        end

      heading * -L("\n").many1()
        * section("Fixed").opt()
        * section("Added").opt()
        * section("Changed").opt()
    end

  fun section(title: String): Parser val =>
    recover
      let heading = (L("### ") * L(title)).term()
      heading * -L("\n\n") * entry().many() * -L("\n").many1()
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

primitive TVersion is Label fun text(): String => "Version"
primitive TDate is Label fun text(): String => "Date"
primitive TEntry is Label fun text(): String => "Entry"
