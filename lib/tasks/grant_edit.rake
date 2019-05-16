# USER_EMAIL=new_museum_user@sciencehistory.org bundle exec rake chf:grant_edit

namespace :chf do
  desc """
  Grant access to all images in the museum collection to a new user.
  bundle exec rake chf:grant_edit
  USER_EMAIL=new_museum_user@sciencehistory.org bundle exec rake chf:grant_edit
  """
  def grant_access(x, username)
    unless  x.edit_users.include? username
      x.edit_users = x.edit_users + [username]
      x.save!
    end
    x.ordered_members.to_a.compact.each do |c|
      grant_access(c, username)
    end
  end

  task :grant_edit => :environment do
    username = ENV['USER_EMAIL']
    if username.nil?
      puts "Please provide a valid user's email address."
      puts "e.g."
      puts "USER_EMAIL=new_museum_user@sciencehistory.org bundle exec rake chf:grant_edit"
      exit
    end
    if  User.find_by_email(username).nil?
      puts "User #{username} was not found."
      exit
    end


    progress_bar = ProgressBar.create(total: GenericWork.count, format: "%a %t: |%B| %R/s %c/%u %p%% %e")
    GenericWork.find_each do |x|
      progress_bar.increment
      next unless x.division == 'Museum'
      next unless x.resource_type.to_a.include? 'Image'
      grant_access(x, username)
      progress_bar.log("Done with generic work #{x.id}")
    end

  end # task
end # namespace
