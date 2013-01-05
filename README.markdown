A deployment script library for TMC's NetBeans plugins.

Building:

    cd nbi-builder
    mvn package

Usage:

```ruby
require 'path/to/tmc_deploy.rb'

NB_DIR = '/opt/netbeans-7.2'
UPDATE_SITE = '/srv/www/updates'
WORK_DIR = File.dirname(__FILE__) + '/work'
STAGING_DIR = WORK_DIR + '/staging'
PLUGIN_REPO = 'git://github.com/testmycode/tmc-netbeans.git'

FileUtils.rm_rf(WORK_DIR)
FileUtils.mkdir_p(WORK_DIR)
FileUtils.rm_rf(STAGING_DIR)
FileUtils.mkdir_p(STAGING_DIR)

TmcDeploy.deployment('tmc-netbeans', :work_dir => WORK_DIR) do |name|
    repo = git_clone(name, PLUGIN_REPO)
    repo.fetch('origin').reset_hard('0.3.8').clean
    build_tmc_nb_plugin(name,
      :tailoring_file => '../MyTailoring.java',
      :netbeans_dir => NB_DIR,
      :zip => true,
      :installers => true
    )
    stage_nb_plugin(name, STAGING_DIR)
    FileUtils.mkdir_p(UPDATE_SITE + '/' + name)
    move_dir_over(STAGING_DIR + '/updates', UPDATE_SITE + '/' + name)
end

TmcDeploy.main(ARGV)
```
