module PProf
  module CLI
    def self.print_info(path, options = { :info => true })
      p = PProf::ProvisioningProfile.new(path)

      lines = []
      if options[:info]
        keys = [:name, :uuid, :app_id_name, :app_id_prefix, :creation_date, :expiration_date, :ttl, :team_ids, :team_name]
        lines += keys.map do |key|
          "- #{key.to_s}: #{p.send(key.to_sym)}"
        end
        lines << "- Entitlements:"
        lines += p.entitlements.to_s.split("\n").map { |line| "   #{line}" }
      end

      if options[:info] || options[:certs] 
        lines << "- #{p.developer_certificates.count} Developer Certificates"
        lines += p.developer_certificates.map { |cert| "   - #{cert.subject}" } if options[:certs]
      end
      if options[:info] || options[:devices]
        lines << "- #{(p.provisioned_devices || []).count} Provisioned Devices"
        lines += p.provisioned_devices.map { |udid| "   - #{udid}" } if options[:devices]
        lines << "- Provision all devices: #{p.provisions_all_devices.inspect}"
      end
      
      puts lines.join("\n")
    end
  end
end
