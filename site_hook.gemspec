require 'pathname'
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'site_hook/version'

Gem::Specification.new do |spec|
  spec.name = 'site_hook'
  spec.version = SiteHook::VERSION
  spec.authors = ['Ken Spencer']
  spec.email = ['me@iotaspencer.me']

  spec.summary = %q{Catch a POST request from a git service push webhook and build a jekyll site.}
  spec.homepage = 'https://iotaspencer.me/projects/site_hook/'
  spec.license = 'MIT'
  spec.licenses = ['MIT']
  spec.required_ruby_version = '>= 2.3'
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata = {
      'source_uri' => 'https://github.com/IotaSpencer/site_hook',
      'source_code_uri' => 'https://github.com/IotaSpencer/site_hook',
      'tutorial_uri' => 'https://iotaspencer.me/projects/site_hook/',
      'documentation_uri' => 'https://iotaspencer.me/projects/site_hook'

  }
  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(tests)/})
  end
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{^bin/}) do |f|
    wanted_bins = %w[site_hook]
    File.basename(f) if wanted_bins.include?(Pathname.new(f).basename.to_s)
  end
  spec.require_paths = ['lib']
  spec.add_dependency 'git', '~> 1.3'
  spec.add_dependency 'highline', '~> 2.0.1'
  spec.add_dependency 'grape', '~> 1.2.3'
  spec.add_dependency 'paint', '~> 2.0'
  spec.add_dependency 'puma'
  spec.add_dependency 'random_password', '~> 0.1.1'
  spec.add_dependency 'recursive-open-struct', '~> 1.1'
  spec.add_dependency 'thor', '~> 0.20.3'
  spec.add_development_dependency 'rspec', '3.8.0'
  spec.add_development_dependency 'aruba', '~> 0.14.8'
  spec.add_development_dependency 'bundler', '~> 1.16.1', '< 2.0'
  spec.add_development_dependency 'cucumber', '>= 3.1.2'
  spec.add_development_dependency 'pry', '~> 0.12.2'
  spec.add_development_dependency 'rake', '~> 10.0'


  spec.post_install_message = <<~POSTINSTALL
    site_hook 0.9.*+ introduces breaking configuration changes!

   1) .shrc/config -> root:host and root:port directives should now be located in
    root:webhook:host and root:webhook:port

    Tutorials on site_hook configuration, installation and setup
    can be seen on https://iotaspencer.me/projects/site_hook

  POSTINSTALL
end
