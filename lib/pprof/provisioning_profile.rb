require 'openssl'
require 'plist'
require 'time'

module PProf
  class ProvisioningProfile
    def initialize(file)
      pkcs7 = OpenSSL::PKCS7.new(File.read(file))
      pkcs7.verify([], OpenSSL::X509::Store.new)
      @plist = Plist::parse_xml(pkcs7.data)
    end

    # @return [String]
    def name
      @plist['Name']
    end

    # @return [String]
    def uuid
      @plist['UUID']
    end

    # @return [String]
    def app_id_name
      @plist['AppIDName']
    end

    # @return [String]
    def app_id_prefix
      @plist['ApplicationIdentifierPrefix']
    end

    # @return [DateTime]
    def creation_date
      @plist['CreationDate']
    end

    # @return [DateTime]
    def expiration_date
      @plist['ExpirationDate']
    end

    # @return [Int]
    def ttl
      @plist['TimeToLive'].to_i
    end

    # @return [Array<String>]
    def team_ids
      @plist['TeamIdentifier']
    end
    
    # @return [String]
    def team_name
      @plist['TeamName']
    end

    # @return [Array<OpenSSL::X509::Certificate>] List of certificates associated with this profile
    def developer_certificates
      @plist['DeveloperCertificates'].map do |data|
        OpenSSL::X509::Certificate.new(data.string)
      end
    end

    # @return [Entitlements] All the entitlements associated with this profile
    def entitlements
      PProf::Entitlements.new(@plist['Entitlements'])
    end

    # @return [Array<String>] List of provisioned devices if any
    def provisioned_devices
      @plist['ProvisionedDevices']
    end

    # @return [Bool]
    def provisions_all_devices
      @plist['ProvisionsAllDevices']
    end

    def to_hash
      @dict
    end

    def to_s
      ent_list = entitlements.to_s.split("\n").map { |line| "   #{line}" }.join("\n")
      lines = [:name, :uuid, :app_id_name, :app_id_prefix, :creation_date, :expiration_date, :ttl, :team_ids, :team_name].map do |key|
        "- #{key.to_s}: #{self.send(key.to_sym)}"
      end +
      [
        "- #{developer_certificates.count} Developer Certificates",
        developer_certificates.map { |cert| "   - #{cert.subject}" }.join("\n"),
        "- #{provisioned_devices.count} Provisioned Devices",
        provisioned_devices.map { |udid| "   - #{udid}" }.join("\n"),
        "- Entitlements:\n#{ent_list}"
      ]
      lines.join("\n")
    end
  end
end
