require "site_hook"
require "site_hook/logger"

module SiteHook
  class Runner
    def initialize(argv = ARGV, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
      @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
    end

    def execute!
      begin
        SiteHook::PreLogger.new($stdin, $stdout, $stderr)
        SiteHook::Config.new
      rescue SiteHook::NoLogsError => e
        FileUtils.mkpath(e.path)
      rescue SiteHook::NoConfigError => e
        TTY::File.create_file(e.path, SiteHook::ConfigSections.all_samples)
      end
      exit_code = begin
                    $stderr = @stderr
                    $stdin = @stdin
                    $stdout = @stdout
                    SiteHook::PreLogger.new($stdin, $stdout, $stderr)
                    SiteHook::Config.new
                    SiteHook::Log.new($stdin, $stdout, $stderr)
                    SiteHook::CLI.start(@argv)
                    0
                  rescue StandardError => e
                    b = e.backtrace
                    unless e.class == SiteHook::NoConfigError
                      STDERR.puts("#{b.shift}: #{e.message} (#{e.class})")
                      STDERR.puts(b.map { |s| "\tfrom #{s}" }.join("\n"))
                      1
                    end
                    0
                  rescue SystemExit => e
                    STDERR.puts e.backtrace
                    STDERR.puts e.status
                    1
                  ensure
                    $stderr = STDERR
                    $stdin = STDIN
                    $stdout = STDOUT
                  end
      @kernel.exit(exit_code)
    end
  end
end
