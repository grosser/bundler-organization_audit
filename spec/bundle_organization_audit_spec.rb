require "spec_helper"

describe BundleOrganizationAudit do
  it "has a VERSION" do
    BundleOrganizationAudit::VERSION.should =~ /^[\.\da-z]+$/
  end
end
