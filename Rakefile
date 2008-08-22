require 'rake/clean'

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

DRUPALS = ['5.x', '6.x']

DRUPALS.each do |version|
  target_filename = "errorlytics-drupal-#{version}.zip"
  target_fullpath = "#{BUILDDIR}/#{target_filename}"
  sources = FileList["drupal/#{version}/errorlytics/*"]
  file target_fullpath => sources do
    cmd = "cd drupal/#{version}"
    cmd << " && zip -r #{target_filename} errorlytics"
    cmd << " && mv #{target_filename} #{BUILDDIR}"
    system(cmd)
  end
  task :"drupal_#{version}" => [BUILDDIR, target_fullpath]
end
task :drupal => DRUPALS.map {|version| "drupal_#{version}"}

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

file "#{BUILDDIR}/errorlytics-wordpress-2.x.zip" => FileList['wordpress/errorlytics/*'] do
  cmd = "cd wordpress"
  cmd << " && zip -r errorlytics-wordpress-2.x.zip errorlytics"
  cmd << " && mv errorlytics-wordpress-2.x.zip #{BUILDDIR}"
  system(cmd)
end
task :wordpress => [BUILDDIR, "#{BUILDDIR}/errorlytics-wordpress-2.x.zip"]
