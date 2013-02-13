require "bundler/organization_audit/version"
require "open-uri"
require "json"
require "tmpdir"
require "base64"

module Bundler
  module OrganizationAudit
    HOST = "https://api.github.com"

    class << self
      def run(options)
        failed = find_failed(options)
        if failed.size == 0
          exit 0
        else
          puts "Failed:"
          puts failed.map(&:first).map { |url| url.sub(".api", "").sub("/repos", "") }
          exit 1
        end
      end

      def repos(options)
        user = if options[:organization]
          "orgs/#{options[:organization]}"
        elsif options[:user]
          "users/#{options[:user]}"
        else
          "user"
        end
        url = File.join(HOST, user, "repos")

        download_all_pages(url, headers(options[:token])).map do |repo|
          preferred_branch = repo["default_branch"] || repo["master_branch"] || "master"
          [repo["url"], preferred_branch, repo["private"]]
        end
      end

      private

      def download_file(url, branch, private, file, options)
        content = if private
          download_content_via_api(url, branch, file, options)
        else
          download_content_via_raw(url, branch, file)
        end
        File.open(file, "w") { |f| f.write content }
      rescue OpenURI::HTTPError => e
        raise e unless e.message.start_with?("404")
      end

      # increases api rate limit
      def download_content_via_api(url, branch, file, options)
        url = File.join(url, "contents", file, "?ref=#{branch}")
        content = open(url, headers(options.fetch(:token))).read
        content = JSON.load(content)["content"]
        Base64.decode64(content)
      end

      # unlimited
      def download_content_via_raw(url, branch, file)
        url = File.join(url.sub("://api.", "://raw.").sub("/repos/", "/"), branch, file)
        open(url).read
      end

      def headers(token)
        token ? {"Authorization" => "token #{token}"} : {}
      end

      def find_failed(options)
        repos(options).select do |url, branch, private|
          project = url.split("/").last
          puts "\n#{project}"
          audit_repo(url, branch, private, options)
        end
      end

      def audit_repo(url, branch, private, options)
        in_temp_dir do
          if download_file(url, branch, private, "Gemfile.lock", options)
            gemspec = url.split("/").last + ".gemspec"
            if options[:ignore_gems] && download_file(url, branch, private, gemspec, options)
              puts "Ignored because it's a gem"
            else
              not sh("bundle-audit")
            end
          else
            puts "No Gemfile.lock found"
          end
        end
      end

      def in_temp_dir(&block)
        Dir.mktmpdir { |dir| Dir.chdir(dir, &block) }
      end

      def sh(cmd)
        puts cmd
        IO.popen(cmd) do |pipe|
          while str = pipe.gets
            puts str
          end
        end
        $?.success?
      end

      def download_all_pages(url, headers)
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
    end
  end
end
