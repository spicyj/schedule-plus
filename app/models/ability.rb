class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    can :read, User do |u|
    	(u.id == user.id) or user.friends.include?(u) or u.discoverable?
    end
    can [:create, :update, :destroy], CourseSelection do |cs|
      cs.schedule.user == user
    end
  end
end
