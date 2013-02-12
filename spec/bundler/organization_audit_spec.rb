require "spec_helper"

describe Bundler::OrganizationAudit do
  it "has a VERSION" do
    Bundler::OrganizationAudit::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe Bundler::OrganizationAudit do
    let(:config){ YAML.load_file("spec/private.yml") }
    describe ".repos" do
      it "returns the list of public repositories" do
        list = Bundler::OrganizationAudit.repos(:user => "grosser")
        list.should include(["https://github.com/grosser/parallel", "master"])
      end

      if File.exist?("spec/private.yml")
        it "returns the list of private repositories from a user" do
          list = Bundler::OrganizationAudit.repos(:token => config["token"])
          list.should include(["https://github.com/#{config["user"]}/#{config["expected_user"]}", "master"])
        end

        it "returns the list of private repositories from a organization" do
          list = Bundler::OrganizationAudit.repos(:token => config["token"], :organization => config["organization"])
          list.should include(["https://github.com/#{config["organization"]}/#{config["expected_organization"]}", "master"])
        end
      end
    end

    describe ".download_lock_file" do
      if File.exist?("spec/private.yml")
        it "can download a private lockfile" do
          url = "https://github.com/#{config["organization"]}/#{config["expected_organization"]}"
          in_temp_dir do
            Bundler::OrganizationAudit.download_lock_file(url, "master", :raw_token => config["raw_token"], :user => config["user"])
            File.read("Gemfile.lock").should include('i18n (0.')
          end
        end
      end

      it "can download a public lockfile" do
        in_temp_dir do
          Bundler::OrganizationAudit.download_lock_file("https://github.com/grosser/parallel", "master", {})
          File.read("Gemfile.lock").should include('rspec (2')
        end
      end

      def in_temp_dir(&block)
        Dir.mktmpdir { |dir| Dir.chdir(dir, &block) }
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
      result.should include "I18N-tools\nNo Gemfile.lock found"
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
