require "open-uri"
require "json"
require "base64"

module Bundler
  module OrganizationAudit
    class Repo
      HOST = "https://api.github.com"

      def initialize(data, token=nil)
        @data = data
        @token = token
      end

      def gem?
        !!content("#{project}.gemspec")
      end

      def url
        api_url.sub("api.", "").sub("/repos", "")
      end

      def to_s
        "#{url} -- #{last_commiter}"
      end

      def project
        api_url.split("/").last
      end

      def self.all(options)
        user = if options[:organization]
          "orgs/#{options[:organization]}"
        elsif options[:user]
          "users/#{options[:user]}"
        else
          "user"
        end
        url = File.join(HOST, user, "repos")

        token = options[:token]
        download_all_pages(url, headers(token)).map { |data| Repo.new(data, token) }
      end

      def content(file)
        @content ||= {}
        @content[file] ||= begin
          if private?
            download_content_via_api(file)
          else
            download_content_via_raw(file)
          end
        end
      rescue OpenURI::HTTPError => e
        raise "Error downloading #{file} from #{url} (#{e})" unless e.message.start_with?("404")
      end

      def private?
        @data["private"]
      end

      def last_commiter
        response = call_api("commits/#{branch}")
        committer = response["commit"]["committer"]
        "#{committer["name"]} <#{committer["email"]}>"
      end

      private

      def self.download_all_pages(url, headers)
        results = []
        page = 1
        loop do
          response = decorate_errors do
            open("#{url}?page=#{page}", headers).read
          end
          result = JSON.parse(response)
          if result.size == 0
            break
          else
            results.concat(result)
            page += 1
          end
        end
        results
      end

      def branch
        @data["default_branch"] || @data["master_branch"] || "master"
      end

      def api_url
        @data["url"]
      end

      def raw_url
        url.sub("://", "://raw.")
      end

      # increases api rate limit
      def download_content_via_api(file)
        content = call_api("contents/#{file}?branch=#{branch}")["content"]
        Base64.decode64(content)
      end

      def call_api(path)
        content = self.class.decorate_errors do
          open(File.join(api_url, path), self.class.headers(@token)).read
        end
        JSON.load(content)
      end

      def self.decorate_errors
        yield
      rescue OpenURI::HTTPError => e
        e.message << " -- body: " << e.io.read
        raise e
      end

      # unlimited
      def download_content_via_raw(file)
        open(File.join(raw_url, branch, file)).read
      end

      def self.headers(token)
        token ? {"Authorization" => "token #{token}"} : {}
      end
    end
  end
end
