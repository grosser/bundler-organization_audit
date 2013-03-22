$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
name = "bundler-organization_audit"
require "#{name.gsub("-","/")}/version"

Gem::Specification.new name, Bundler::OrganizationAudit::VERSION do |s|
  s.summary = s.description = "Audit all Gemfiles of a user/organization on github for unpatched versions"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = "MIT"
  key = File.expand_path("~/.ssh/gem-private_key.pem")
  if File.exist?(key)
    s.signing_key = key
    s.cert_chain = ["gem-public_cert.pem"]
  else
    puts "No signature"
  end
  s.executables = ["bundle-organization-audit"]
  s.add_runtime_dependency "json"
end
