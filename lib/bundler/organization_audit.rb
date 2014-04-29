require "bundler/organization_audit/version"
require "organization_audit"
require "tmpdir"

module Bundler
  module OrganizationAudit
    class << self
      def run(options)
        vulnerable = find_vulnerable(options)
        if vulnerable.size == 0
          0
        else
          $stderr.puts "Vulnerable:"
          puts vulnerable
          1
        end
      end

      private

      def download_file(repo, file)
        return unless content = repo.content(file)
        File.open(file, "w") { |f| f.write content }
      end

      def find_vulnerable(options)
        ::OrganizationAudit.all(options).select do |repo|
          next if options[:ignore_gems] && repo.gem?
          audit_repo(repo, options)
        end
      end

      def audit_repo(repo, options)
        vulnerable = false
        $stderr.puts repo.name
        in_temp_dir do
          if download_file(repo, "Gemfile.lock")
            command = "bundle-audit"
            if options[:ignore_advisories] && options[:ignore_advisories].any?
              command << " --ignore #{options[:ignore_advisories].join(" ")}"
            end
            vulnerable = !sh(command)
          else
            $stderr.puts "No Gemfile.lock found"
          end
        end
        $stderr.puts ""
        vulnerable
      rescue Exception => e
        $stderr.puts "Error auditing #{repo.name} (#{e})"
        true
      end

      def in_temp_dir(&block)
        Dir.mktmpdir { |dir| Dir.chdir(dir, &block) }
      end

      # http://grosser.it/2010/12/11/sh-without-rake
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
