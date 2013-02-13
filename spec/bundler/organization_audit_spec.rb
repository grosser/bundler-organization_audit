require "spec_helper"

describe Bundler::OrganizationAudit do
  it "has a VERSION" do
    Bundler::OrganizationAudit::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe Bundler::OrganizationAudit do
    describe ".audit_repo" do
      let(:repo) do
        Bundler::OrganizationAudit::Repo.new(
          "url" => "https://api.github.com/repos/grosser/parallel"
        )
      end

      it "audits public repos" do
        out = record_stdout do
          Bundler::OrganizationAudit.send(:audit_repo, repo, {})
        end
        out.strip.should == "parallel\nbundle-audit\nNo unpatched versions found"
      end

      it "does not audit ignored repos" do
        out = record_stdout do
          Bundler::OrganizationAudit.send(:audit_repo, repo, :ignore_gems => true)
        end
        out.strip.should == "parallel\nIgnored because it's a gem"
      end
    end

    describe ".run" do
      before do
        Bundler::OrganizationAudit.stub(:puts)
      end

      it "is successful when failed are empty" do
        Bundler::OrganizationAudit.should_receive(:find_failed).and_return([])
        Bundler::OrganizationAudit.should_receive(:exit).with(0)
        Bundler::OrganizationAudit.run({})
      end

      it "fails with failed" do
        Bundler::OrganizationAudit.should_receive(:find_failed).and_return([["url", "branch"]])
        Bundler::OrganizationAudit.should_receive(:exit).with(1)
        Bundler::OrganizationAudit.run({})
      end
    end
  end

  context "CLI" do
    it "can audit a user" do
      result = audit("--user anamartinez")
      result.should include "I18N-tools\nNo Gemfile.lock found" # did not use audit when not necessary
      result.should include "js-cldr-timezones\nbundle-audit\nNo unpatched versions found" # used audit where necessary
    end

    it "can audit a unpatched user" do
      result = audit("--user user-with-unpatched-apps", :fail => true)
      result.should include "unpatched\nbundle-audit\nName: json\nVersion: 1.5.3" # Individual vulnerabilities
      result.should include "Failed:\nhttps://github.com/user-with-unpatched-apps/unpatched" # Summary
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
      result = `#{command} 2>&1`
      raise "FAILED #{command}\n#{result}" if $?.success? == !!options[:fail]
      decolorize(result)
    end
  end

  def decolorize(string)
    string.gsub(/\e\[\d+m/, "")
  end

  def record_stdout
    recorder = StringIO.new
    $stdout, old = recorder, $stdout
    yield
    decolorize(recorder.string)
  ensure
    $stdout = old
  end

  def in_temp_dir(&block)
    Dir.mktmpdir { |dir| Dir.chdir(dir, &block) }
  end
end
