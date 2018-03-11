require 'site_hook/plugin'
module SiteHook
  class JekyllBuild
    include SiteHook::Plugins::PluginBase
    _name 'jekyll_name'
    _version '0.1.0'
  end
end