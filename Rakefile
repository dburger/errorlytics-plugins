require 'rake/clean'

# Attempts to return the value of a string constant defined in php as:
# define('ERRORLYTICS_API_VERSION', '1.0');
# very strict regex for now.
def get_php_string_constant(constant_name, source)
  (source =~ /^define\('#{constant_name}', '(.*)'\);$/) ? $1 : nil
end

BUILDDIR = File.join(File.dirname(__FILE__), 'build')
TEXT_REPLACEMENTS = {
  '$ERRORLYTICS_URL$' => 'http://<%= DEFAULT_URL_HOST %>',
  '$YOUR_SECRET_KEY$' => '<%= @website.secret_key %>',
  '$YOUR_ACCOUNT_ID$' => '<%= @website.account.id %>',
  '$YOUR_WEBSITE_ID$' => '<%= @website.id %>',
  '$YOUR_ERRORLYTICS_PATH$' => '<%= account_website_errors_path(@account, @website) %>'
}
CLEAN.include(BUILDDIR)

task :default => :build_all

task :build_all => [:drupal, :jsp, :php, :wordpress]

directory BUILDDIR

# drupal

DRUPALS = {'5.x' => nil, '6.x' => nil}

DRUPALS.each do |drupal_version, plugin_version|
  src_directory = "drupal/#{drupal_version}"
  drupal_src = File.open("#{src_directory}/errorlytics/errorlytics.module").read
  plugin_version = get_php_string_constant('ERRORLYTICS_PLUGIN_VERSION', drupal_src)
  raise "Unable to determine plugin version for drupal #{drupal_version}" if !plugin_version
  DRUPALS[drupal_version] = plugin_version
  target_filename = "errorlytics-drupal-#{drupal_version}-#{plugin_version}.zip"
  target_fullpath = "#{BUILDDIR}/#{target_filename}"
  sources = FileList["drupal/#{drupal_version}/errorlytics/*"]
  file target_fullpath => sources do
    cmd = "cd drupal/#{drupal_version}"
    cmd << " && zip -r #{target_filename} errorlytics"
    cmd << " && mv #{target_filename} #{BUILDDIR}"
    system(cmd)
  end
  task :"drupal_#{drupal_version}-#{plugin_version}" => [BUILDDIR, target_fullpath]
end
task :drupal => (DRUPALS.map do |drupal_version, plugin_version|
  "drupal_#{drupal_version}-#{plugin_version}"
end)

# jsp

file "#{BUILDDIR}/errorlytics.jsp" => 'jsp/errorlytics.jsp' do
  jsp_source = File.open('jsp/errorlytics.jsp').read
  jsp_source.gsub!('<%', '<%%')
  TEXT_REPLACEMENTS.each {|k, v| jsp_source.gsub!(k, v)}
  File.open("#{BUILDDIR}/errorlytics.jsp", 'w') {|f| f.write(jsp_source)}
end
task :jsp => [BUILDDIR, "#{BUILDDIR}/errorlytics.jsp"]

# php

file "#{BUILDDIR}/errorlytics.php" => 'php/errorlytics.php' do
  php_source = File.open('php/errorlytics.php').read
  TEXT_REPLACEMENTS.each {|k, v| php_source.gsub!(k, v)}
  File.open("#{BUILDDIR}/errorlytics.php", 'w') {|f| f.write(php_source)}
end
task :php => [BUILDDIR, "#{BUILDDIR}/errorlytics.php"]

# wordpress

src_directory = 'wordpress'
wordpress_src = File.open("#{src_directory}/errorlytics/errorlytics.php").read
plugin_version = get_php_string_constant('ERRORLYTICS_PLUGIN_VERSION', wordpress_src)
raise "Unable to determine plugin version for wordpress" if !plugin_version
target_filename = "errorlytics-wordpress-2.x-#{plugin_version}.zip"

file "#{BUILDDIR}/#{target_filename}" => FileList['#{src_directory}/errorlytics/*'] do
  cmd = "cd #{src_directory}"
  cmd << " && zip -r #{target_filename} errorlytics"
  cmd << " && mv #{target_filename} #{BUILDDIR}"
  system(cmd)
end
task :wordpress => [BUILDDIR, "#{BUILDDIR}/#{target_filename}"]
