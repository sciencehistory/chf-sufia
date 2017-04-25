module CHF
  module Utils
    class Admin

      def self.grant(email)
        begin
          u = User.find_by!(email: email)
        rescue ActiveRecord::RecordNotFound
          raise
        end
        r = Role.find_or_create_by!(name: 'admin')
        u.roles.push(r) unless u.roles.include?(r)
      end
      
      def self.revoke(email)
        r = Role.find_by(name: 'admin')
        u = User.find_by(email: email)
        u.roles.delete r
        puts "User: #{u.email} is no longer an admin."
      end
    end
  end
end
