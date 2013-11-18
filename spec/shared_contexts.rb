require 'albacore/paths'

shared_context 'package_metadata_dsl' do
  let :m do
    subject.metadata
  end

  def self.has_value sym, e
    it "should have overridden #{sym}, to be #{e}" do
      m.send(sym).should eq e
    end
  end

  def self.has_dep name, version
    it "has dependency on '#{name}'" do
      m.dependencies.has_key?(name).should be_true
    end
    it "overrode dependency on '#{name}'" do
      m.dependencies[name].version.should eq version
    end
  end

  def self.has_not_dep name
    it "does not have a dependency on #{name}" do
      m.dependencies.has_key?(name).should be_false
    end
  end

  def self.has_file src, target, exclude = nil
    src, target = norm(src), norm(target)
    it "has file[#{src}] (should not be nil)" do
      file = subject.files.find { |f| f.src == src }
     #  puts "## ALL FILES ##"
     #  subject.files.each do |f|
     #    puts "subject.files: #{subject.files}, index of: #{subject.files.find_index { |f| f.src == src }}"
     #    puts "#{f.inspect}"
     #  end
      file.should_not be_nil 
    end

    it "has file[#{src}].target == '#{target}'" do
      file = subject.files.find { |f| f.src == src }
      file.target.should eq target
    end 
  end

  def self.has_not_file src
    src = norm src
    it "has not file[#{src}]" do
      file = subject.files.find { |f| f.src == src }
      file.should be_nil
    end
  end

  def self.norm str
    Albacore::Paths.normalise_slashes str
  end  
end

