require "spec_helper"

describe Bundler::OrganizationAudit do
  it "has a VERSION" do
    Bundler::OrganizationAudit::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe Bundler::OrganizationAudit do
    let(:repo) do
      OrganizationAudit::Repo.new(
        "url" => "https://api.github.com/repos/grosser/parallel"
      )
    end

    describe ".audit_repo" do
      it "audits public repos" do
        out = record_out do
          Bundler::OrganizationAudit.send(:audit_repo, repo, {})
        end
        out.strip.should == "parallel\nbundle-audit\nNo unpatched versions found"
      end
    end

    describe ".run" do
      before do
        Bundler::OrganizationAudit.stub(:puts)
      end

      it "is successful when failed are empty" do
        Bundler::OrganizationAudit.should_receive(:find_vulnerable).and_return([])
        record_out do
          Bundler::OrganizationAudit.run({}).should == 0
        end
      end

      it "fails with failed" do
        Bundler::OrganizationAudit.should_receive(:find_vulnerable).and_return([repo])
        record_out do
          Bundler::OrganizationAudit.run({}).should == 1
        end
      end
    end
  end

  context "CLI" do
    it "can audit a user" do
      result = audit("--user anamartinez --ignore ruby-cldr-timezones --ignore enefele")
      result.should include "I18N-tools\nNo Gemfile.lock found" # did not use audit when not necessary
      result.should include "js-cldr-timezones\nbundle-audit\nNo unpatched versions found" # used audit where necessary
    end

    it "can audit a unpatched user" do
      result = audit("--user user-with-unpatched-apps", :fail => true)
      result.should include "unpatched\nbundle-audit\nName: json\nVersion: 1.5.3" # Individual vulnerabilities
      result.should include "Vulnerable:\nhttps://github.com/user-with-unpatched-apps/unpatched" # Summary
    end

    it "can audit a empty repo user" do
      result = audit("--user user-with-empty-repo")
      result.should include "unpatched\nbundle-audit\nName: json\nVersion: 1.5.3"
    end

    it "only shows failed repo on stdout" do
      result = audit("--user user-with-unpatched-apps 2>/dev/null", :fail => true, :keep_output => true)
      result.should == "https://github.com/user-with-unpatched-apps/unpatched -- user-with-unpatched-apps <michael+unpatched@grosser.it>\n"
    end

    it "ignores repos in --ignore" do
      result = audit("--user user-with-unpatched-apps --ignore https://github.com/user-with-unpatched-apps/unpatched 2>/dev/null", :keep_output => true)
      result.should == ""
    end

    it "ignores advisories via --ignore-advisory" do
      result = audit("--user user-with-unpatched-apps --ignore-advisory OSVDB-90074 2>/dev/null", :keep_output => true)
      result.should == ""
    end

    it "shows --version" do
      audit("--version").should include(Bundler::OrganizationAudit::VERSION)
    end

    it "shows --help" do
      audit("--help").should include("Audit all Gemfiles")
    end

    def audit(command, options={})
      sh("bin/bundle-organization-audit #{command}", options)
    end

    def sh(command, options={})
      result = `#{command} #{"2>&1" unless options[:keep_output]}`
      raise "FAILED #{command}\n#{result}" if $?.success? == !!options[:fail]
      decolorize(result)
    end
  end

  def decolorize(string)
    string.gsub(/\e\[\d+m/, "")
  end

  def record_out
    recorder = StringIO.new
    $stdout, out = recorder, $stdout
    $stderr, err = recorder, $stderr
    yield
    decolorize(recorder.string)
  ensure
    $stdout = out
    $stderr = err
  end

  def in_temp_dir(&block)
    Dir.mktmpdir { |dir| Dir.chdir(dir, &block) }
  end
end
