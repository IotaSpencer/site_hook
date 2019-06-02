class String
  def squish!
    strip!
    gsub!(/\s+/, ' ')
    self
  end
  def squish
    dup.squish!
  end
  def underscore!
    self unless /[A-Z-]|::/.match?(self)
    self.to_s.gsub!("::".freeze, "/".freeze)
    self.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'.freeze)
    self.gsub!(/([a-z\d])([A-Z])/, '\1_\2'.freeze)
    self.tr!("-".freeze, "_".freeze)
    self.downcase!
    self
  end
  def underscore
    dup.underscore!
  end
  def camelcase!
    to_s.scan(/\w+/).collect(&:capitalize).join
  end
  def camelcase
    dup.camelcase!
  end
  def camelize!
    to_s.split(/_|\s+/).collect(&:capitalize).join
  end
  def camelize
    dup.camelize!
  end
  def safe_log_name
    self.split('::').last.underscore
  end
end
module SiteHook
  module StrExt
    def StrExt.mkvar(inspection)
      inspection.to_s.tr('.', '_').tr(' ', '_')
    end
    def StrExt.mkatvar(inspection)
      inspection.dup.to_s.insert(0, '@').to_sym
    end
    def StrExt.mkatatvar(inspection)
      inspection.to_s.insert(0, '@').insert(0, '@').to_sym
    end
    def StrExt.rematvar(inspection)
      inspection.to_s.tr('@', '')
    end

    def self.mkmvar(inspection)
      inspection.to_s.tr('@', '').to_sym
    end
  end
end