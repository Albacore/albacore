require 'albacore/support/updateattributes'

module NCover
  class CodeCoverageBase
    include UpdateAttributes
    
    attr_accessor :coverage_type, :minimum, :item_type 
    
    def initialize(coverage_type, params={})
      @coverage_type = coverage_type
      @minimum = 0
      @item_type = :View
      update_attributes(params) if params
      super()
    end
    
    def get_coverage_options
      options = "#{@coverage_type}"
      options << ":#{@minimum}" if @minimum
      options << ":#{@item_type}" if @item_type
      options
    end
  end
end  
  
