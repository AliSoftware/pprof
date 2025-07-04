# pprof

[![Twitter: @aligatr](https://img.shields.io/badge/contact-@aligatr-blue.svg?style=flat)](https://twitter.com/aligatr)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/AliSoftware/pprof/blob/master/LICENSE)
[![Gem Version](https://badge.fury.io/rb/pprof.svg)](https://badge.fury.io/rb/pprof)

`pprof` is a ruby library and binary to manipulate Provisioning Profiles.

It can help you manage the Provisioning Profiles installed on your Mac (find the profiles UUIDs from the app names or bundle IDs, find detailed information on a given profile, clean up expired profiles from your Mac…) directly from the command line.

It also supports printing the output in JSON format so you can pipe the result of printing provisioning profiles info into `jq` or similar tools.

## Installation

### Rubygems

```sh
$ gem install pprof
```

_(You might need to run this command with `sudo` if your gem home is a system directory. Alternatively, we recommend to use a Ruby Version Manager like `rbenv`.)_

### Build from source

* Clone the repository
* Build it using `gem build pprof.gemspec`
* Install it using `gem install pprof-*.gem` (replace `*` with the current version number)

## Example usages

* Find all the Provisioning Profiles that are attached to a given Team, or with a given AppID, or that will expire after a given date.

* List all your Provisioning Profiles and their inner information, like the provisioned device UDIDs, the list of certificates (with their associated subject/name), etc.

### Using it from the command line

#### Listing (and filtering) provisioning profiles

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

# List only the expired profiles, and pipe the resulting list to xargs to remove them all
$ pprof --exp -0 | xargs -0 rm
```

#### Printing info for a given Provisioning Profile

```sh
# Print info for a given Provisioning Profile
$ pprof '12345678-ABCD-EF90-1234-567890ABCDEF'

# Print certificates in a given PP
$ pprof --certs '12345678-ABCD-EF90-1234-567890ABCDEF'

# Print devices in a given PP
$ pprof --devices '12345678-ABCD-EF90-1234-567890ABCDEF'

# Print all info on a given PP
$ pprof --certs --devices --info '12345678-ABCD-EF90-1234-567890ABCDEF'
$ pprof -cdi '12345678-ABCD-EF90-1234-567890ABCDEF'
```

#### Printing output in JSON

```sh
# Print info about all your provisioning profiles as a JSON array
$ pprof --json
# Print info about all your provisioning profiles whose name contains "Foo", as a JSON array
$ pprof --name "Foo" --json
# Print info about all your provisioning profiles as a JSON array, including list of devices and certificates in each profile
$ pprof --json --devices --certs

# Print info about a specific provisioning profile as JSON object
$ pprof --json '12345678-ABCD-EF90-1234-567890ABCDEF'
# Print info about a specific provisioning profile as JSON object, including list of devices and certificates
$ pprof --json -c -d '12345678-ABCD-EF90-1234-567890ABCDEF'

# Use `jq` (https://stedolan.github.io/jq/) to post-process the JSON output and generate some custom JSON array of objects from it
$ pprof --name 'My App' --json --devices | jq '.[] | {uuid:.UUID, name:.AppIDName, nb_profiles: .ProvisionedDevices|length}'
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
File.open('certs.txt', 'w') do |file|
  o2 = PProf::OutputFormatter.new(file)
  o2.print_info(p, :certs => true)
end

# And you can easily loop on all provisioning profiles and manipulate each
profiles_dirs = PProf::ProvisioningProfile::DEFAULT_DIRS
# `*.mobileprovision` are typically for iOS profiles, `*.provisionprofile` for Mac profiles
profiles_dirs.each do |dir|
  Dir["#{dir}/*.{mobileprovision,provisionprofile}"].each do |file|
    p = PProf::ProvisioningProfile.new(file)
    puts p.name
  end
end
```


## Anatomy of a Provisioning Profile

Provisioning Profiles are in fact PKCS7 files which contain a plist payload. 

That plist payload itself contains various data, including some textual information (Team Name, AppID, …), dates (expiration date, etc) but also X509 Certificates (`OpenSSL::X509::Certificate`).

<details>
<summary>Outline of the two main classes `ProvisioningProfile` and `Entitlements`</summary>

```ruby
PProf::ProvisioningProfile
    ::DEFAULT_DIRS
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
    [](key) => Any
    has_key?(key) => Bool
    keys => Array<String>
    
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

## Contributing

There's plenty of room for improvement, including:

* Additional filters
* Parsing of additional entitlement keys

Don't hesitate to contribute, either with an Issue to give ideas or additional keys that aren't parsed yet, or via a Pull Request to provide new features yourself!

## License

This project is under the MIT license. See `LICENSE` file for more details.
