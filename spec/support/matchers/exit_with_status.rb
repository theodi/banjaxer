RSpec::Matchers.define :exit_with_status do |expected|
  match do |actual|
    expect { actual.call }.to raise_error(SystemExit)

    begin
      actual.call
    rescue SystemExit => e
      expect(e.status).to eq expected
    end
  end

  supports_block_expectations
end
