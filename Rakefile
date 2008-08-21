require 'rake/clean'

BUILDDIR = 'build'
CLEAN.include(BUILDDIR)

task :default => :build_all

task :build_all => [:drupal, :jsp, :php, :wordpress]

directory BUILDDIR

task :drupal => BUILDDIR do
  puts 'TODO'
end

task :jsp => BUILDDIR do
  jsp_source = File.open('java/errorlytics.jsp').read
  jsp_source.gsub!('<%', '<%%')
  jsp_source.sub!('$ERRORLYTICS_URL$', 'http://<%= DEFAULT_URL_HOST %>')
  jsp_source.sub!('$YOUR_SECRET_KEY$', '<%= @website.secret_key %>')
  jsp_source.sub!('$YOUR_ACCOUNT_ID$', '<%= @website.account.id %>')
  jsp_source.sub!('$YOUR_WEBSITE_ID$', '<%= @website.id %>')
  File.open("#{BUILDDIR}/errorlytics.jsp", 'w') {|f| f.write(jsp_source)}
end

task :php => BUILDDIR do
  php_source = File.open('php/errorlytics.php').read
  php_source.sub!('$ERRORLYTICS_URL$', 'http://<%= DEFAULT_URL_HOST %>')
  php_source.sub!('$YOUR_ERRORLYTICS_PATH$',
      '<%= account_website_errors_path(@account, @website) %>')
  php_source.sub!('$YOUR_SECRET_KEY$', '<%= @website.secret_key %>')
  File.open("#{BUILDDIR}/errorlytics.php", 'w') {|f| f.write(php_source)}
end

task :wordpress => BUILDDIR do
  puts 'TODO'
end
