
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

  def git_clone(dir, source)
    GitRepo.clone(source, dir)
  end

  def build_tmc_nb_plugin(dir, options)
    TmcNbPluginBuilder.new(dir, options).build
  end

  def stage_nb_plugin(name, staging_dir)
    mv_if_exists("#{name}/build/updates", staging_dir + '/updates')
    mv_if_exists("#{name}/dist/tmc_netbeans.zip", staging_dir + "/updates/#{name}.zip")
    mv_if_exists("#{name}/dist/tmc_netbeans.app", staging_dir + "/updates/#{name}.app")
    mv_if_exists("#{name}/dist/tmc_netbeans-linux.sh", staging_dir + "/updates/#{name}-linux.sh")
    mv_if_exists("#{name}/dist/tmc_netbeans-macosx.tgz", staging_dir + "/updates/#{name}-macosx.tgz")
    mv_if_exists("#{name}/dist/tmc_netbeans-windows.exe", staging_dir + "/updates/#{name}-windows.exe")
  end

  def mv_if_exists(from, to)
    FileUtils.mv(from, to) if File.exist?(from)
  end

  def move_dir_over(from, to)
    randstr = (Random.new.rand * 1000).to_i
    backup = "#{to}.bak_#{randstr}"

    FileUtils.mv(to, backup)
    begin
      FileUtils.mv(from, to)
    rescue => ex
      FileUtils.mv(backup, to)
      raise ex
    else
      FileUtils.rm_rf(backup)
    end
  end
end
