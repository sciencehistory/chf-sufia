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

  # TASK=your:task[,other:task] REASON=reason UNTIL="12pm Eastern Time" cap <stage> invoke:rake_with_maintenance
  #
  # By default maintenance mode is turned off again even if interrupted
  # with an error. If you'd like to leave it on, set enf SAFE_MAINT=false
  desc "Execute a rake task on remote serer with maintenance enable/disable"
  task :rake_with_maintenance do
    if ENV['TASK']
      error_encountered = false
      begin
        SSHKit.config.output.info("Turning on maintenance mode")

        invoke("maintenance:enable")

        invoke("invoke:rake")

      # Catch Ctrl-C Interrupt, so we still turn off maint mode.
      # And errors raised by our rake tasks.
      rescue Interrupt, SSHKit::Runner::ExecuteError => e
        SSHKit.config.output.error("Error caught when executing rake task: #{e.inspect}")

        # tell the ensure block
        error_encountered = true

        # Raise it again so our cap task has non-zero exit code, don't
        # know how else to make that so...
        raise e
      ensure
        if error_encountered && ENV['SAFE_MAINT'] == "false"
          SSHKit.config.output.warn("\n\nMAINTENANCE MODE STILL ON!\n\n")
        else
          SSHKit.config.output.info("Turning off maintenance mode")
          invoke("maintenance:disable")
        end
      end
    else
      SSHKit.config.output.error "\n\nFailed! You need to specify the 'TASK' parameter!",
           "Usage: cap <stage> invoke:rake TASK=your:task"
    end
  end

  # cap <stage> invoke:rake TASK=your:task[,other:task]
  desc "Execute a rake task on a remote server"
  task :rake do
    if ENV['TASK']
      tasks = ENV['TASK'].split(',')

      on roles(:app) do
        within current_path do
          with rails_env: fetch(:rails_env) do
            tasks.each do |task|
              # warning, may be executing this on multiple servers if we have
              # multiple 'app' servers later, which would be bad.
              # Will have to deal with that then, not sure best way.
              execute :rake, task, interaction_handler: StreamOutputInteractionHandler.new(:stderr)
              info("finished rake #{task}")
            end
          end
        end
      end

    else
      error "\n\nFailed! You need to specify the 'TASK' parameter!\n" +
           "Usage: cap <stage> invoke:rake TASK=your:task[,other:task]"
    end
  end
end
