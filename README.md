[![Build Status](http://img.shields.io/travis/theodi/banjaxer.svg?style=flat-square)](https://travis-ci.org/theodi/banjaxer)
[![Dependency Status](http://img.shields.io/gemnasium/theodi/banjaxer.svg?style=flat-square)](https://gemnasium.com/theodi/banjaxer)
[![Coverage Status](http://img.shields.io/coveralls/theodi/banjaxer.svg?style=flat-square)](https://coveralls.io/r/theodi/banjaxer)
[![Code Climate](http://img.shields.io/codeclimate/github/theodi/banjaxer.svg?style=flat-square)](https://codeclimate.com/github/theodi/banjaxer)
[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://theodi.mit-license.org)

# Kicking Aruba into a bin

My weapon-of-choice for building Ruby CLI apps has long been the mighty [Thor](http://whatisthor.com/), and up until now I've always used [Aruba](https://github.com/cucumber/aruba) to test my Thor apps (while sticking with [Rspec](http://rspec.info/) to TDD the actual workings of my gems). This has mostly worked OK, but I'm also (for better or worse) a big fan of [VCR](https://github.com/vcr/vcr), and these things really do not play nicely together.

## Oh hi, Technical Debt

Because Aruba spawns a separate Ruby process to run its tests, it's all invisible to VCR. There are a number of ([now deprecated](https://groups.google.com/forum/#!topic/cukes/UQRkro-AeVg)) [hacks](http://georgemcintosh.com/vcr-and-aruba/) to get around this problem, but I was finding that I had to write my features in very contrived ways (which definitely defeats the purpose of Cucumber), and it still behaved unexpectedly. And when Aruba also started to interfere with some of my other [favourite](https://github.com/travisjeffery/timecop) [tools](https://coveralls.io/), I decided it was Different Solution time.

## Doing it all with Rspec

I came across [this blogpost](http://bokstuff.com/blog/testing-thor-command-lines-with-rspec/) which mentions [this capture method](https://github.com/erikhuda/thor/blob/d634d240bdc0462fe677031e1dc6ed656e54f27e/spec/helper.rb#L49-L60) in Thor's _spec_helper_. Turns out this is kinda generic, and we can paste it right into our Gem's own *spec_helper*.

But wait, don't call yet, because _then_ I was pointed towards [this Stack Overflow post](http://stackoverflow.com/questions/1480537/how-can-i-validate-exits-and-aborts-in-rspec/28047771#28047771) about validating exits in Rspec, and _that_ led me to [Rspec's `output` matcher](https://www.relishapp.com/rspec/rspec-expectations/docs/built-in-matchers/output-matcher) which appears to make all of the foregoing redundant.

So how does this all fit together?

### Simple match

```ruby
module Banjaxer
  describe CLI do
    let :subject do
      described_class.new
    end

    it 'has a version' do
      expect { subject.version }.to output(/^banjaxer version #{VERSION}$/).to_stdout
    end
  end
end
```

```ruby
module Banjaxer
  class CLI < Thor
    desc 'version', 'Print banjaxer version'
    def version
      puts "banjaxer version #{VERSION}"
    end
    map %w(-v --version) => :version
  end
end
```

In the spec, we set up a instance of our class, which is a _Thor_, then we call its `#version` method and inspect whatever lands on STDOUT.

There is a certain amount of sleight-of-hand going on in this: note that our argument to the _output_ matcher is a regex, even though we really want to match a string. That's because the actual output string will have a `"\n"` on the end of it, so we'd have to match that explicitly.

### With an argument

```ruby
module Banjaxer
  describe CLI do
    let :subject do
      described_class.new
    end

    it 'gets the url', :vcr do
      expect { subject.get_url 'http://uncleclive.herokuapp.com/banjax' }.to output(/^Content-Length is 808$/).to_stdout
    end
  end
end
```

```ruby
module Banjaxer
  class CLI < Thor
    desc 'get url', 'GET a url and tell us the Content-Length'
    def get_url url
      h = HTTParty.get url, headers: { 'Accept' => 'application/json' }
      puts "Content-Length is #{h.headers['Content-Length']}"
    end
  end
end
```

We might notice some more prestidigitation here, when we consider how Thor works: it takes something like `banjaxer get_url http://uncleclive.herokuapp.com/banjax` from STDIN, and turns that (via the `./exe/banjaxer` executable) into a call to `#version('http://uncleclive.herokuapp.com/banjax')` - we're bypassing that
step and making the method call directly. The corresponding Aruba:

```
Scenario: Get url		
  When I successfully run `multichain get_url http://uncleclive.herokuapp.com/banjax`		
  Then the output should contain "Content-Length is 808"
```

will do _exactly_ what it says, which may be a more accurate test, but notice that we've dropped a `:vcr` into the Rspec version [_and it worked as expected_](https://github.com/theodi/banjaxer/blob/ed1a4801e1f250113310d607eee5e903200bfac2/spec/fixtures/vcr/Banjaxer_CLI/gets_the_url.yml), which simply would not happen with Aruba.

### With options

```ruby
module Banjaxer
  describe CLI do
    let :subject do
      described_class.new
    end

    context 'with options' do
      it 'can handle an option' do
        subject.options = {json: true}
        expect { subject.embiggen 'the smallest man' }.to output(/^{"embiggening":"the smallest man"}/).to_stdout
      end
    end
  end
end
```

```ruby
module Banjaxer
  class CLI < Thor
    desc 'embiggen', 'Embiggen something'
    method_option :json,
                  type: :boolean,
                  aliases: '-j',
                  description: 'Return JSON on the console'
    def embiggen value
      if options[:json]
        puts({ embiggening: value }.to_json)
      else
        puts "embiggening #{value}"
      end
    end
  end
end
```

Some more trickery here, which took me a little while to figure out: when we pass options on the command-line, Thor shoves them into the _options_ hash on the instance. So in our spec, we set up that hash ourselves with `subject.options = {json: true}` and then call the method.

### Testing exit statuses

```ruby
module Banjaxer
  describe CLI do
    let :subject do
      described_class.new
    end

    context 'deal with exit codes' do
      it 'exits with a zero by default' do
        expect { subject.cromulise }.to exit_with_status 0
      end
    end
  end
end
```

```ruby
module Banjaxer
  class CLI < Thor
    desc 'cromulise', 'Exit with the supplied status'
    def cromulise status = 'zero'
      lookups = {
        'zero' => 0,
        'one' => 1
      }
      code = lookups.fetch(status, 99)

      puts "Exiting with a #{code}"
      exit code
    end
  end
end
```

Checking the exit status is supported out-of-the-box in Aruba:

```
Scenario: Get version
  When I run `multichain -v`
  Then the exit status should be 0
```

but for Rspec, we have to cook up our own [custom matcher](https://www.relishapp.com/rspec/rspec-expectations/v/2-4/docs/custom-matchers/define-matcher):

```ruby
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
```
