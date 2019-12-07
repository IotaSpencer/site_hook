require 'super_callbacks'
module SiteHook
  module Templates
    class Logs
      include SuperCallbacks
      before :created_log_log_header do 
        @@time = Time.now.utc.localtime.strftime("%Y%m%dT%H%M%SZ%Z")
      end
      ###
      # Puts the log header to the start of the log files
      # @param [String,File,Pathname] file file to  
      # @return NilClass
      ###
      def created_log_log_header
        header = "### Log file created at #{@@time}"
      end
    end
  end
end