module SiteHook
  class Prompt
    def self.inherited(base)
      base.class_eval do
        Prompt.class_variable_set(:'@@runnable', runnable)
      end
    end
    define_singleton_method :runnable do |mlist|
      puts mlist
    end
    def self.run
    end
  end
end