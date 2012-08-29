
A deployment script library for TMC's NetBeans plugins.

Usage:

    require 'path/to/tmc_deploy.rb'

    NB_DIR = '/opt/netbeans-7.2'
    UPDATE_SITE = '/srv/www/updates'
    WORK_DIR = File.dirname(__FILE__) + '/work'
    PLUGIN_REPO = 'git://github.com/testmycode/tmc-netbeans.git'

    FileUtils.mkdir_p(WORK_DIR)

    TmcDeploy.deployment('tmc-netbeans', :work_dir => WORK_DIR) do |name|
        repo = git_clone_or_open(name, PLUGIN_REPO)
        repo.fetch('origin').reset_hard('0.3.1').clean
        build_tmc_nb_plugin(name,
          :tailoring_file => '../MyTailoring.java',
          :netbeans_dir => NB_DIR
        )
        FileUtils.mkdir_p(UPDATE_SITE + '/' + name)
        replace_dir_quickly(name + '/build/updates', UPDATE_SITE + '/' + name)
    end

    TmcDeploy.main(ARGV)
