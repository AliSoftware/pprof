# CHANGELOG

This file lists the changes for various versions of the `pprof` gem.

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
