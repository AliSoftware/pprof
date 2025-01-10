# CHANGELOG

This file lists the changes for various versions of the `pprof` gem.

## 1.0.0

* Add support Mac Profiles (`*.provisionprofile`) alongside the already-supported iOS Profiles (`*.mobileprovision`).
* Add `--platform` filter to only list profiles that support a given platform (`OSX`, `iOS`, …)

## 0.5.1

* Fix an issue with `-j`/`--json` when used with list mode, so that it can now take `-c` and `-d` flags into account to include (or not) the certificates and devices in the JSON output list mode.

## 0.5.0

* Add support for printing the output and profiles info as JSON using `-j`/`--json`.
* Fix an issue with `-l`/`--list` which were printing the path instead of the UUID.

## 0.4.1

* Lower the minimum ruby version required for the gem (was accidentally bumped in previous version, while we don't strictly really require a higher one for the gem to work)

## 0.4.0

* Make the output of `-c` (printing certificates in a provisioning profile) more verbose,
  especially to include certificate serial number and expiration date.
* Modernized the ruby codebase a bit, configuring and fixing rubocop violations.

## 0.3.9

* Fix the case when the PKCS7 payload parsed with the OpenSSL gem is _empty_,
  by using the same fallback to `security cms` which was introduced in 0.3.7

## 0.3.8

* Improved help banner (`pprof -h`) with notes and tips.

## 0.3.7

* Fix case when the parsing of the PKCS7 payload fails using the OpenSSL payload
  (which seems to happen on some Provisioning Profile files and with High Sierra)
  to fallback to using `security cms` when OpenSSL fails.

## 0.3.6

* Now catching errors when parsing a provisioning profile file and printing the error(s) at the end of the output.

## 0.3.5

* Added `--team` filter to filter by team or team ID.
* Removed one-char flags for filters to avoid ambiguity (`-n`, `-e`, `-a`).
* Added `-l`/`--list` and  `-p`/`--path` options to print only the UUID or the Path of the matching Provisioning Profiles instead of an ASCII table.
* Added `-0`/`--print0` so that you can use `xargs -0` on the resulting list.

## 0.3.4

* Update the gem homepage.
* Added badge in README.
* Added `CHANGELOG`.  
[#3](https://github.com/AliSoftware/pprof/issues/3)
* Improved ruby documentation.

## 0.3.3

Basically contains the changes listed in 0.3.4, but had to be yanked from RubyGems after a bad manipulation.

## 0.3.2

* Fix `-e` / `--exp` option.
* First version [published on RubyGems.org](https://rubygems.org/gems/pprof).

## 0.3.1

* Improved `README`.
* Added `[]`, `has_key?` and `keys` facades for `Entitlements`.

## 0.3.0

* Refactoring `info`, `list` and `ascii_table` to the `OutputFormatter` class.
* Better CLI option parser error handling.
* Fix case of `nil` block/proc.
* Refactor `print_list` method.

## 0.2.0

* Adding options, filters and flags to the CLI.

## 0.1.0

* Initial version.
