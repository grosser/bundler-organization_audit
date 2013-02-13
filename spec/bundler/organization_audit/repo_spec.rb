require "spec_helper"

describe Bundler::OrganizationAudit::Repo do
  let(:config){ YAML.load_file("spec/private.yml") }
  let(:repo) do
    Bundler::OrganizationAudit::Repo.new(
      "url" => "https://api.github.com/repos/grosser/parallel"
    )
  end

  describe ".all" do
    it "returns the list of public repositories" do
      # use a big account -> make sure pagination works
      list = Bundler::OrganizationAudit::Repo.all(:user => "grosser")
      list.map(&:url).should include("https://github.com/grosser/parallel")
    end

    if File.exist?("spec/private.yml")
      it "returns the list of private repositories from a user" do
        list = Bundler::OrganizationAudit::Repo.all(:token => config["token"])
        list.map(&:url).should include("https://github.com/#{config["user"]}/#{config["expected_user"]}")
      end

      it "returns the list of private repositories from a organization" do
        list = Bundler::OrganizationAudit::Repo.all(:token => config["token"], :organization => config["organization"])
        list.map(&:url).should include("https://github.com/#{config["organization"]}/#{config["expected_organization"]}")
      end
    end
  end

  describe ".content" do
    it "can download a public file" do
      repo.content("Gemfile.lock").should include('rspec (2')
    end

    if File.exist?("spec/private.yml")
      it "can download a private file" do
        url = "https://api.github.com/repos/#{config["organization"]}/#{config["expected_organization"]}"
        repo = Bundler::OrganizationAudit::Repo.new(
          "url" => url, "private" => true
        )
        content = repo.content("Gemfile.lock", :token => config["token"], :user => config["user"])
        content.should include('i18n (0.')
      end
    end
  end
end

