
require File.dirname(__FILE__) + '/lib/init.rb'
require 'tmc_nb_plugin_builder'
require 'git_repo'
require 'pathname'
require 'fileutils'
require 'tmpdir'

ShellUtils.echo_on!

class TmcDeploy
  @deployments = {}

  def self.main(args)
    if args.size == 0 || args.any? {|a| ['-h', '--help'].include?(a) }
      puts usage
      exit(1)
    end

    for name in args
      raise "No such deployment: #{name}" if !@deployments[name]
      @deployments[name].run
    end
  end

  def self.usage
    <<EOS
Usage: #{$0} <deployment_name>

Available deployments: #{@deployments.keys.sort.join(', ')}.

EOS
  end

  def self.deployment(name, options, &block)
    raise 'Missing :work_dir' unless options[:work_dir]
    @deployments[name] = self.new(name, options, &block)
  end

  def initialize(name, options, &block)
    raise 'Missing :work_dir' unless options[:work_dir]

    @name = name
    @work_dir = Pathname(options[:work_dir]).realpath
    @block = block
  end

  def run
    Dir.chdir(@work_dir) do
      if @block.arity == 1
        self.instance_exec(@name, &@block)
      else
        self.instance_exec(&@block)
      end
    end
  end

  # Operations available in deployment blocks

  def git_clone_or_open(dir, source)
    dir = Pathname(dir)
    if dir.exist?
      GitRepo.new(dir)
    else
      GitRepo.clone(source, dir)
    end
  end

  def build_tmc_nb_plugin(dir, options)
    TmcNbPluginBuilder.new(dir, options).build
  end

  def replace_dir_quickly(from, to)
    randstr = (Random.new.rand * 1000).to_i
    newdir = "#{to}.new_#{randstr}"
    olddir = "#{to}.old_#{randstr}"

    begin
      FileUtils.cp_r(from, newdir, :preserve => true)
    rescue => ex
      FileUtils.rm_rf(newdir)
      raise ex
    end

    FileUtils.mv(to, olddir)
    begin
      FileUtils.mv(newdir, to)
    rescue => ex
      FileUtils.mv(olddir, to)
      raise ex
    end

    FileUtils.rm_rf(olddir)
  end
end
