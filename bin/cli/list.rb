module PProf
  module CLI
    def self.print_list(filters = {})
      count = 0

      table = PProf::CLI::ASCIITable.new(36, 60, 45, 25, 2, 10)
      table.print_header('uuid', 'name', 'AppID', 'Expiration Date', ' ', 'Team Name')

      Dir[PROV_PROFILES_DIR + '/*.mobileprovision'].each do |file|
        p = PProf::ProvisioningProfile.new(file)
        
        next unless filters[:name].nil? || p.name =~ filters[:name]
        next unless filters[:appid_name].nil? || p.app_id_name =~ filters[:appid_name]
        next unless filters[:appid].nil? || p.entitlements.app_id =~ filters[:appid]
        next unless filters[:uuid].nil? || p.uuid =~ filters[:uuid]
        next unless filters[:exp].nil? || (p.expiration_date < DateTime.now) == filters[:exp]
        next unless filters[:has_devices].nil? || !(p.provisioned_devices || []).empty? == filters[:has_devices]
        next unless filters[:all_devices].nil? || p.provisions_all_devices == filters[:all_devices]
        next unless filters[:aps_env].nil? || match_aps_env(p.entitlements.aps_environment, filters[:aps_env])

        state = DateTime.now < p.expiration_date ? "\u{2705}" : "\u{274c}" # 2705=checkmark, 274C=red X
        table.print_row(p.uuid, p.name, p.entitlements.app_id, p.expiration_date.to_time, state, p.team_name)
        count += 1
      end

      table.print_separator
      puts "#{count}#{filters.empty? ? '' : ' matching'} Provisioning Profiles found."
    end

    private
    def self.match_aps_env(actual, expected)
      return false if actual.nil?   # false if no Push entitlements
      return true if expected === true  # true if Push present but we don't filter on specific env
      return actual =~ expected     # true if Push present and we filter on specific env
    end
  end
end
