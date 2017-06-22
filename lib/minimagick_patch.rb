# Hack to monkey-patch MiniMagick to always add the 'quiet'
# option to every imagemagick command line.
MiniMagick::Tool.class_eval do
  class_attribute :quiet_arg
  self.quiet_arg = false

  prepend(MiniMagickPatch = Module.new do
    def command
      if quiet_arg
        [*executable, *(['-quiet'] + args)]
      else
        super
      end
    end
  end)
end
