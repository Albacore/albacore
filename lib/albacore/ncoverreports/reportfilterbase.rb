require 'albacore/support/updateattributes'

module NCover
  class ReportFilterBase
    include UpdateAttributes
    
    attr_accessor :filter,
                  :filter_type,
                  :item_type, 
                  :is_regex
    
    def initialize(item_type, params={})
      @filter = ""
      @item_type = item_type
      @is_regex = false
      @filter_type = :exclude
      update_attributes(params) if params
      super()
    end
  
    def get_filter_options
      f = "\"#{@filter}\""
      f << ":#{@item_type}"
      f << ":#{@is_regex}"
      f << ":#{@filter_type == :include}"
      f
    end
  end
end  
