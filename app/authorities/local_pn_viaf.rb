class LocalPnViaf < LocalViaf

  def initialize(_)
  end

  def search q
    search_subauthority 'personalNames', q
  end

end
