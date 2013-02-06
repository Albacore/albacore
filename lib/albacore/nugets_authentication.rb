module Albacore
  module NugetsAuthentication
    # if the nuget feed you're accessing is authenticated, set this username
    attr_accessor :username

    # if the nuget feed you're accessing from is authenticated, set this password
    attr_accessor :password
  end
end
