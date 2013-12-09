require 'albacore/support/updateattributes'

module NCover
  class ReportFilterBase
    include UpdateAttributes
    
    attr_accessor :filter, :filter_type, :item_type, :is_regex
    
    def initialize(item_type, params={})
      @filter = ""
      @item_type = item_type
      @is_regex = false
      @filter_type = :exclude
      update_attributes(params) if params
      super()
    end
  
    def get_filter_options
      filter = "\"#{@filter}\""
      filter << ":#{@item_type}" if @item_type
      filter << ":#{@is_regex}" if @is_regex
      filter << ":#{(@filter_type == :include)}" if @filter_type
      filter
    end
  end
end  
