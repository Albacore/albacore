require 'rspec'
require 'albacore/albacore_module'

RSpec.configure do |config|
  config.before(:each) do
    @logout = StringIO.new
    @output = StringIO.new
    ::Albacore.set_application(::Albacore::Application.new(@logout, @output))
    ::Albacore.log_level = Logger::INFO
    #::Albacore.set_application(::Albacore::Application.new)
  end
end
