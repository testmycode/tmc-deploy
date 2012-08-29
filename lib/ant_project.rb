
require 'shell_utils'
require 'pathname'

class AntProject
  def initialize(dir, defs = {})
    @dir = Pathname(dir)
    @defs = defs.map {|k, v| "-D#{k}=#{v}"}
  end

  attr_reader :dir

  def ant(*targets)
    Dir.chdir(@dir) do
      ShellUtils.system! ['ant', *@defs, *targets]
    end
  end
end
