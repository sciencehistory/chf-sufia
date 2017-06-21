# Hack to monkey-patch MiniMagick to always add the 'quiet'
# option to every imagemagick command line.
class MiniMagick::Tool
  class_attribute :quiet_arg
  self.quiet_arg = false

  prepend(Module.new do
    def command
      if quiet_arg
        [*executable, *(['-quiet'] + args)]
      else
        super
      end
    end
  end)
end
