module Banjaxer
  describe CLI do
    let :subject do
      described_class.new
    end

    context 'version' do
      let :output do
        capture :stdout do
          subject.version
        end
      end

      it 'has a version' do
        expect(output).to match "banjaxer version #{VERSION}"
      end
    end
  end
end
