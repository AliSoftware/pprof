module PProf
  module CLI
    # Prints the filtered list
    #
    # Convenience method. Calls self.print_list with a block build from a filter hash
    #
    # @param [Hash<Symbol,?>] filters
    #        The hash describing the applied filters
    #
    def self.print_filtered_list(filters = {})
      self.print_list do |p|
        (filters[:name].nil? || p.name =~ filters[:name]) &&
        (filters[:appid_name].nil? || p.app_id_name =~ filters[:appid_name]) &&
        (filters[:appid].nil? || p.entitlements.app_id =~ filters[:appid]) &&
        (filters[:uuid].nil? || p.uuid =~ filters[:uuid]) &&
        (filters[:exp].nil? || (p.expiration_date < DateTime.now) == filters[:exp]) &&
        (filters[:has_devices].nil? || !(p.provisioned_devices || []).empty? == filters[:has_devices]) &&
        (filters[:all_devices].nil? || p.provisions_all_devices == filters[:all_devices]) &&
        (filters[:aps_env].nil? || match_aps_env(p.entitlements.aps_environment, filters[:aps_env])) &&
        true
      end
    end

    # Prints the filtered list
    #
    # @param [Proc] match_block
    #        The block to validate each provisioning provile.
    #        it's given the ProvisioningProfile object and should
    #        return true to display the row, falst to filter it out
    #
    def self.print_list(&match_block)   
      count = 0

      table = PProf::CLI::ASCIITable.new(36, 60, 45, 25, 2, 10)
      table.print_header('UUID', 'Name', 'AppID', 'Expiration Date', ' ', 'Team Name')

      Dir[PROV_PROFILES_DIR + '/*.mobileprovision'].each do |file|
        p = PProf::ProvisioningProfile.new(file)
        
        next unless match_block.nil? || match_block.call(p)

        state = DateTime.now < p.expiration_date ? "\u{2705}" : "\u{274c}" # 2705=checkmark, 274C=red X
        table.print_row(p.uuid, p.name, p.entitlements.app_id, p.expiration_date.to_time, state, p.team_name)
        count += 1
      end

      table.print_separator
      puts "#{count} Provisioning Profiles found."
    end

    private
    def self.match_aps_env(actual, expected)
      return false if actual.nil?   # false if no Push entitlements
      return true if expected === true  # true if Push present but we don't filter on specific env
      return actual =~ expected     # true if Push present and we filter on specific env
    end
  end
end
