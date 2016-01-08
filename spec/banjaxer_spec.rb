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

    context 'Tell the time' do
      let :output do
        capture :stdout do
          Timecop.freeze Time.local 1974, 06, 15, 9, 30 do
            subject.tell_the_time
          end
        end
      end

      it 'knows what time it is' do
        expect(output).to match '09:30 on June 15, 1974'
      end
    end
  end
end
