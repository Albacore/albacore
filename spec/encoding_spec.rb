describe 'encoding functions' do
  it 'should throw InvalidByteSequenceError by default' do
    # http://www.ruby-doc.org/core-2.1.3/String.html#method-i-encode
    begin
      # it's "valid US-ASCII" from the POV of #encode unless
      # #force_encoding is used
      [0xef].pack('C*').force_encoding('US-ASCII').encode 'utf-8'
      fail 'should throw invalid byte sequence error, because it\'s NOT US-ASCII'
    rescue Encoding::InvalidByteSequenceError
      # yep
    end
  end
  it 'should be replaceable' do
    subj =  [0xef].pack('C*').encode 'utf-8', undef: :replace, invalid: :replace, replace: ''
    expect(subj).to eq ''
  end
end
