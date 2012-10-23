module Configuration
  module NetVersion
    include Failure
  
    def win_dir
      ENV['windir'] || ENV['WINDIR'] || 'C:/Windows'
    end
   
    def get_net_version(netversion)
      case netversion
        when :net2, :net20, :net3, :net30
          version = 'v2.0.50727'
        when :net35
          version = 'v3.5'
        when :net4, :net40, :net45
          version = 'v4.0.30319'
        else
          fail_with_message "The .NET Framework #{netversion} is not supported"
      end
      
      File.join win_dir, 'Microsoft.NET', 'Framework', version
    end
  end
end
