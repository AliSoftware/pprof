require 'pprof'

context 'Entitlements' do
  e = ''
  text = ''
  Steps 'Pretty Printed' do
    Given 'I have an example' do
      e = PProf::Entitlements.new('application-identifier' => '12345678-ABCD-EF90-1234-567890ABCDEF', 'uid' => '0')
    end

    When 'I convert it to text' do
      text = e.to_s
    end

    Then 'It should be formatted' do
      expect(text).to eq <<~EOL.chomp
      - application-identifier: 12345678-ABCD-EF90-1234-567890ABCDEF
      - uid: 0
      EOL
    end
  end
end