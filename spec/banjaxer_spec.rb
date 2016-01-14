module Banjaxer
  describe CLI do
    let :subject do
      described_class.new
    end

    it 'has a version' do
      expect { subject.version }.to output(/^banjaxer version #{VERSION}$/).to_stdout
    end

    it 'gets the url', :vcr do
      expect { subject.get_url 'http://uncleclive.herokuapp.com/banjax' }.to output(/^Content-Length is 808$/).to_stdout
    end

    it 'knows what time it is' do
      Timecop.freeze Time.local 1974, 06, 15, 9, 30 do
        expect { subject.tell_the_time }.to output(/^09:30 on Saturday June 15, 1974$/).to_stdout
      end
    end

    context 'with options' do
      it 'is fine with no options' do
        expect { subject.embiggen 'the smallest man' }.to output(/^embiggening the smallest man$/).to_stdout
      end

      it 'can handle an option' do
        subject.options = {json: true}
        expect { subject.embiggen 'the smallest man' }.to output(/^{"embiggening":"the smallest man"}/).to_stdout
      end
    end

    context 'deal with exit codes' do
      it 'exits with a zero by default' do
        expect { subject.cromulise }.to exit_with_status 0
      end

      it 'exits with a one' do
        expect { subject.cromulise 'one' }.to exit_with_status 1
      end
    end

    context 'read output files' do
      it 'writes the expected output file' do
        subject.say 'monorail'
        expect('said').to have_content (
        """
        The word was:
          monorail
        """
        )
      end

      it 'matches with a regular expression' do
        subject.say 'Lee Carvallo'
        expect('said').to have_content (
        """
        The word was:
        /Carvallo/
        """
        )
      end
    end
  end
end
