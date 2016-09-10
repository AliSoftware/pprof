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
* Install it using `gem install pprof-0.2.0.gem`

## Example usages

* For example you can use it to find all the Provisioning Profiles that are attached to a given Team, or with a given AppID, or that will expire after a given date.

* You can also use it to list all your Provisioning Profiles and their inner information, like the provisioned device UDIDs, the list of certificates (with their associated subject/name), etc.

### Using it in Ruby

```ruby
# @todo: Add example Ruby usages
```

### Using it from the command line

```sh
# List all provisioning profiles
$ pprof 

# Filter provisioning profiles by name
$ pprof --name foo         # only ones containing 'foo', case sensitive
$ pprof --name /foo/i      # only ones containing 'foo', case insensitive
$ pprof --name '/foo|bar/' # only ones containing 'foo' or 'bar'
$ pprof --name /^foo$/     # only the ones exactly matching 'foo'

# Filter by AppID
$ pprof --appid com.foo             # only ones containing 'com.foo'
$ pprof --appid '/com\.(foo|bar)/'  # only ones containing 'com.foo' or 'com.bar'

# List only provisioning profiles having push notifications
$ pprof --aps
$ pprof --aps development
$ pprof --aps production

# List only provisioning profiles being expired or not
$ pprof --exp
$ pprof --no-exp

# List only provisioning profiles containing provisioned devices
$ pprof --has-devices

# Combine filters
$ pprof --has-devices --aps --appid com.foo
```
```sh
# Print info for a given Provisioning Profile
$ pprof '12345678-ABCD-EF90-1234-567890ABCDEF'

# Print certificates in a given PP
$ pprof --certs '12345678-ABCD-EF90-1234-567890ABCDEF'

# Print devices in a given PP
$ pprof --devices '12345678-ABCD-EF90-1234-567890ABCDEF'

# Print all info on a given PP
$ pprof --certs --devices --info
$ pprof -cdi '12345678-ABCD-EF90-1234-567890ABCDEF'
```


## Anatomy of a Provisioning Profile

Provisioning Profiles are in fact PKCS7 files which contain a plist payload. That plist payload itself contains various data, including some textual information (Team Name, AppID, …), dates (expiration date, etc) but also X509 Certificates (`OpenSSL::X509::Certificate`).

> TODO:
> 
> * Structured list of attributes of `class ProvisioningProfile`
> * Link to the RubyDoc once published on rubygems.
