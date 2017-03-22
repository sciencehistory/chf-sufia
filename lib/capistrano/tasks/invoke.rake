# based on sshkit's MappingInteractionHandler, but all we want to do is log it as we get it!
class StreamOutputInteractionHandler

  def initialize(log_level=:info)
    @log_level = log_level
  end

  def on_data(_command, stream_name, data, channel)
    #log(data)
    $stderr.print data
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
      on roles(:app) do
        within current_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, ENV['TASK'], interaction_handler: StreamOutputInteractionHandler.new(:debug)
          end
        end
      end

    else
      puts "\n\nFailed! You need to specify the 'TASK' parameter!",
           "Usage: cap <stage> invoke:rake TASK=your:task"
    end
  end
end
