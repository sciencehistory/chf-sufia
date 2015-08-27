class LocalCnViaf < LocalViaf

  def initialize(_)
  end

  def search q
    search_subauthority 'corporateNames', q
  end

end
