# require 'openssl'
# require 'hpricot'
# require 'open-uri'
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
# 
# def isempty(cell)
#   cell.to_s.strip == "<td>&nbsp;</td>"
# end
# 
# doc = open('https://enr-apps.as.cmu.edu/assets/SOC/sched_layout_fall.htm') { |f| Hpricot(f) }
# table = doc.search("//table")
# rows = (table/"tr")
# 
# (0...rows.length).to_a.each do |i|
#   cells = (rows[i]/"td")
#   prev_cells = (rows[i-1]/"td") if i > 0
#   prev_prev_cells = (rows[i-2]/"td") if i > 1
# 
#   if ( cells[1] && !isempty(cells[1]) && isempty(cells[2]) && isempty(cells[0]) &&
#     prev_cells &&  prev_cells[1] && !isempty(prev_cells[1]) && isempty(prev_cells[2]) && isempty(prev_cells[3]) &&
#     prev_prev_cells &&  prev_prev_cells[1] && !isempty(prev_prev_cells[1]) && isempty(prev_prev_cells[2]) && isempty(prev_prev_cells[3]))
#     puts "------------"
#     puts "cells[0]"+cells[0].to_s
#     puts prev_prev_cells[1]
#     puts prev_cells[1]
#     puts cells[1]
#   end
#   # number = cells[0].inner_text if cells[0]
#   # name = cells[1].inner_text if cells[1]
#   # units = cells[2].inner_text if cells[2]
#   # section = cells[3].inner_text if cells[3]
#   # 
#   # 
#   # puts cells[1].inner_text if cells[1]
#   
# end

user1 = User.create(:uid => "1326120295", :name => "Eric Wu")
user2 = User.create(:uid => "1326120240", :name => "Jen")



c1 = Course.create(:number => '15-213', :name => 'Computer Systems', :has_recitation => false)

l1 = Lecture.create(:section => '1', :course_id => c1.id)
lst1 = LectureSectionTime.create(:day => 'monday', :begin => '1330', :end => '1500', :lecture_id => l1.id)
l2 = Lecture.create(:section => '2', :course_id => c1.id)
lst2 = LectureSectionTime.create(:day => 'friday', :begin => '830', :end => '900', :lecture_id => l2.id)

sc1 = ScheduledCourse.create(:course_id => c1.id, :lecture_section => '1')


Schedule.create(:scheduled_course_id => sc1, :user_id => user1.id)
Schedule.create(:scheduled_course_id => sc1, :user_id => user2.id)
