module SiteHook
  module Loggers
    autoload :Access, 'site_hook/loggers/access'
    autoload :App, 'site_hook/loggers/app'
    autoload :Build, 'site_hook/loggers/build'
    autoload :Fake, 'site_hook/loggers/fake'
    autoload :Git, 'site_hook/loggers/git'
    autoload :Hook, 'site_hook/loggers/hook'
  end
end