#! /usr/bin/env ruby

require 'pp'
require 'yaml'
require 'fileutils'

BASE_DIR = File.expand_path(File.dirname(__FILE__)) + "/.."
GIT_DIR = BASE_DIR + "/repo"
DOC_DIR = GIT_DIR + "/doc"
POSTS_DIR = BASE_DIR + "/_posts"
SITE_DIR = BASE_DIR + "/_site"
API_DIR = SITE_DIR + "/api" 

DATE_STR = `date +%Y-%m-%d`.chomp
DATE_STR_W_TIME = `date "+%Y-%m-%d %H:%M:%S"`.chomp

MISSING_HELP_PAGE = <<HTML
<html>
<head><title>Some documentation</title></head>
<body>
	You want to see  some kind of help for <?php echo $_GET["topic"] ?>?<br/>
	Well, to tell you the sad truth, no one ever wrote one.
	Ask the developers for help (yelling at them sometimes also helps).<br/>
	<br/>
	<div style="width: 100%; max-height: 100%; text-align: center">
		<img style="height: 100%" src="http://uqudy.serpens.uberspace.de/wp-content/uploads/2013/09/CIMG0398-1024x768.jpg"/><br/>
		<small>By Johannes Bechberger, CC-BY-SA licensed</small>
	</div>
</body>
</html>
HTML

#Pulls the git repository 
def update_repo
	puts "Update the repository"
	if !File.exists?(GIT_DIR)
		system "mkdir #{GIT_DIR};
	 	  cd #{GIT_DIR}; git clone git@github.com:CVVisualPSETeam/CVVisual.git .
	   	  git remote add origin git@github.com:CVVisualPSETeam/CVVisual.git"
	end
	puts `cd #{GIT_DIR}; git pull origin master; git reset --hard origin/master`
end

#Makes preparations for the use of jekyll
def prepare_jekyll
	File.delete BASE_DIR + "/index.html" if File.exists?(BASE_DIR + "/index.html")
	FileUtils.rm_rf "#{BASE_DIR}/_posts/" if File.exists?("#{BASE_DIR}/_posts")
	FileUtils.mkdir "#{BASE_DIR}/_posts"
	file_name_map = {}
	Dir.new(DOC_DIR).entries.each do |file_name|
		next if [".", ".."].include? file_name
		full_name = DOC_DIR + "/" + file_name
		if File.directory? full_name
			dest_dir = BASE_DIR + "/" + file_name
			print "Copy dir '#{file_name}'..."
			system "rm #{dest_dir} -fr"
			copy_dir full_name, dest_dir
			puts " done..."
		else
			puts "Preparing doc file '#{file_name}'..."
			res_fn = prepare_file(file_name)
			file_name_map[file_name] = res_fn if res_fn != ""
		end
	end
	return file_name_map
end

#Prepares the given file (full path: BASE_DIR / file) and copies it at the
#right destination for use with jekyll
def prepare_file file
	return "" if file == "topics.yml"
	file_lines = File.readlines(DOC_DIR + "/" + file)
	new_file_name = ""
	resulting_file_name = ""
	new_file_content = ""
	return if file_lines.empty? || !file_lines[0].start_with?("#")
	title = file_lines[0].chomp.slice(1..-1)
	file_content = file_lines.drop(1).join
	if file == "index.md"
		resulting_file_name = "index.html"
		new_file_name = BASE_DIR + "/index.md"
		new_file_content = "---
layout: page 
title: #{title}
---

#{file_content}"
	elsif file.include? "-"
		category = file.split("-")[-1].split(".")[0]
		order = 0
		if category.include? ":"
			arr = category.split ":"
			category = arr[0]
			order = arr[1].to_i
		end
		resulting_file_name = "#{category}/#{file.sub(/[^.]+\z/, "html")}"
		new_file_name = "#{POSTS_DIR}/#{DATE_STR}-#{file}"
		new_file_content = "---
layout: default
title: #{title}
date: #{DATE_STR_W_TIME}
category: #{category}
order: #{order}
---

#{file_content}"
	end
	if !new_file_content.empty? && !new_file_name.empty?
		puts "Create file '#{File.basename(new_file_name)}...'"
		File.open(new_file_name, "w") do |f|
			f.write new_file_content
		end
		return resulting_file_name
	end
	return ""
end

#Executes the actual jekyll command
def run_jekyll
	print "jekyll build..."
	FileUtils.rm_rf SITE_DIR if File.exists?(SITE_DIR)
	silent_system "cd #{BASE_DIR}; jekyll build"
	silent_system "cd #{BASE_DIR}; ruby ~/.gem/ruby/1.8/bin/jekyll build"
	puts " done..."
end 

#Executes jekyll and creates the help.php script
def jekyll
	file_name_map = prepare_jekyll
	create_help_script(file_name_map)
	run_jekyll
end

#Creates the help.php script using the topics.yml file
def create_help_script file_name_map
	puts "Create help.php script"
	topic_config = YAML.load_file(DOC_DIR + "/topics.yml")
	topic_map_code = []
	topic_config.each do |topic, file|
		if file_name_map.key? file
			topic_map_code << "'#{topic}' => '#{file_name_map[file]}'"
		end
	end
	php_script = "<?php
$topic_map = array(#{topic_map_code.join(", ")});
if (isset($_GET['topic'])){
	if (isset($topic_map[$_GET['topic']])){
		$topic_url = $topic_map[$_GET['topic']];
		header(\"Location: $topic_url\");
	} else {
		?>
		#{MISSING_HELP_PAGE}
		<?php
	}
}
?>"
	File.open(BASE_DIR + "/help.php", "w") do |file|
		file.write php_script
	end
end

#Executes doxygen
def doxygen
	print "doxygen..."
	silent_system "cd #{BASE_DIR}; doxygen"
	copy_dir BASE_DIR + "/html", API_DIR
	silent_system "cd #{BASE_DIR}; rm -fr *.tmp; rm -fr html"
	puts " done..."
end

#Zips the _site dir
def zip_site
	print "Zipping _site dir..."
	system "zip -r #{SITE_DIR}/site #{SITE_DIR} -q"
	puts " done..."
end

#Copies the source to its destination
def copy_dir source_dir, dest_dir
	system "/bin/cp -rf #{source_dir}/ #{dest_dir}/"
end

#Executes the given command silently on the shell
def silent_system cmd
	system "/bin/sh #{cmd} 2> /dev/null 1> /dev/null"
end

update_repo
jekyll
doxygen
zip_site
