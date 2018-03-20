class User < ApplicationRecord
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Curation Concerns behaviors.
  include CurationConcerns::User

  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles
  # Connects this user object to Sufia behaviors.
  include Sufia::User
  include Sufia::UserUsageStats

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def password_required?
    false
  end

  def staff?
    groups.include? 'registered'
  end

  # A devise method, we're taking advantage of it for a cheesy way to lock out
  # admin users based on CHF::Env variable.
  def active_for_authentication?
    if CHF::Env.lookup(:logins_disabled)
      false
    else
      super
    end
  end
  def inactive_message
    if CHF::Env.lookup(:logins_disabled)
      "Sorry, logins are temporarily disabled for some software maintenance."
    else
      super
    end
  end

  # Use on a current_user to ensure it's not a guest / nil object user
  alias_method :logged_in?, :persisted?

end
