namespace :invoke do

  #     cap <stage> invoke:rake TASK=chf:data_fix:something[,other:task]
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
              execute :rake, task, interaction_handler: CHF::CapistranoHelp::StreamOutputInteractionHandler.new(:stderr)
              info("finished rake #{task}")
            end
          end
        end
      end

    else
      # Not really sure why we can't just use `error` method, maybe not since
      # cap 4?
      SSHKit.config.output.error "\n\nFailed! You need to specify the 'TASK' parameter!\n" +
           "Usage: cap <stage> invoke:rake TASK=your:task[,other:task]"
    end
  end


  namespace :rake do

    #     TASK=your:task[,other:task] REASON=reason UNTIL="12pm Eastern Time" cap <stage> invoke:rake:with_maintenance
    #
    # By default maintenance mode is turned off again even if interrupted
    # with an error. If you'd like to leave it on, set enf SAFE_MAINT=false
    desc "Execute a rake task on remote serer with maintenance enable/disable"
    task :with_maintenance do
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
          SSHKit.config.output.warn("\n\nMAINTENANCE MODE STILL ON!\n\n\n")
        else
          SSHKit.config.output.info("Turning off maintenance mode")
          invoke("maintenance:disable")
        end
      end
    end
  end
end

# Can't for the life of me figure out how to define this somewhere
# else and `require` it, not sure why. That'd be better.

# based on sshkit's MappingInteractionHandler, but all
# we want to do is log it as we get it! Not really an interactin handler at all,
# just a stream logger.
module CHF
  module CapistranoHelp
    class StreamOutputInteractionHandler

      # set log level to :stderr and it will be written directly to stderr console
      # instead of capistrano logging. This allows byte-by-byte output
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
  end
end

