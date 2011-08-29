require 'rubygems'
require 'hpricot'
require 'openssl'
require 'open-uri'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def isempty(cell)
	str = cell.inner_text.strip
	return true if !str
	
	if str.length == 1
		match = str[/[[:alnum:]]+/]
		return true if !match
		return match.length == 0
	end
	
	return ((str == "&nbsp;") || (str == ""))
end

def isemptystr(str)
	str = str.strip
	return true if !str
	
	if str.length == 1
		match = str[/[[:alnum:]]+/]
		return true if !match
		return match.length == 0
	end
	
	return ((str == "&nbsp;") || (str == ""))
end

def getsection(sec)
	if sec.include? 'Lec'
		if sec == 'Lec'
			return '1'
		end
		return sec[-1,1]
	end
	sec
end

def islecture(sec)
	sec.include? 'Lec'
end

def getday(c)
	case c
	when 'M'
		return 'Monday'
	when 'T'
		return 'Tuesday'
	when 'W'
		return 'Wednesday'
	when 'R'
		return 'Thursday'
	when 'F'
		return 'Friday'
	when 'U'
		return 'Sunday'
	when 'S'
		return 'Saturday'
	end
end

def getdays(days)
	abort "Days was nil or empty" if !days || (days == '') || (isemptystr(days))
	return ['TBA'] if (days == 'TBA')
	
	days_arr = []
	days.each_char do |c|
		days_arr.push getday(c)
	end
	days_arr
end

########################################################
# Debugging ############################################
########################################################
def Coursecreate(map)
	puts "+============================= COURSE =======================================+"
	puts 'num:   ' + map[:number]
	puts 'name:  ' + map[:name]
	puts 'units: ' + map[:units]
	1
end

def Lecturecreate(map)
	puts "    -------- LECTURE --------"
	puts '    section:   ' + map[:section]
	puts '    instrctr:  ' + map[:instructor]
	1
end

def LectureSectionTimecreate(map)
		puts "        ___ LEC SEC TIME ___"
		puts '        day:   ' + map[:day]
		puts '        begin: ' + map[:begin]
		puts '        end:   ' + map[:end]
		puts '        loc:   ' + map[:location]
		1
end

def Recitationcreate(map)
		puts "        ---- RECITATION ----"
		puts '        section:   ' + map[:section]
		1
end

def RecitationSectionTimecreate(map)
		puts "            ___ REC SEC TIME ___"
		puts '            day:   ' + map[:day]
		puts '            begin: ' + map[:begin]
		puts '            end:   ' + map[:end]
		puts '            loc:   ' + map[:location]
		1
end
##########################################################
##########################################################
##########################################################

def timetominutes(time)     
return -1 if !time || time == ''

is_pm = (time.include? 'PM')
times = time[0,5].split(':')
hour = times[0]
min = times[1]

if (hour.include? "12")
	hour = (hour.to_i - 12)
end

if is_pm
	hour = (hour.to_i + 12)
end

(hour.to_i*60 + min.to_i)
end

def reformatunits(units)
  units.gsub!(',', '-')
  split = units.split('-')
  if split[0] == split[-1]
    units = split[0].to_f.to_s
  else
    first = split[0].to_f
    second = split[-1].to_f
    units = first.to_s + '-' + second.to_s
  end

  units
end

# If begin_time > end_time, SoC fucked up, so we fix it for them
def validatetimes(begin_time, end_time)
  if (begin_time > end_time)
    if (begin_time >= 720 && end_time >= 720)
      begin_time -= 720
    else
      end_time += 720
    end
  end
  
  return [begin_time, end_time]
end

######################
file = 'https://enr-apps.as.cmu.edu/assets/SOC/sched_layout_fall.htm'
#file = 'scheduleman_small.html'

if Rails.env.production?
	parse_file = File.new("#{RAILS_ROOT}/tmp/parse_file_#{Process.pid}.html", "w")
else
	parse_file = File.new("parse_file.html", "w")
end
file = open(file)

