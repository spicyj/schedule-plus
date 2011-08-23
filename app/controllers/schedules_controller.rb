class SchedulesController < ApplicationController
  def new
    
  end
  
  def import
    parsed = Parser.parse(params[:url])
    @schedule = parsed[:schedule]
    # store imported schedule id in session var to retrieve after oauth
    session[:imported] = @schedule.id
    if request.xhr?
      render :json => parsed
    else
      redirect_to schedules_path
    end
  end
  
  def new
    # release 2
  end

  def show
    if (!params[:id]) 
      if current_user
        @schedule = current_user.main_schedule
      else
        redirect_to root_path
      end
    else
      @schedule = Schedule.find(params[:id])
      if request.xhr?
        render :json => @schedule.to_json(:include =>
          {:scheduled_courses => {:include =>
             {
               :course => {}, 
               :lecture => {:include => :lecture_section_times}, 
               :recitation => {:include => :recitation_section_times}
             }
          }
        })
      else
        
      end
    end
  end

	def get_friends_in_course
		if request.xhr?
			scheduled_course_id = params[:scheduled_course_id]
			course_id = params[:course_id]

			friends_includes = friends.includes(:main_schedule => {:scheduled_courses => 
        [:course, :lecture, :recitation]})
			
      if scheduled_course_id
        sc = ScheduledCourse.find(scheduled_course_id)
        response = Hash.new
        #response[:lecture] = friends.in_lecture(sc.lecture)
        #friends_includes.where('scheduled_courses.lecture.id = ?', sc.lecture_id)

        if sc.recitation
          # response[:recitation] = friends_includes.where('scheduled_courses.recitation.id = ?', sc.recitation_id)
        end

        response[:data] = friends_includes.where('scheduled_courses.id = ?', scheduled_course_id)
        if current_user.main_schedule.scheduled_courses.exists? scheduled_course_id
          response[:me] = current_user.uid 
        else
          response[:me] = nil
        end

        render :json => response.to_json
		  elsif course_id
				render :json => friends_includes.where('courses.id = ?', course_id).to_json
			end

		else
			redirect_to schedules_path
		end

	end

  def add_course
    if request.xhr?
      input = params[:course]
      letter = input[5..-1]
      number = input[0,5]
      
      course = Course.find_by_number(number)
      section = course.find_by_section(letter)
p "COURSE " + course.number
p "SECTION " + section.section

      if course.lectures.find_by_section(letter)
        @course = ScheduledCourse.find_or_create_by_course_id_and_lecture_id(
          :course_id => course.id, :lecture_id => section.id)
      else
        @course = ScheduledCourse.find_or_create_by_course_id_and_lecture_id_and_recitation_id(
          :course_id => course.id, :lecture_id => section.lecture.id, :recitation_id => section.id)
      end

      CourseSelection.create(:schedule_id => current_user.main_schedule.id, :scheduled_course_id => @course.id)
      render :json => @course.to_json(:include => {
        :course => {},
        :lecture => { :include => :lecture_section_times },
        :recitation => { :include => :recitation_section_times }
      })
    else

    end
  end
end
