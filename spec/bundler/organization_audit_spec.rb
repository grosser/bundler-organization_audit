require "spec_helper"

describe Bundler::OrganizationAudit do
  it "has a VERSION" do
    Bundler::OrganizationAudit::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe Bundler::OrganizationAudit do
    describe ".repos" do
      it "returns the list of public repositories" do
        list = Bundler::OrganizationAudit.repos(:user => "grosser")
        list.should include(["https://github.com/grosser/parallel", "master"])
      end

      if File.exist?("spec/private.yml")
        it "returns the list of private repositories" do
          config = YAML.load_file("spec/private.yml")
          list = Bundler::OrganizationAudit.repos(:token => config["token"])
          list.should include(["https://github.com/#{config["user"]}/#{config["expected"]}", "master"])
        end
      end
    end

    describe ".run" do
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
      result = audit("--user anamartinez").gsub(/\e\[\d+m/, "")
      result.should include "No Gemfile.lock found for I18N-tools"
      result.should include "js-cldr-timezones\nbundle-audit\nNo unpatched versions found"
    end

    it "shows --version" do
      audit("--version").should include(Bundler::OrganizationAudit::VERSION)
    end

    it "shows --help" do
      audit("--help").should include("Audit all Gemfiles")
    end

    def audit(command)
      sh("bin/bundle-organization-audit #{command}")
    end

    def sh(command, options={})
      result = `#{command} 2>&1`
      raise "FAILED #{command}\n#{result}" if $?.success? == !!options[:fail]
      result
    end
  end
end
