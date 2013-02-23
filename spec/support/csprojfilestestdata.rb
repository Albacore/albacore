class CsProjFilesTestData
  attr_accessor :added_but_not_on_filesystem, :correct, :on_filesystem_but_not_added
  @@csprojfiles = File.expand_path(File.join(File.dirname(__FILE__), 'csprojfiles'))
  def initialize
  	@added_but_not_on_filesystem = File.join(@@csprojfiles, 'added_but_not_on_filesystem', 'aproject.csproj')
  	@correct = File.join(@@csprojfiles, 'correct', 'aproject.csproj')
  	@on_filesystem_but_not_added = File.join(@@csprojfiles, 'on_filesystem_but_not_added', 'aproject.csproj')
  end
end
