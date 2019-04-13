Pod::Spec.new do |s|
s.name = 'YWFMDB'
s.version = '0.3.0'
s.summary = '基于FMDB上的二次封装，直接对model进行操作'
s.homepage = 'https://github.com/flyOfYW/YWFMDB'
s.license = 'MIT'
s.author = { 'flyOfYW' => '1498627884@qq.com' }
s.platform     = :ios, "6.0"
s.source = { :git => 'https://github.com/flyOfYW/YWFMDB.git', :tag => "#{s.version}" }
s.requires_arc = true
s.source_files  = 'YWFMDB/*'
s.default_subspec = 'standard'


# use the built-in library version of sqlite3
s.subspec 'standard' do |ss|
ss.dependency 'FMDB'
ss.source_files  = 'YWFMDB/*'
end



# use SQLCipher and enable -DSQLITE_HAS_CODEC flag
 s.subspec 'SQLCipher' do |ss|
 ss.dependency 'FMDB'
 ss.dependency 'SQLCipher'
 ss.source_files  = 'YWFMDB/*'
 ss.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DSQLITE_HAS_CODEC -DHAVE_USLEEP=1', 'HEADER_SEARCH_PATHS' => 'SQLCipher' }
 end



end

