$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
name = "bundle_organization_audit"
require "#{name}/version"

Gem::Specification.new name, BundleOrganizationAudit::VERSION do |s|
  s.summary = "Audit all Gemfiles of a user/organization on github for unpatched versions"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = "MIT"
  s.signing_key = File.expand_path("~/.ssh/gem-private_key.pem")
  s.cert_chain = [".public_cert.pem"]
end