File.readlines(file).each do |line|
	if line.include? 'Lec/Sec'
		open(parse_file, 'a') { |f| f.puts '<TABLE>' }
	elsif line.include? '<B>'
		open(parse_file, 'a') { |f| f.puts '<TR>' }
	else
		open(parse_file, 'a') { |f| f.puts line }
	end
end


doc = open(parse_file) { |f| Hpricot(f) }
table = doc.search("//table")
rows = (table/"tr")

######################

catch(:done) do
	i = 0
	while i < rows.length
	
		cells = (rows[i]/"td")
	
		# if 'Title' is empty, it is a category, not a course
		if (!isempty(cells[0]) && isempty(cells[1])) || (cells[0].inner_text == 'Course') || (isempty(cells[0]))
			puts '*** SKIPPING ***' + cells.to_s
			i += 1
			next
		end

		throw :done if i >= rows.length
	
		abort 'Error (1)' if isempty(cells[0]) || isempty(cells[1]) || isempty(cells[2])
    
    # Prints name and number so that I know something's happening
    puts cells[0].inner_text + ' ' + cells[1].inner_text
		
		number = cells[0].inner_text
		number.insert(2, '-')
    # Create Course
		db_course = Course.create(:number => number,
															:name		=> cells[1].inner_text,
															:units	=> reformatunits(cells[2].inner_text))

		# Loop through Course info, creating lectures/recitations, etc.
		begin
			# If course name is long and takes two vertical rows, move on to next row
			if isempty(cells[3]) && isempty(cells[4])
				i += 1
				throw :done if i >= rows.length
				cells = (rows[i]/"td")
			end
		
			# Create Lecture	
			section = cells[3].inner_text
			db_lecture = Lecture.create(:course_id	=> db_course.id,
																	:section		=> getsection(section),
																	:instructor => cells[8].inner_text)
	
			# Create all the Lecture Section Times, attaching them to Lecture
			db_lec_sec_time = nil
			begin
			  times = validatetimes(timetominutes(cells[5].inner_text), timetominutes(cells[6].inner_text))
				getdays(cells[4].inner_text).each do |day|
					db_lec_sec_time = LectureSectionTime.create(:lecture_id => db_lecture.id,
																											:day 				=> day,
																											:begin 			=> times[0],
																											:end 				=> times[1],
																											:location 	=> cells[7].inner_text)
				end
				i += 1
				throw :done if i >= rows.length
				cells = (rows[i]/"td")
			end while isempty(cells[3]) && isempty(cells[0]) && isempty(cells[1])
	
			abort 'Lecture section time was nil!' if !db_lec_sec_time
	
			# Check if lecture section is 'Lec' and contains recitations under it
			if islecture(section)
				# Loop through course sections that take multiple rows
				while i < rows.length
					cells = (rows[i]/"td")
					if !isempty(cells[0]) || islecture(cells[3].inner_text)
						break
					end
			
					# If course name is long and takes two vertical rows, move on to next row
					if isempty(cells[3]) && isempty(cells[4])
						i += 1
						throw :done if i >= rows.length
						cells = (rows[i]/"td")
					end
			
					# Create Recitation
					db_recitation = Recitation.create(:lecture_id	=> db_lecture.id,
																						:section 		=> getsection(cells[3].inner_text),
																						:instructor => cells[8].inner_text)
		
					db_rec_sec_time = nil
					# Create all Recitation Section Times, attatching them to Recitation
					begin
					  times = validatetimes(timetominutes(cells[5].inner_text), timetominutes(cells[6].inner_text))
						getdays(cells[4].inner_text).each do |day|
							db_rec_sec_time = RecitationSectionTime.create(	:recitation_id => db_recitation.id,
																															:day 				=> day,
																															:begin 			=> times[0],
        																											:end 				=> times[1],
																															:location 	=> cells[7].inner_text)
						end
						i += 1
						throw :done if i >= rows.length
						cells = (rows[i]/"td")
					end while isempty(cells[3]) && isempty(cells[0]) && isempty(cells[1])
				
					abort 'Recitation section time was nil!' if !db_rec_sec_time
				
				end
			end
		end while isempty(cells[0])
	
	end
end

