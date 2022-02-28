# frozen_string_literal: true

# Module for the pprof tool to manipulate Provisioning Profiles
module PProf
  # A helper tool to pretty-print Provisioning Profile informations
  class OutputFormatter
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
        '| ' + cols.zip(@widths).map do |c, w|
          (c || '<nil>').to_s.ljust(w)[0...w]
        end.join(' | ') + ' |'
      end

      # Add a separator line to the ASCII table
      def separator
        '+' + @widths.map { |w| '-' * (w + 2) }.join('+') + '+'
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
        keys = %i[name uuid app_id_name app_id_prefix creation_date expiration_date ttl team_ids
                  team_name]
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

    # Prints the filtered list of Provisioning Profiles
    #
    # Convenience method. Calls self.print_list with a filter block build from a filter hash
    #
    # @param [String] dir
    #        The directory to search for the provisioning profiles. Defaults to the standard directory on Mac
    #
    # @param [Hash<Symbol,Any>] filters
    #        The hash describing the applied filters
    #
    # @param [Hash<Symbol,Any>] list_options
    #        The way to print the output.
    #        * Valid values for key `:mode` are:
    #          - `:table` (for ASCII table output)
    #          - `:list` (for plain list of only the UUIDs, suitable for piping to `xargs`)
    #          - `:path` (for plain list of only the paths, suitable for piping to `xargs`)
    #        * Valid values for key `:zero` are `true` or `false` to decide if we print `\0` at the end of each output.
    #          Only used by `:list` and `:path` modes
    #
    def print_filtered_list(dir = PProf::ProvisioningProfile::DEFAULT_DIR, filters = {}, list_options = { mode: :table })
      filter_func = lambda do |p|
        (filters[:name].nil? || p.name =~ filters[:name]) &&
          (filters[:appid_name].nil? || p.app_id_name =~ filters[:appid_name]) &&
          (filters[:appid].nil? || p.entitlements.app_id =~ filters[:appid]) &&
          (filters[:uuid].nil? || p.uuid =~ filters[:uuid]) &&
          (filters[:team].nil? || p.team_name =~ filters[:team] || p.team_ids.any? { |id| id =~ filters[:team] }) &&
          (filters[:exp].nil? || (p.expiration_date < DateTime.now) == filters[:exp]) &&
          (filters[:has_devices].nil? || !(p.provisioned_devices || []).empty? == filters[:has_devices]) &&
          (filters[:all_devices].nil? || p.provisions_all_devices == filters[:all_devices]) &&
          (filters[:aps_env].nil? || match_aps_env(p.entitlements.aps_environment, filters[:aps_env])) &&
          true
      end

      case list_options[:mode]
      when :table
        print_table(dir, &filter_func)
      else
        print_list(dir, list_options, &filter_func)
      end
    end

    # Prints the filtered list as a table
    #
    # @param [String] dir
    #        The directory containing the mobileprovision files to list.
    #        Defaults to '~/Library/MobileDevice/Provisioning Profiles'
    #
    # @yield each provisioning provile for filtering/validation
    #        The block is given ProvisioningProfile object and should
    #        return true to display the row, false to filter it out
    #
    def print_table(dir = PProf::ProvisioningProfile::DEFAULT_DIR)
      count = 0
      errors = []

      table = PProf::OutputFormatter::ASCIITable.new(36, 60, 45, 25, 2, 10)
      @output.puts table.separator
      @output.puts table.row('UUID', 'Name', 'AppID', 'Expiration Date', ' ', 'Team Name')
      @output.puts table.separator

      Dir[dir + '/*.mobileprovision'].each do |file|
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

      @output.puts table.separator
      @output.puts "#{count} Provisioning Profiles found."

      errors.each { |e| print_error(e[:message], e[:file]) } unless errors.empty?
    end

    # Prints the filtered list of UUIDs or Paths only
    #
    # @param [String] dir
    #        The directory containing the mobileprovision files to list.
    #        Defaults to '~/Library/MobileDevice/Provisioning Profiles'
    # @param [Hash] options
    #        The options hash typically filled while parsing the command line arguments.
    #         - :mode: will print the UUIDs if set to `:uuid`, the file path otherwise
    #         - :zero: will concatenate the entries with `\0` instead of `\n` if set
    #
    # @yield each provisioning profile for filtering/validation
    #        The block is given ProvisioningProfile object and should
    #        return true to display the row, false to filter it out
    #
    def print_list(dir = PProf::ProvisioningProfile::DEFAULT_DIR, options) # rubocop:disable Style/OptionalArguments
      errors = []
      Dir[dir + '/*.mobileprovision'].each do |file|
        p = PProf::ProvisioningProfile.new(file)
        next if block_given? && !yield(p)

        @output.print options[:mode] == :uuid ? p.uuid.chomp : file.chomp
        @output.print options[:zero] ? "\0" : "\n"
      rescue StandardError => e
        errors << { message: e, file: file }
      end
      errors.each { |e| print_error(e[:message], e[:file]) } unless errors.empty?
    end

    def self.match_aps_env(actual, expected)
      return false if actual.nil? # false if no Push entitlements
      return true if expected == true # true if Push present but we don't filter on specific env

      actual =~ expected        # true if Push present and we filter on specific env
    end
  end
end
