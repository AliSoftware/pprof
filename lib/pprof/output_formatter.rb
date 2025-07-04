# frozen_string_literal: true

require 'json'

# Module for the pprof tool to manipulate Provisioning Profiles
module PProf
  # A helper tool to pretty-print Provisioning Profile informations
  class OutputFormatter
    # List of properties of a `PProf::ProvisioningProfile` to print when using the `-i` flag
    MAIN_PROFILE_KEYS = %i[name uuid app_id_name app_id_prefix creation_date expiration_date ttl team_ids team_name].freeze

    # Initialize a new OutputFormatter
    #
    # @param [IO] output
    #        The output destination where to print the formatted data.
    #        Defaults to $stdout
    #
    def initialize(output = $stdout)
      @output = output
    end

    # A small helper to print ASCII tables
    class ASCIITable
      # Create a new ASCII table
      #
      # @param [Int...] widths
      #        The list of width for each colum of the table
      def initialize(*widths)
        @widths = widths
      end

      # Add a new row to the ASCII table
      #
      # @param [String...] cols
      #        The content of each column of the row to add
      def row(*cols)
        justified_cols = cols.zip(@widths).map do |c, w|
          (c || '<nil>').to_s.ljust(w)[0...w]
        end
        "| #{justified_cols.join(' | ')} |"
      end

      # Add a separator line to the ASCII table
      def separator
        columns_dashes = @widths.map { |w| '-' * (w + 2) }
        "+#{columns_dashes.join('+')}+"
      end
    end

    # Prints an error message
    #
    # @param [String] message
    #        The error message to print
    # @param [String] file
    #        The provisioning profile file for which the error occurred
    #
    def print_error(message, file)
      @output.puts "\u{274c}  #{file} - #{message}"
    end

    # Prints the description of a Provisioning Profile
    #
    # @param [PProf::ProvisioningProfile] profile
    #        The ProvisioningProfile object to print
    # @param [Hash<Symbol,Bool>] options
    #        Decide what to print. Valid keys are :info, :certs and :devices
    #
    def print_info(profile, options = nil)
      options ||= { info: true }
      if options[:info]
        keys = MAIN_PROFILE_KEYS
        keys.each do |key|
          @output.puts "- #{key}: #{profile.send(key.to_sym)}"
        end
        @output.puts '- Entitlements:'
        @output.puts(profile.entitlements.to_s.split("\n").map { |line| "   #{line}" })
      end

      # rubocop:disable Style/GuardClause
      if options[:info] || options[:certs]
        @output.puts "- #{profile.developer_certificates.count} Developer Certificates"
        if options[:certs]
          profile.developer_certificates.each do |cert|
            @output.puts "   - #{cert.subject}"
            @output.puts "     issuer: #{cert.issuer}"
            @output.puts "     serial: #{cert.serial}"
            @output.puts "     expires: #{cert.not_after}"
          end
        end
      end

      if options[:info] || options[:devices]
        @output.puts "- #{(profile.provisioned_devices || []).count} Provisioned Devices"
        profile.provisioned_devices.each { |udid| @output.puts "   - #{udid}" } if options[:devices]
        @output.puts "- Provision all devices: #{profile.provisions_all_devices.inspect}"
      end
      # rubocop:enable Style/GuardClause
    end

    # Returns a Provisioning Profile hash ready to be printed as a JSON output
    #
    # @param [Array<PProf::ProvisioningProfile>] profile
    #        List of provisioning profiles to include in the JSON output
    # @param [Hash] options
    #        Options to indicate what to include in the generated JSON.
    #        `:certs`: if set to `true`, output will also include the info about `DeveloperCertificates` in each profile
    #        `:devices`: if set to `true`, output will also include the list of `ProvisionedDevices` for each profile
    #
    # @return [Hash] The hash ready to be `JSON.pretty_generate`'d
    #
    def as_json(profile, options = {})
      hash = profile.to_hash.dup
      hash.delete 'DER-Encoded-Profile'
      hash.delete 'ProvisionedDevices' unless options[:devices]
      if options[:certs]
        hash['DeveloperCertificates'] = profile.developer_certificates.map do |cert|
          {
            subject: cert.subject,
            issuer: cert.issuer,
            serial: cert.serial,
            expires: cert.not_after
          }
        end
      else
        hash.delete 'DeveloperCertificates'
      end
      hash
    end

    # Prints a Provisioning Profile as JSON
    #
    # @param [Array<PProf::ProvisioningProfile>] profile
    #        List of provisioning profiles to include in the JSON output
    # @param [Hash] options
    #        Options to indicate what to include in the generated JSON.
    #        `:certs`: if set to `true`, output will also include the info about `DeveloperCertificates` in each profile
    #        `:devices`: if set to `true`, output will also include the list of `ProvisionedDevices` for each profile
    #
    def print_json(profile, options = {})
      @output.puts JSON.pretty_generate(as_json(profile, options))
    end

    # Generates a lambda which takes a `PProf::ProvisioningProfile` and returns if it should be kept in our listing or not
    #
    # @param [Hash<Symbol,Any>] filters
    #        The hash describing the applied filters
    # @return [Lambda] A lambda which takes a `PProf::ProvisioningProfile` and returns `true` if it matches the provided `filters`
    #
    def filter_proc(filters = {})
      lambda do |p|
        (filters[:name].nil? || p.name =~ filters[:name]) &&
          (filters[:appid_name].nil? || p.app_id_name =~ filters[:appid_name]) &&
          (filters[:appid].nil? || p.entitlements.app_id =~ filters[:appid]) &&
          (filters[:uuid].nil? || p.uuid =~ filters[:uuid]) &&
          (filters[:team].nil? || p.team_name =~ filters[:team] || p.team_ids.any? { |id| id =~ filters[:team] }) &&
          (filters[:exp].nil? || (p.expiration_date < DateTime.now) == filters[:exp]) &&
          (filters[:has_devices].nil? || !(p.provisioned_devices || []).empty? == filters[:has_devices]) &&
          (filters[:all_devices].nil? || p.provisions_all_devices == filters[:all_devices]) &&
          (filters[:aps_env].nil? || match_aps_env(p.entitlements.aps_environment, filters[:aps_env])) &&
          (filters[:platform].nil? || p.platform.include?(filters[:platform])) &&
          true
      end
    end

    # Prints the filtered list as a table
    #
    # @param [String] dirs
    #        The directories containing the mobileprovision/provisionprofile files to list.
    #        Defaults to ['~/Library/MobileDevice/Provisioning Profiles', '~/Library/Developer/Xcode/UserData/Provisioning Profiles']
    #
    # @yield each provisioning provile for filtering/validation
    #        The block is given ProvisioningProfile object and should
    #        return true to display the row, false to filter it out
    #
    def print_table(dirs: PProf::ProvisioningProfile::DEFAULT_DIRS)
      count = 0
      errors = []

      table = PProf::OutputFormatter::ASCIITable.new(36, 60, 45, 25, 2, 10)
      @output.puts table.separator
      @output.puts table.row('UUID', 'Name', 'AppID', 'Expiration Date', ' ', 'Team Name')
      @output.puts table.separator

      dirs.each do |dir|
        Dir['*.{mobileprovision,provisionprofile}', base: dir].each do |file_name|
          file = File.join(dir, file_name)
          begin
            p = PProf::ProvisioningProfile.new(file)

            next if block_given? && !yield(p)

            state = DateTime.now < p.expiration_date ? "\u{2705}" : "\u{274c}" # 2705=checkmark, 274C=red X
            @output.puts table.row(p.uuid, p.name, p.entitlements.app_id, p.expiration_date.to_time, state, p.team_name)
          rescue StandardError => e
            errors << { message: e, file: file }
          end
          count += 1
        end
      end

      @output.puts table.separator
      @output.puts "#{count} Provisioning Profiles found."

      errors.each { |e| print_error(e[:message], e[:file]) } unless errors.empty?
    end

    # Prints the filtered list of UUIDs or Paths only
    #
    # @param [Hash] options
    #        The options hash typically filled while parsing the command line arguments.
    #         - :mode: will print the UUIDs if set to `:list`, the file path otherwise
    #         - :zero: will concatenate the entries with `\0` instead of `\n` if set
    # @param [String] dirs
    #        The directories containing the mobileprovision/provisionprofile files to list.
    #        Defaults to ['~/Library/MobileDevice/Provisioning Profiles', '~/Library/Developer/Xcode/UserData/Provisioning Profiles']
    #
    # @yield each provisioning profile for filtering/validation
    #        The block is given ProvisioningProfile object and should
    #        return true to display the row, false to filter it out
    #
    def print_list(options:, dirs: PProf::ProvisioningProfile::DEFAULT_DIRS)
      errors = []
      dirs.each do |dir|
        Dir['*.{mobileprovision,provisionprofile}', base: dir].each do |file_name|
          file = File.join(dir, file_name)
          p = PProf::ProvisioningProfile.new(file)
          next if block_given? && !yield(p)

          @output.print options[:mode] == :list ? p.uuid.chomp : file.chomp
          @output.print options[:zero] ? "\0" : "\n"
        rescue StandardError => e
          errors << { message: e, file: file }
        end
      end
      errors.each { |e| print_error(e[:message], e[:file]) } unless errors.empty?
    end

    # Prints the filtered list of profiles as a JSON array
    #
    # @param [Hash] options
    #        The options hash typically filled while parsing the command line arguments.
    #         - :certs: will print the UUIDs if set to `:list`, the file path otherwise
    #         - :devices: will concatenate the entries with `\0` instead of `\n` if set
    # @param [String] dirs
    #        The directories containing the mobileprovision/provisionprofile files to list.
    #        Defaults to ['~/Library/MobileDevice/Provisioning Profiles', '~/Library/Developer/Xcode/UserData/Provisioning Profiles']
    #
    # @yield each provisioning profile for filtering/validation
    #        The block is given ProvisioningProfile object and should
    #        return true to display the row, false to filter it out
    #
    def print_json_list(options:, dirs: PProf::ProvisioningProfile::DEFAULT_DIRS)
      errors = []
      profiles = dirs.flat_map do |dir|
        Dir['*.{mobileprovision,provisionprofile}', base: dir].map do |file_name|
          file = File.join(dir, file_name)
          p = PProf::ProvisioningProfile.new(file)
          as_json(p, options) unless block_given? && !yield(p)
        rescue StandardError => e
          errors << { message: e, file: file }
        end
      end.compact
      errors.each { |e| print_error(e[:message], e[:file]) } unless errors.empty?
      @output.puts JSON.pretty_generate(profiles)
    end

    def self.match_aps_env(actual, expected)
      return false if actual.nil? # false if no Push entitlements
      return true if expected == true # true if Push present but we don't filter on specific env

      actual =~ expected        # true if Push present and we filter on specific env
    end
  end
end
