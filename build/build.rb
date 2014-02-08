#! /usr/bin/env ruby

require 'pp'

BASE_DIR = File.dirname(__FILE__) + "/.."
GIT_DIR = BASE_DIR + "/repo"
DOC_DIR = GIT_DIR + "/doc"
POSTS_DIR = BASE_DIR + "/_posts"
API_DIR = BASE_DIR + "/api" 

DATE_STR = `date +%Y-%m-%d`.chomp
DATE_STR_W_TIME = `date "+%Y-%m-%d %H:%M:%S"`.chomp

#Pulls the git repository 
def update_repo
	puts "Update the repository"
	if !File.exists?(GIT_DIR)
		system "mkdir #{GIT_DIR};
	 	  cd #{GIT_DIR}; git clone git@github.com:CVVisualPSETeam/CVVisual.git .
	   	  git remote add origin git@github.com:CVVisualPSETeam/CVVisual.git"
	end
	#puts `cd #{GIT_DIR}; git pull origin master; git reset --hard origin/master`
end

#Makes preparations for the use of jekyll
def prepare_jekyll
	silent_system "bash 'cd #{BASE_DIR} rm index.html; rm _posts -fr;
   						mkdir _posts'"
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
			prepare_file file_name
		end
	end
end

#Prepares the given file (full path: BASE_DIR / file) and copies it at the
#right destination for use with jekyll
def prepare_file file
	file_lines = File.readlines(DOC_DIR + "/" + file)
	new_file_name = ""
	new_file_content = ""
	return if file_lines.empty? || !file_lines[0].start_with?("#")
	title = file_lines[0].chomp.slice(1..-1)
	file_content = file_lines.drop(1).join
	if file == "index.md"
		new_file_name = BASE_DIR + "/index.html"
		new_file_content = "---
layout: default
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
		new_file_name = "#{POSTS_DIR}/#{DATE_STR}-#{file}"
		new_file_content = "---
layout: page
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
	end
end

#Executes the actual jekyll command
def run_jekyll
	print "jekyll build..."
	silent_system "cd #{BASE_DIR}; jekyll build --destination ."
	silent_system "cd #{BASE_DIR}; ruby ~/.gem/ruby/1.8/bin/jekyll build --destination ."
	puts " done..."
end 

#Executes jekyll
def jekyll
	prepare_jekyll
	run_jekyll
end

#Executes doxygen
def doxygen
	print "doxygen..."
	silent_system "cd #{BASE_DIR}; doxygen"
	copy_dir BASE_DIR + "/html", API_DIR
	silent_system "cd #{BASE_DIR}; rm -fr *.tmp; rm -fr html"
	puts " done..."
end

#Copies the source to its destination
def copy_dir source_dir, dest_dir
	system "cp -rf #{source_dir}/ #{dest_dir}/"
end

#Executes the given command silently on the shell
def silent_system cmd
	system "bash #{cmd} 2> /dev/null 1> /dev/null"
end

update_repo
jekyll
doxygen

