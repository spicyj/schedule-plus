class User < ActiveRecord::Base
  # omniauth
  has_many :authentications, :dependent => :destroy
  has_many :schedules, :order => "semester_id desc, id asc", :dependent => :destroy

  def first_name
    if name then
      name.split(" ").first
    else
      ""
    end
  end

  def main_schedule(semester=Semester.current)
    schedules.active.by_semester(semester).first
  end

  def courses(semester=Semester.current)
    main_schedule(semester).course_selections.map(&:course)
  end

############################# AUTHENTICATION ####################################

  def apply_omniauth(omniauth)
    self.name = omniauth['user_info']['name'] if name.blank?
    self.uid = omniauth['uid']
    authentications.build(:provider => omniauth['provider'], 
                          :uid => omniauth['uid'],
                          :token => (omniauth['credentials']['token'] rescue nil))
  end

  def fb_uid
    self.authentications.find_by_provider('facebook').token rescue nil
  end
  
  # fb_graph for a user
  def fb
    @fb_user ||= FbGraph::User.me(fb_uid).fetch
  end

  def friends
    if fb
      fids = fb.friends.map(&:identifier)
      User.where(:uid => fids)
      # uids = User.all.collect{|u|u.uid if friends.include? u.uid}.compact
      # FIXME FIXME FIXME PLEASE
      # @friends = fb.friends
    else
      nil
    end
  end

###############################################################################

  def as_json(options={})
    {
      :id => self.id,
      :uid => self.uid,
      :name => self.name,
      :status => self.status
    }
  end

  # true if user is in the course
  def in_course?(course)
    main_schedule.course_selections.map(&:course).each do |my_course|
      return true if my_course == course
    end
    false
  end

  # array of courses in common with friend
  def courses_in_common(friend)
    user_courses = self.main_schedule.scheduled_courses.collect{|sc| sc.course}
    friend_courses = friend.main_schedule.scheduled_courses.collect{|sc| sc.course}

    # intersection of user_courses and friend_courses
    user_courses & friend_courses
  end

  # the current status of the user, e.g. "free" or "in XX-XXX"
  def status
    return '' if !self.main_schedule

    current_time = Time.now.in_time_zone
    current_time_in_min = current_time.hour*60 + current_time.min
    current_day = %w(U M T W R F S)[current_time.wday]

    course_selections = self.main_schedule.course_selections.includes(
      :section => [[:lecture => :scheduled_times], 
      :scheduled_times])

    current_course_selection = course_selections.where(
      'scheduled_times.begin <= ? AND scheduled_times.end >= ? AND scheduled_times.days LIKE ?',
      current_time_in_min, current_time_in_min, "%#{current_day}%").first

    number = ''
    section = ''

    if current_course_selection
      number = current_course_selection.section.course.number
      section = current_course_selection.section.letter
    end

    if number == ''
      return 'free'
    else
      return 'in ' + number + ' ' + section
    end
  end

  def free?
    self.status == 'free'
  end

  def update_active_schedule(schedule)
    if (schedule.user == self)
      active_schedules.find_by_semester(schedule.semester)
                      .update_attribute(:active,false)
                      .save
      schedule.update_attribute(:active,true).save
    end
  end

end
