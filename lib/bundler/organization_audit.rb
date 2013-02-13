require "bundler/organization_audit/version"
require "tmpdir"
require "bundler/organization_audit/repo"

module Bundler
  module OrganizationAudit
    class << self
      def run(options)
        vulnerable = find_vulnerable(options).map(&:url)
        vulnerable -= (options[:ignore] || [])
        if vulnerable.size == 0
          0
        else
          $stderr.puts "Vulnerable:"
          puts vulnerable
          1
        end
      end

      private

      def download_file(repo, file, options)
        return unless content = repo.content(file, options)
        File.open(file, "w") { |f| f.write content }
      end

      def find_vulnerable(options)
        Repo.all(options).select do |repo|
          audit_repo(repo, options)
        end
      end

      def audit_repo(repo, options)
        success = false
        $stderr.puts repo.project
        in_temp_dir do
          if download_file(repo, "Gemfile.lock", options)
            if options[:ignore_gems] && repo.gem?(options)
              $stderr.puts "Ignored because it's a gem"
            else
              success = !sh("bundle-audit")
            end
          else
            $stderr.puts "No Gemfile.lock found"
          end
        end
        $stderr.puts ""
        success
      rescue Exception => e
        $stderr.puts "Error auditing #{repo.project} (#{e})"
      end

      def in_temp_dir(&block)
        Dir.mktmpdir { |dir| Dir.chdir(dir, &block) }
      end

      def sh(cmd)
        $stderr.puts cmd
        IO.popen(cmd) do |pipe|
          while str = pipe.gets
            $stderr.puts str
          end
        end
        $?.success?
      end
    end
  end
end
