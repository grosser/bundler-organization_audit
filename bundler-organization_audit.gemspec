$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
name = "bundler-organization_audit"
require "#{name.gsub("-","/")}/version"

Gem::Specification.new name, Bundler::OrganizationAudit::VERSION do |s|
  s.summary = s.description = "Audit all Gemfiles of a user/organization on github for unpatched versions"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files lib bin`.split("\n")
  s.license = "MIT"
  cert = File.expand_path("~/.ssh/gem-private-key-AUTHOR_GITHUB.pem")
  if File.exist?(cert)
    s.signing_key = cert
    s.cert_chain = ["gem-public_cert.pem"]
  end
  s.executables = ["bundle-organization-audit"]
  s.add_runtime_dependency "json"
end
