class DoAnErrorJob < ActiveJob::Base
  def perform(number)
    raise StandardError.new("We failed on purpose, we were sent: #{number}")
  end
end
