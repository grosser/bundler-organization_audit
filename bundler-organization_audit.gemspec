name = "bundler-organization_audit"
require "./lib/#{name.gsub("-","/")}/version"

Gem::Specification.new name, Bundler::OrganizationAudit::VERSION do |s|
  s.summary = s.description = "Audit all Gemfiles of a user/organization on github for unpatched versions"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files lib bin`.split("\n")
  s.license = "MIT"
  s.executables = ["bundle-organization-audit"]
  s.add_runtime_dependency "organization_audit", ">= 0.2.0"
  s.required_ruby_version = '>= 2.0.0'
end
