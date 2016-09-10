module PProf
  class Entitlements
    def initialize(dict)
      @dict = dict
    end

    # @return [Array<String>]
    def keychain_access_groups
      @dict['keychain-access-groups']
    end

    # @return [Bool]
    def get_task_allow
      @dict['get-task-allow']
    end

    # @return [String]
    def app_id
      @dict['application-identifier']
    end

    # @return [String]
    def team_id
      @dict['com.apple.developer.team-identifier']
    end

    # @return [String]
    def aps_environment
      @dict['aps-environment']
    end

    # @return [Array<String>]
    def app_groups
      @dict['com.apple.security.application-groups']
    end

    # @return [Bool]
    def beta_reports_active
      @dict['beta-reports-active']
    end

    # @return [Bool]
    def healthkit
      @dict['com.apple.developer.healthkit']
    end

    # @return [Array<String>]
    def ubiquity_container_identifiers
      @dict['com.apple.developer.ubiquity-container-identifiers']
    end

    # @return [String]
    def ubiquity_kvstore_identifier
      @dict['com.apple.developer.ubiquity-kvstore-identifier']
    end

    def to_hash
      @dict
    end

    def to_s
      @dict.map do |key, value|
        "- #{key}: #{value}"
      end.join("\n")
    end
  end
end
