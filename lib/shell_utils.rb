require 'shellwords'

module ShellUtils
  def sh!(*cmd)
    sh_preescaped!(Shellwords.join(cmd.flatten.map(&:to_s)))
  end
  
  def sh_preescaped!(cmd)
    puts cmd if @shell_utils_echo
    output = `#{cmd} 2>&1`
    raise "Failed: #{cmd}. Exit code: #{$?.exitstatus}. Output:\n#{output}" if !$?.success?
    output
  end

  def system!(*cmd)
    cmd = Shellwords.join(cmd.flatten.map(&:to_s))
    puts cmd if @shell_utils_echo
    system(cmd)
    raise "Failed: #{cmd}. Exit code: #{$?.exitstatus}." if !$?.success?
  end

  def echo_on!
    @shell_utils_echo = true
  end

  def echo_off!
    @shell_utils_echo = false
  end

  extend self
end
