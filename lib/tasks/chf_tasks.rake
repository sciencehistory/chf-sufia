namespace :chf do

  desc 'Grant admin role to user. Create user if not found.'
  task grant_admin: :environment do
    u = prompt_to_create_user
    puts "User: #{u.email} exists."
    r = create_admin_role
    u.roles.push(r) unless u.roles.include?(r)
    r.reload
    puts "User: #{u.email} is an admin."
  end

  desc 'Revoke admin role from user.'
  task revoke_admin: :environment do
    r = Role.find_by(name: 'admin')
    u = User.find_by(email: prompt_for_email)
    u.roles.delete r
    puts "User: #{u.email} is no longer an admin."
  end

  def create_admin_role
    Role.find_or_create_by!(name: 'admin') do
      puts 'Admin role now found. Creating now.'
    end
  end

  def prompt_to_create_user
    User.find_or_create_by!(email: prompt_for_email) do |u|
      puts 'User not found. Enter a password to create the user.'
      u.password = prompt_for_password
      u.save
    end
  rescue => e
    puts e
    retry
  end

  def prompt_for_email
    print 'Email: '
    $stdin.gets.chomp
  end

  def prompt_for_password
    begin
      system 'stty -echo'
      print 'Password (must be 8+ characters): '
      password = $stdin.gets.chomp
      puts "\n"
    ensure
      system 'stty echo'
    end
    password
  end
end
