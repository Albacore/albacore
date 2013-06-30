require 'rspec'
require 'albacore/albacore_module'

RSpec.configure do |config|
  config.before(:each) do
    @logout = StringIO.new
    #@logout = STDOUT
    @output = StringIO.new
    ::Albacore.set_application(::Albacore::Application.new(@logout, @output))
    ::Albacore.log_level = Logger::DEBUG
    @logger = ::Albacore.application.logger
    #::Albacore.set_application(::Albacore::Application.new)
  end
end
