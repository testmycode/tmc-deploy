
require 'shell_utils'
require 'pathname'

class GitRepo
  def self.clone(from, to)
    from = from
    to = Pathname(to).realdirpath
    ShellUtils.system! ['git', 'clone', from, to]
    GitRepo.new(to)
  end

  def initialize(dir)
    @dir = Pathname(dir).realpath
  end

  def fetch(remote = nil)
    Dir.chdir(@dir) do
      cmd = ['git', 'fetch']
      cmd << remote if remote
      ShellUtils.system! cmd
    end
    self
  end

  def reset_hard(rev)
    Dir.chdir(@dir) do
      ShellUtils.system! ['git', 'reset', '--hard', rev]
    end
    self
  end

  def clean
    Dir.chdir(@dir) do
      ShellUtils.system! ['git', 'clean', '-f', '-d']
    end
    self
  end
end