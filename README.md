# pprof

[![Twitter: @aligatr](https://img.shields.io/badge/contact-@aligatr-blue.svg?style=flat)](https://twitter.com/aligatr)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/AliSoftware/pprof/blob/master/LICENSE)

`pprof` is a ruby library and binary to manipulate Provisioning Profiles.

It can help you create ruby scripts to list, get information, find and filter Provisioning Profiles easily.

## Installation

### Rubygems

As of now this library is very early stage and hasn't been pushed on RubyGems yet. (Will do as soon as I improve the binary command line a bit)

### Build from source

* Clone the repository
* Build it using `gem build pprof.gemspec`
* Install it using `gem install pprof-0.1.0.gem`

## Example usages

* For example you can use it to find all the Provisioning Profiles that are attached to a given Team, or with a given AppID, or that will expire after a given date.

* You can also use it to list all your Provisioning Profiles and their inner information, like the provisioned device UDIDs, the list of certificates (with their associated subject/name), etc.

### Using it in Ruby

```ruby
# @todo: Add example Ruby usages
```

### Using it from the command line

```sh
# TODO: Add example CLI usages
```


## Anatomy of a Provisioning Profile

Provisioning Profiles are in fact PKCS7 files which contain a plist payload. That plist payload itself contains various data, including some textual information (Team Name, AppID, …), dates (expiration date, etc) but also X509 Certificates (`OpenSSL::X509::Certificate`).

> TODO:
> 
> * Structured list of attributes of `class ProvisioningProfile`
> * Link to the RubyDoc once published on rubygems.
