# Module for the pprof tool to manipulate Provisioning Profiles
module PProf
  # Represents the list of entitlements in a Provisioning Profile
  class Entitlements
    # Create a new Entitlements object from the hash representation
    # extracted from the Provisioning Profile
    #
    # @param [Hash] dict
    #        The hash representation of the entitlements, typically
    #        extracted from the Provisioning Profile.
    def initialize(dict)
      @dict = dict
    end

    # The list of Keychain Access Groups
    #
    # @return [Array<String>]
    def keychain_access_groups
      @dict['keychain-access-groups']
    end

    # The status of the `get-task-allow` flag.
    # True if we can attach a debugger to the executable, false if not.
    #
    # @return [Bool]
    def get_task_allow
      @dict['get-task-allow']
    end

    # The full application identifier (including the team prefix), as specified in the entitlements
    #
    # @return [String]
    def app_id
      @dict['application-identifier']
    end

    # The Team Identifier
    #
    # @return [String]
    def team_id
      @dict['com.apple.developer.team-identifier']
    end

    # The Apple Push Service environment used for push notifications.
    # Typically either 'development' or 'production', or `nil` if push isn't enabled.
    #
    # @return [String]
    def aps_environment
      @dict['aps-environment']
    end

    # The Application Groups registered in the entitlements
    #
    # @return [Array<String>]
    def app_groups
      @dict['com.apple.security.application-groups']
    end

    # Are Beta (TestFlight) reports active?
    #
    # @return [Bool]
    def beta_reports_active
      @dict['beta-reports-active']
    end

    # True if the HealthKit entitlement is set
    #
    # @return [Bool]
    def healthkit
      @dict['com.apple.developer.healthkit']
    end

    # The Ubiquity Container identifiers, if at least one is enabled
    #
    # @return [Array<String>]
    def ubiquity_container_identifiers
      @dict['com.apple.developer.ubiquity-container-identifiers']
    end

    # The Ubiquity Key-Value Store Identifier, if enabled.
    #
    # @return [String]
    def ubiquity_kvstore_identifier
      @dict['com.apple.developer.ubiquity-kvstore-identifier']
    end

    # Generic access to any entitlement by key
    #
    # @param [#to_s] key
    #        The entitlement key to read
    #
    def [](key)
      @dict[key.to_s]
    end

    # Check if a given entitlement key is present
    #
    # @param [#to_s] key
    #        The key to check
    #
    def has_key?(key)
      @dict.has_key?(key.to_s)
    end

    # The list of all entitlement keys, as String
    #
    # @return [Array<String>]
    #
    def keys
      @dict.keys.map(&:to_s)
    end

    # The hash representation of the entitlements (as represented in their PLIST form)
    #
    # @return [Hash]
    def to_hash
      @dict
    end

    # The pretty-printed list of all entitlement keys and values
    # (as a multi-line dashed list for human reading)
    #
    # @return [String]
    def to_s
      @dict.map do |key, value|
        "- #{key}: #{value}"
      end.join("\n")
    end
  end
end
