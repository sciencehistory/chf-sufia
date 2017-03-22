# based on sshkit's MappingInteractionHandler, but all we want to do is log it as we get it!
class StreamOutputInteractionHandler

  # set log level to :stderr, and it will be written directly to stderr console
  # instead of capistrano logging, which works to get byte-by-byte output
  # before newlines, like progress bars.
  def initialize(log_level=:info)
    @log_level = log_level
  end

  def on_data(_command, stream_name, data, channel)
    if @log_level == :stderr
      $stderr.print data
    else
      log(data)
    end
  end

  private

  def log(message)
    SSHKit.config.output.send(@log_level, message) unless @log_level.nil?
  end
end

namespace :invoke do
  desc "Execute a rake task on a remote server"
  task :rake do
    if ENV['TASK']
      tasks = ENV['TASK'].split(',')

      on roles(:app) do
        within current_path do
          with rails_env: fetch(:rails_env) do
            tasks.each do |task|
              execute :rake, task, interaction_handler: StreamOutputInteractionHandler.new(:stderr)
              info("finished rake #{task}")
            end
          end
        end
      end

    else
      puts "\n\nFailed! You need to specify the 'TASK' parameter!",
           "Usage: cap <stage> invoke:rake TASK=your:task"
    end
  end
end
