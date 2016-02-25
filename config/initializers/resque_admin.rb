module Sufia
  class ResqueAdmin
    def self.matches?(request)
      current_user = request.env['warden'].user
      return false if current_user.blank?
      current_user.roles.include? Role.find_by(name: 'admin')
    end
  end
end
