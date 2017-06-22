require 'rails'
require 'open-uri-s3'
namespace :spaider do 
	@base_url="http://music.163.com"
	desc "fetch classify"
	task classify: :environment do 
		doc = Nokogiri::HTML(open("#{@base_url}/discover/playlist/"))
		doc.css("div.bd").each do |d|
			d.css("dt").each do |dd|
				Dir::mkdir("#{Rails.root}/files/#{dd.text}") if  !File.directory?("#{Rails.root}/files/#{dd.text}")
				aFile = File.new("#{Rails.root}/files/#{dd.text}/#{dd.text}.txt", "a+")
				d.css("dl a").each do |a|
					if aFile
					   aFile.syswrite("#{a["href"]},#{a.text}\n")
					else
					   puts "Unable to open file!"
					end
				end
				aFile.close
			end
			# puts d.css("dl a").text
		end
	end

	desc "fetch playlist"
	task playlist: :environment do 
		doc = Nokogiri::HTML(open("#{@base_url}/discover/playlist/"))
		doc.css("div.bd").each do |d|
			d.css("dt").each do |dd|
				d.css("dl a").each do |a|
					Dir::mkdir("#{Rails.root}/files/#{dd.text}/#{a.text.gsub(/\//,",")}") if  !File.directory?("#{Rails.root}/files/#{dd.text}/#{a.text.gsub(/\//,",")}")
					open_url("#{@base_url}#{a["href"]}","#{dd.text}/#{a.text.gsub(/\//,",")}","#{a.text.gsub(/\//,",")}")
				end
			end
			# puts d.css("dl a").text
		end
	end
	@array = []
	@album =[]
	def open_url(url,path,name)
		return nil if @array.include?(url)
		doc = Nokogiri::HTML(open("#{url}"))
		urls=doc.css("div.u-page a.zpgi")
		urls.present? && urls.each do |a|
			href ="#{@base_url}#{a["href"]}"
			next if @array.include?(href) || a["href"] == "javascript:void(0)"
			@array << "#{@base_url}#{a["href"]}"

			album(href,path,name)
			open_url(href,path,name)
		end
		return @array.uniq!
	end

	def album(url,path,name)
		doc = Nokogiri::HTML(open(url))
		doc.css("ul.m-cvrlst.f-cb li").each do |li|
				img = li.css("img.j-flag").first["src"]
				title= li.css("p.dec a").first.text
				songs= li.css("p.dec a").first["href"] 
				Dir::mkdir("#{Rails.root}/files/#{path}/songs/") if  !File.directory?("#{Rails.root}/files/#{path}/songs/")
				Dir::mkdir("#{Rails.root}/files/#{path}/lrc/") if  !File.directory?("#{Rails.root}/files/#{path}/lrc/")
				song("#{@base_url}#{songs}","#{Rails.root}/files/#{path}/")
				aFile = File.new("#{Rails.root}/files/#{path}/#{name}_playlist.txt", "a+")
					if aFile
					   aFile.syswrite("#{img},#{title},#{@base_url}#{songs}\n")
					else
					   puts "Unable to open file!"
					end

				aFile.close
		end
	end

	def song(url,path)
		doc = Nokogiri::HTML(open(url))
		# puts doc.css("table.m-table  tbody tr")
		doc.css("ul.f-hide  li").each do |li|
				a =li.css("a").first
				name = a.text
				href = a["href"]
				require 'watir'

					browser = Watir::Browser.new
					browser.goto "#{@base_url}#{href}"
					#div.bd.bd-open.f-brk.f-ib
					puts browser.html
					# => 'Hello World! - Google Search'
					browser.close
				aFile = File.new("#{path}songs/#{name.gsub(/\s|\//,"")[0,20]}.txt", "a+")
					if aFile
					   aFile.syswrite("#{name},#{@base_url}#{href}\n")
					else
					   puts "Unable to open file!"
					end

				aFile.close
		end
	end
end