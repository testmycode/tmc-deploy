
require 'pathname'
require 'fileutils'
require 'shell_utils'
require 'ant_project'

class TmcNbPluginBuilder
  def initialize(dir, options)
    raise "Required option :netbeans_dir missing" unless options[:netbeans_dir]
    
    @options = {
      :clean => true,
      :nbms => true,
      :zip => false,
      :installers => false,
      :pack200 => true
    }.merge(options)

    @dir = Pathname(dir).realpath
    @tailoring_file = Pathname(@options[:tailoring_file]).realpath if @options[:tailoring_file]

    nbplatform_name = @options[:nbplatform_name] || 'default'
    @nbdir = Pathname(@options[:netbeans_dir]).realpath
    defs = {
      "nbplatform.#{nbplatform_name}.harness.dir" => "#{@nbdir}/harness",
      "nbplatform.#{nbplatform_name}.netbeans.dest.dir" => "#{@nbdir}"
    }
    @ant_project = AntProject.new(@dir, defs)
  end

  def build
    apply_tailoring if @tailoring_file
    @ant_project.ant('clean', 'build')
    @ant_project.ant('nbms') if @options[:nbms]
    @ant_project.ant('build-zip') if zip_needed?
    if @options[:installers]
      build_installers
    end
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

  def zip_needed?
    @options[:zip] || @options[:mac_app] || @options[:installers]
  end

  def build_installers
    @ant_project.ant('build-mac')

    Dir.chdir nbi_builder_dir do
      options = {
        'project-name' => project_title,
        'project-dir' => @ant_project.dir,
        'zip-name' => project_branding_token,
        'branding-token' => project_branding_token,
        'harness-dir' => "#{@nbdir}/harness",
        'pack200' => @options[:pack200],
        'solaris' => 'false'
      }
      options['project-version'] = @options[:version] if @options[:version]
      options = options.map {|k, v| ["--#{k}", "'#{v}'"] }.flatten
      ShellUtils.system! ['mvn', 'exec:java', '-Dant.home=' + ant_home, '-Dexec.args=' + options.join(' ')]
    end
  end

  def ant_home
    (ShellUtils.sh! ['ant', '-diagnostics']).split("\n").each do |line|
      if line.strip =~ /^ant.home\s*:\s*(.*)$/
        return $1
      end
    end
    raise "Could not determine ant.home from `ant -diagnostics`"
  end

  def project_branding_token
    Dir.chdir @ant_project.dir do
      IO.readlines('nbproject/platform.properties').each do |line|
        if line.strip =~ /^branding.token=(.*)$/
          return $1
        end
      end
      raise "Failed to determine project branding token"
    end
  end

  def project_title
    Dir.chdir @ant_project.dir do
      IO.readlines('nbproject/project.properties').each do |line|
        if line.strip =~ /^app.title=(.*)$/
          return $1
        end
      end
      raise "Failed to determine project branding token"
    end
  end

  def project_zip_name
    @ant_project.dir.basename
  end

  def nbi_builder_dir
    project_root_dir + 'nbi-builder'
  end

  def project_root_dir
    Pathname(__FILE__).parent.parent
  end
end