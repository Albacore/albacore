require 'albacore/paths'

shared_context 'package_metadata_dsl' do
  let :m do
    subject.metadata
  end

  def self.has_value sym, e
    it "should have overridden #{sym}, to be #{e}" do
      expect(m.send(sym)).to eq e
    end
  end

  def self.has_dep name, version, target_framework = nil
    if target_framework.nil?
      it "has dependency on '#{name}'" do
        expect(m.dependencies.has_key?(name)).to be true
      end
      it "overrode dependency on '#{name}'" do
        expect(m.dependencies[name].version).to eq version
      end
    else
      it "has dependency on '#{name}' for #{target_framework}" do
        expect(m.dependencies.has_key?("#{name}|#{target_framework}")).to be true
      end
      it "overrode dependency on '#{name}' for #{target_framework}" do
        expect(m.dependencies["#{name}|#{target_framework}"].version).to eq version
      end
    end
  end

  def self.has_not_dep name, target_framework = nil
    if target_framework.nil?
      it "does not have a dependency on #{name}" do
        expect(m.dependencies.has_key?(name)).to be false
      end
    else
      it "does not have a dependency on #{name} for #{target_framework}" do
        expect(m.dependencies.has_key?("#{name}|#{target_framework}")).to be false
      end
    end
  end

  def self.has_file src, target, exclude = nil
    src, target = norm(src), norm(target)
    it "has file[#{src}] (should not be nil)" do
      file = subject.files.find { |f| f.src == src }
      #puts "## ALL FILES ##"
      #subject.files.each do |f|
      #  puts "file: #{file.inspect}"
      #end
      expect(file).to_not be nil
    end

    it "has file[#{src}].target == '#{target}'" do
      file = subject.files.find { |f| f.src == src }
      expect(file.target).to eq target
    end 
  end

  def self.has_not_file src
    src = norm src
    it "has not file[#{src}]" do
      file = subject.files.find { |f| f.src == src }
      expect(file).to be nil
    end
  end

  def self.norm str
    Albacore::Paths.normalise_slashes str
  end  
end

