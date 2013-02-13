require "open-uri"
require "json"
require "base64"

module Bundler
  module OrganizationAudit
    class Repo
      HOST = "https://api.github.com"

      def initialize(data)
        @data = data
      end

      def gem?(options)
        !!content("#{project}.gemspec", options)
      end

      def url
        api_url.sub("api.", "").sub("/repos", "")
      end
      alias_method :to_s, :url

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

        download_all_pages(url, headers(options[:token])).map { |data| Repo.new(data) }
      end

      def content(file, options={})
        if private?
          download_content_via_api(file, options)
        else
          download_content_via_raw(file)
        end
      rescue OpenURI::HTTPError => e
        raise e unless e.message.start_with?("404")
      end

      def private?
        @data["private"]
      end

      private

      def self.download_all_pages(url, headers)
        results = []
        page = 1
        loop do
          result = JSON.parse(open("#{url}?page=#{page}", headers).read)
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
      def download_content_via_api(file, options)
        url = File.join(api_url, "contents", file, "?ref=#{branch}")
        content = open(url, self.class.headers(options.fetch(:token))).read
        content = JSON.load(content)["content"]
        Base64.decode64(content)
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
