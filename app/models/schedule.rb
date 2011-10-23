class Schedule < ActiveRecord::Base
  belongs_to :user
  has_many :courses, :class_name => 'CourseSelection'
  scope :active, :conditions => { :active => true }
 
  # Adds a course by course_id and section_id
  # Assumes course_id and section_id are valid
  # Uses section A by default.
  def add_course(course_id, section_id)
    section_id ||= Course.find(course_id).find_by_section('A')
    self.courses.create(:course_id => course_id,
                        :section_id => section_id)
  end

  # Changes section for some course on the schedule
  def switch_section(course_id, section_id)
    self.courses.find_by_course_id(course_id)
                .update_attribute(:section_id, section_id)
                .save
  end

  # Deletes a course from the schedule.
  def delete_course(course_id)
    self.courses.find_by_course_id(course_id).destroy!
  end

end
