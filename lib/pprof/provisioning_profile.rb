# frozen_string_literal: true

require 'openssl'
require 'plist'
require 'time'

# Module for the pprof tool to manipulate Provisioning Profiles
module PProf
  # Represents the content of a Provisioning Profile file
  class ProvisioningProfile
    # The default location where all the Provisioning Profiles are stored on a Mac
    DEFAULT_DIR = "#{ENV['HOME']}/Library/MobileDevice/Provisioning Profiles"

    # Create a new ProvisioningProfile object from a file path or UUID
    #
    # - If the parameter given has the form of an UUID, a file named with this UUID
    #   and a `.mobileprovision` is searched in the default directory `DEFAULT_DIR`
    # - Otherwise, the parameter is interpreted as a file path
    #
    # @param [String] file
    #        File path or UUID of the ProvisioningProfile
    #
    def initialize(file)
      path = if file.match?(/^[0-9A-F-]*$/i)
               Dir["#{PProf::ProvisioningProfile::DEFAULT_DIR}/#{file}.{mobileprovision,provisionprofile}"].first
             else
               file
             end
      raise "Unable to find Provisioning Profile with UUID #{file}." if file.nil?

      xml = nil
      begin
        pkcs7 = OpenSSL::PKCS7.new(File.read(path))
        pkcs7.verify([], OpenSSL::X509::Store.new)
        xml = pkcs7.data
        raise 'Empty PKCS7 payload' if xml.nil? || xml.empty?
      rescue StandardError
        # Seems like sometimes OpenSSL fails to parse the PKCS7 payload
        # Besides, OpenSSL is deprecated on macOS so might not be up-to-date on all machines
        # So as a fallback, we run the `security` command line.
        # (We could use `security` everytime, but invoking a command line is generally less
        #  efficient than calling the OpenSSL gem if available, so for now it's just used as fallback)
        xml = `security cms -D -i "#{path}" 2> /dev/null`
      end
      @plist = Plist.parse_xml(xml)
      raise "Unable to parse file #{path}." if @plist.nil?
    end

    # The name of the Provisioning Profile
    #
    # @return [String]
    def name
      @plist['Name']
    end

    # The UUID of the Provisioning Profile
    #
    # @return [String]
    def uuid
      @plist['UUID']
    end

    # The name of the Application Identifier associated with this Provisioning Profile
    #
    # @note This is not the AppID itself, but rather the name you associated to that
    #       AppID in your Developer Portal
    #
    # @return [String]
    def app_id_name
      @plist['AppIDName']
    end

    # The AppID prefix (which is typically the ID of the team)
    #
    # @return [String]
    def app_id_prefix
      @plist['ApplicationIdentifierPrefix']
    end

    # The Creation date of this Provisioning Profile
    #
    # @return [DateTime]
    def creation_date
      @plist['CreationDate']
    end

    # The expiration date of this Provisioning Profile
    #
    # @return [DateTime]
    def expiration_date
      @plist['ExpirationDate']
    end

    # The Time-To-Live of this Provisioning Profile
    # @return [Int]
    def ttl
      @plist['TimeToLive'].to_i
    end

    # The Team IDs associated with this Provisioning Profile
    #
    # @note typically Provisioning Profiles contain only one team
    #
    # @return [Array<String>]
    def team_ids
      @plist['TeamIdentifier']
    end

    # The name of the Team associated with this Provisioning Profile
    #
    # @return [String]
    def team_name
      @plist['TeamName']
    end

    # The list of X509 Developer Certificates associated with this profile
    #
    # @return [Array<OpenSSL::X509::Certificate>]
    def developer_certificates
      @plist['DeveloperCertificates'].map do |data|
        OpenSSL::X509::Certificate.new(data.string)
      end
    end

    # All the entitlements associated with this Provisioning Profile
    #
    # @return [Entitlements]
    def entitlements
      PProf::Entitlements.new(@plist['Entitlements'])
    end

    # The list of devices provisioned with this Provisioning Profile (if any)
    #
    # @return [Array<String>]
    def provisioned_devices
      @plist['ProvisionedDevices']
    end

    # Indicates if this Provisioning Profile is provisioned for all devices
    # or only for a list of some specific devices
    #
    # @return [Bool]
    def provisions_all_devices
      @plist['ProvisionsAllDevices'] || false
    end

    # The hash representation of this Provisioning Profile
    #
    # @return [Hash]
    def to_hash
      @plist
    end

    # The human-readable string representation of this Provisioning Profile
    # Typically suitable for printing this Provisioning Profile information to the user.
    #
    # @return [String]
    def to_s
      lines = %i[name uuid app_id_name app_id_prefix creation_date expiration_date ttl team_ids team_name].map do |key|
        "- #{key}: #{send(key.to_sym)}"
      end +
              [
                "- #{developer_certificates.count} Developer Certificates",
                "- #{provisioned_devices.count} Provisioned Devices",
                '- Entitlements:'
              ] + entitlements.to_hash.map { |key, value| "   - #{key}: #{value}" }
      lines.join("\n")
    end
  end
end
