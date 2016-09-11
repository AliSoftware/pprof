# pprof

[![Twitter: @aligatr](https://img.shields.io/badge/contact-@aligatr-blue.svg?style=flat)](https://twitter.com/aligatr)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/AliSoftware/pprof/blob/master/LICENSE)

`pprof` is a ruby library and binary to manipulate Provisioning Profiles.

It can help you create ruby scripts to list, get information, find and filter Provisioning Profiles easily.

## Installation

### Rubygems

As of now this library is very early stage and [hasn't been pushed on RubyGems yet](https://github.com/AliSoftware/pprof/issues/4).
I intend to push it as soon as [#2](https://github.com/AliSoftware/pprof/issues/4) (unit tests) and [#3](https://github.com/AliSoftware/pprof/issues/4) (CHANGELOG) are addressed.

### Build from source

* Clone the repository
* Build it using `gem build pprof.gemspec`
* Install it using `gem install pprof-0.3.0.gem`

## Example usages

* Find all the Provisioning Profiles that are attached to a given Team, or with a given AppID, or that will expire after a given date.

* List all your Provisioning Profiles and their inner information, like the provisioned device UDIDs, the list of certificates (with their associated subject/name), etc.

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

### Using it in Ruby

```ruby
require 'pprof'
# Load the Provisioning Profile
p = PProf::ProvisioningProfile.new('12345678-ABCD-EF90-1234-567890ABCDEF')

# Print various informations
puts p.name
puts p.team_name
puts p.entitlements.aps_environment
puts p.provisioned_devices.count

# Use an OutputFormatter to pretty-print the info
o = PProf::OutputFormatter.new
o.print_info(p)

# You can also print into any IO other than $stdout, like a File
certs_file = File.new('certs.txt', 'w')
o2 = PProf::OutputFormatter.new(certs_file)
o2.print_info(p, :certs => true)
certs_file.close

# And you can easily loop on all provisioning profiles and manipulate each
dir = PProf::ProvisioningProfile::DEFAULT_DIR
Dir["#{dir}/*.mobileprovision"].each do |file|
  p = PProf::ProvisioningProfile.new(file)
  puts p.name
end
```


## Anatomy of a Provisioning Profile

Provisioning Profiles are in fact PKCS7 files which contain a plist payload. 

That plist payload itself contains various data, including some textual information (Team Name, AppID, …), dates (expiration date, etc) but also X509 Certificates (`OpenSSL::X509::Certificate`).

<details>
<summary>Outline of the two main classes `ProvisioningProfile` and `Entitlements`</summary>

```ruby
PProf::ProvisioningProfile
    ::DEFAULT_DIR
    new(file) => PProf::ProvisioningProfile
    to_hash => Hash<String, Any>
    
    name => String
    uuid => String
    app_id_name => String
    app_id_prefix => String
    creation_date => DateTime
    expiration_date => DateTime
    ttl => Int
    team_ids => Array<String>
    team_name => String
    developer_certificates => Array<OpenSSL::X509::Certificate>
    entitlements => PProf::Entitlements
    provisioned_devices => Array<String>
    provisions_all_devices => Bool

PProf::Entitlements
    new(dict) => PProf::Entitlements
    to_hash => Hash<String, Any>
    
    keychain_access_groups => Array<String>
    get_task_allow => Bool
    app_id => String
    team_id => String
    aps_environment => String
    app_groups => Array<String>
    beta_reports_active => Bool
    healthkit => Bool
    ubiquity_container_identifiers => Array<String>
    ubiquity_kvstore_identifier => String
```
</details>
