
require 'pathname'
require 'fileutils'
require 'ant_project'

class TmcNbPluginBuilder
  def initialize(dir, options)
    raise "Required option :netbeans_dir missing" unless options[:netbeans_dir]

    @dir = Pathname(dir).realpath
    @tailoring_file = Pathname(options[:tailoring_file]).realpath if options[:tailoring_file]

    nbdir = Pathname(options[:netbeans_dir]).realpath
    defs = {
      'nbplatform.default.harness.dir' => "#{nbdir}/harness",
      'nbplatform.default.netbeans.dest.dir' => "#{nbdir}"
    }
    @ant_project = AntProject.new(@dir, defs)
  end

  def build(clean = true)
    apply_tailoring if @tailoring_file
    @ant_project.ant('clean') if clean
    @ant_project.ant('build', 'nbms')
  end

private
  def apply_tailoring
    FileUtils.cp(@tailoring_file, tailoring_dir)
    File.open(tailoring_dir + 'SelectedTailoring.properties', 'w') do |f|
      f.puts("defaultTailoring=fi.helsinki.cs.tmc.tailoring.#{@tailoring_file.basename('.java')}")
    end
  end

  def tailoring_dir
    Pathname("#{@dir}/tmc-plugin/src/fi/helsinki/cs/tmc/tailoring")
  end
end