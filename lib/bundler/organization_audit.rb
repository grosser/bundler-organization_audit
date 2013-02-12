require "bundler/organization_audit/version"
require "open-uri"
require "json"
require "tmpdir"

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
          puts failed.map(&:first)
          exit 1
        end
      end

      def download_lock_file(url, branch, options)
        lock_file = "Gemfile.lock"
        url = File.join(url.sub("://", "://raw."), branch, lock_file)
        if options[:raw_token] && options[:user]
          url << "?login=#{options[:user]}&token=#{options[:raw_token]}"
        end
        content = open(url).read
        File.open(lock_file, "w") { |f| f.write content }
      rescue OpenURI::HTTPError
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
        headers = (options[:token] ? {"Authorization" => "token #{options[:token]}"} : {})

        download_all_pages(url, headers).map do |repo|
          preferred_branch = repo["default_branch"] || repo["master_branch"] || "master"
          [repo["url"].sub("api.", "").sub("/repos/", "/"), preferred_branch]
        end
      end

      private

      def find_failed(options)
        in_temp_dir do
          repos(options).select do |url, branch|
            project = url.split("/").last
            puts "\n#{project}"
            if download_lock_file(url, branch, options)
              not sh("bundle-audit")
            else
              puts "No Gemfile.lock found"
            end
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
