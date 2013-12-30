require 'albacore/support/updateattributes'

module NCover
  class CodeCoverageBase
    include UpdateAttributes
    
    attr_accessor :coverage_type, 
                  :minimum, 
                  :item_type 
    
    def initialize(coverage_type, params={})
      @coverage_type = coverage_type
      @minimum = 0
      @item_type = :View
      update_attributes(params) if params
      super()
    end
    
    def get_coverage_options
      o = "#{@coverage_type}"
      o << ":#{@minimum}" if @minimum
      o << ":#{@item_type}" if @item_type
      o
    end
  end
end  
  
