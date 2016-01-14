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
  When I successfully run `banjaxer get_url http://uncleclive.herokuapp.com/banjax`		
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
  When I run `banjaxer -v`
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

This is surprisingly simple: we just `#call` the method passed in as `actual`, trap the exception it raises, and check its `#status` against the expectation. That `supports_block_expectations` is apparently required because this matcher actually calls a block (but this is a bit magical and I don't fully understand it, I just know that it didn't work without it).

### Inspecting output files

```ruby
module Banjaxer
  describe CLI do
    let :subject do
      described_class.new
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
    end
  end
end
```

```ruby
module Banjaxer
  class CLI < Thor
    desc 'say', 'Say the word'
    def say word, outfile = 'said'
      File.open outfile, 'w' do |f|
        f.write "The word was:\n#{word}"
      end
    end
  end
end
```

Replicating this (very useful) feature of Aruba:

```
Scenario: Write file
  When I run `banjaxer say monorail`
  Then a file named "said" should exist
  And the file named "said" should contain:  
  """
  The word was:
    monorail
  """
```

required considerably more work. The full code for the `have_content` custom matcher (and its supporting bits and pieces) can be seen  [here](https://github.com/theodi/banjaxer/blob/master/spec/support/matchers/have_content.rb). There's quite a bit going on in this, so let's dig in:

#### [Temporary output directory](https://github.com/theodi/banjaxer/blob/master/spec/support/matchers/have_content.rb#L1-L13)

Presumably our CLI app would generate any output files in its Present Working Directory, but we can get Rspec to make us a temporary directory and switch to that before each test (and then bounce back out of it afterwards). Notice that it deletes the _tmp/_ directory before it starts, _not_ at the end of the run. I stole this idea from Aruba and it means that in the event of a spec failure, we can run just the failing test and then debug by having a look at exactly the output it produced.

#### [Custom matcher](https://github.com/theodi/banjaxer/blob/master/spec/support/matchers/have_content.rb#L15-L39)

This matcher takes the _expected_ string from the spec and reads the _actual_ file, then splits them both into lines and compares them - if it finds a mismatch, then `pass` becomes `false` and we get a failure. The clever stuff is in the next section, though:

#### [Monkey-patching `String`](https://github.com/theodi/banjaxer/blob/master/spec/support/matchers/have_content.rb#L41-L61)

I originally wrote these as normal static methods, but it occurred to me that everything would be a lot more elegant if they were `String` instance methods. The interesting (and possibly brittle) thing here is the `#is_regex` stuff: if the string _looks_ like a Regular Expression (i.e. with leading and trailing slashes) then we take the body of it and turn it into an _actual_ regular expression and then do our comparison against that. I think this may bite me somewhere down the road.

This matcher is significantly more sophisticated than the `exit_with_status` one - so much so that it became necessary to [generate Rspec with Rspec](https://github.com/theodi/banjaxer/blob/master/spec/matcher/have_content_spec.rb)

## Suppressing console output

Any self-respecting CLI app is likely to be generating feedback on the command line, but this is going to pollute our Rspec output. We can suppress it with something like this in the *spec_helper*:

```ruby
RSpec.configure do |config|
  # Suppress CLI output. This *will* break Pry
  original_stderr = $stderr
  original_stdout = $stdout
  config.before(:all) do
    # Redirect stderr and stdout
    $stderr = File.new '/dev/null', 'w'
    $stdout = File.new '/dev/null', 'w'
  end

  config.after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end
end
```

Before each test, we redirect STDOUT and STDERR to `/dev/null`, then bring them back afterwards. Note that this is not platform-independent, you need to something different on Windows, but I don't know what. Also note that this causes _pry_ to do _really_ odd things - disable this if you want to reliably pry into your code (maybe this should be wrapped in an `unless ENV['PRY']` guard of some sort).

## Next steps

I seem to have replicated quite a lot of the functionality of Aruba, but with the added benefit of not using Aruba. I think the thing to do now _might_ be to package this up into a Gem and use it on a real project.

I sincerely hope somebody else finds this useful - I certainly did :)
