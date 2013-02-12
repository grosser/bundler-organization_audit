require "spec_helper"

describe Bundler::OrganizationAudit do
  it "has a VERSION" do
    Bundler::OrganizationAudit::VERSION.should =~ /^[\.\da-z]+$/
  end

  context "CLI" do
    it "can audit a user" do

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
