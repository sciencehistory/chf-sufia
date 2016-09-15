class ResqueAdmin
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?
    # TODO code a group here that makes sense
    #current_user.groups.include? 'admin'
    return true
  end
end
