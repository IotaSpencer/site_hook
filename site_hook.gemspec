
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "site_hook/version"

Gem::Specification.new do |spec|
  spec.name = "site_hook"
  spec.version = SiteHook::VERSION
  spec.authors = ["Ken Spencer"]
  spec.email = ["me@iotaspencer.me"]

  spec.summary = %q{Catch a github webhook and execute a plugin}
  spec.homepage = 'https://iotaspencer.me/projects/site_hook/'
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["source_uri"] = 'https://github.com/IotaSpencer/site_hook'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec)/})
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency 'sinatra', '~> 2.0'
  spec.add_runtime_dependency 'sinatra-contrib', '~> 2.0'
  spec.add_runtime_dependency 'thor', '~> 0.20'
  spec.add_runtime_dependency 'paint', '~> 2.0'
  spec.add_runtime_dependency 'git', '~> 1.3'
  spec.add_runtime_dependency 'logging', '~> 2.2'
  spec.add_runtime_dependency 'pry', '~> 0.11'
  spec.add_runtime_dependency 'activesupport', '~> 5.1'
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
