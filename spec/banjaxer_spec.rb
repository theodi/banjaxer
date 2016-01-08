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

    context 'GET a url' do
      let :output do
        capture :stdout do
          subject.get_url 'http://uncleclive.herokuapp.com/banjax'
        end
      end

      it 'gets the url', :vcr do
        expect(output).to match 'Content-Length is 808'
      end
    end
  end
end
