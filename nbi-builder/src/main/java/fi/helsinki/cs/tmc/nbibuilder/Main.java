/* This is a modified version of the BuildInstallersMojo.java and
 * AbstractNetbeansMojo.java files from the NBM Maven Plugin
 * (http://mojo.codehaus.org/nbm-maven/nbm-maven-plugin/)
 * 
 * Original copyright notices follow:
 */

/*
 * Copyright 2012 Frantisek Mantlik <frantisek at mantlik.cz>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * under the License.
 */

/* ==========================================================================
 * Copyright 2003-2004 Mevenide Team
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 * =========================================================================
 */
package fi.helsinki.cs.tmc.nbibuilder;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import java.io.*;
import java.util.*;
import org.apache.maven.plugin.logging.Log;
import org.apache.maven.plugin.logging.SystemStreamLog;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.ProjectHelper;
import org.codehaus.plexus.util.FileUtils;

public class Main {

    public static void main(String[] args) throws Exception {
        Main main = new Main();
        JCommander jc = new JCommander(main, args);
        if (main.help) {
            jc.usage();
            return;
        }
        main.execute();
    }
    private static final Log log = new SystemStreamLog();
    @Parameter(names = "--project-name", required = true)
    private String projectName;
    @Parameter(names = "--help", help = true)
    public boolean help = false;
    /**
     * Project base dir.
     */
    @Parameter(names = "--project-dir", required = true)
    private File basedir;
    /**
     * The NB harness dir.
     */
    @Parameter(names = "--harness-dir", required = true)
    private File originalHarnessDir;
    /**
     * The branding token for the application based on NetBeans platform.
     */
    @Parameter(names = "--branding-token")
    private String brandingToken;
    /**
     * Create installer for Windows
     */
    @Parameter(names = "--windows", arity = 1)
    private boolean installerOsWindows = true;
    /**
     * Create installer for Solaris
     */
    @Parameter(names = "--solaris", arity = 1)
    private boolean installerOsSolaris = true;
    /**
     * Create installer for Linux
     */
    @Parameter(names = "--linux", arity = 1)
    private boolean installerOsLinux = true;
    /**
     * Create installer for MacOSx
     */
    @Parameter(names = "--macosx", arity = 1)
    private boolean installerOsMacosx = true;
    /**
     * Enable Pack200 compression
     */
    @Parameter(names = "--pack200", arity=1)
    private boolean installerPack200Enable = true;
    /**
     * License file
     */
    @Parameter(names = "--license-file")
    private File installerLicenseFile = new File("license.txt");
    /**
     * Custom installer template. This file, if provided, will replace default
     * template from &lt;NetBeansInstallation&gt;/harness/nbi/stub/template.xml
     */
    @Parameter(names = "--template-file")
    private File templateFile;
    /**
     * Parameters passed to templateFile or to installer/nbi/stub/template.xml
     * to customize generated installers.
     *
     */
    private Map<String, String> userSettings = new HashMap<String, String>();
    /**
     * Name of the zip artifact used to produce installers from.
     */
    @Parameter(names = "--zip-name", required = true)
    private String zipName;

    public void execute() throws IOException {
        Project antProject = antProject();

        File outputDirectory = new File(basedir, "dist");
        
        outputDirectory.mkdirs();
        
        if (zipName.toLowerCase().endsWith(".zip")) {
            zipName = zipName.substring(zipName.length() - 4);
        }
        File zipFile = new File(outputDirectory, zipName + ".zip");
        getLog().info(String.format("Running Build Installers action for (existing=%2$s) zip file %1$s",
                zipFile, zipFile.exists()));

        File appIconIcnsFile;

        // Copy Netbeans Installer resources
        File harnessDir = new File(outputDirectory, "installer");
        FileUtils.deleteDirectory(harnessDir);
        FileUtils.copyDirectoryStructure(originalHarnessDir, harnessDir);

        // Overwrite template file with modified version to accept branded images etc.
        if (templateFile != null) {
            File template = new File(harnessDir, "nbi/stub/template.xml");
            FileUtils.copyFile(templateFile, template);
        }

        appIconIcnsFile = new File(harnessDir, "etc" + File.separatorChar + "applicationIcon.icns");
        getLog().info("Application icon:" + appIconIcnsFile.getAbsolutePath());

        Map<String, String> props = new HashMap<String, String>();

        if (brandingToken == null) {
            brandingToken = zipName;
        }
        
        props.put("suite.location", basedir.getAbsolutePath().replace("\\", "/"));
        props.put("suite.props.app.name", brandingToken);
        props.put("suite.dist.zip", zipFile.getAbsolutePath().replace("\\", "/"));
        props.put("suite.dist.directory", outputDirectory.getAbsolutePath().replace("\\", "/"));
        props.put("installer.build.dir", new File(outputDirectory, "installerbuild").getAbsolutePath().replace("\\", "/"));

        String installersFilePrefix = zipName;
        props.put("installers.file.prefix", installersFilePrefix);

        props.put("install.dir.name", brandingToken);

        props.put("suite.nbi.product.uid", brandingToken);

        props.put("suite.props.app.title", projectName);

        // Could fill in suite.nbi.product.version[.short] too, but it's not required

        props.put("nbi.stub.location", new File(harnessDir, "nbi/stub").getAbsolutePath().replace("\\", "/"));

        props.put("nbi.stub.common.location", new File(harnessDir, "nbi/.common").getAbsolutePath().replace("\\", "/"));

        props.put("nbi.ant.tasks.jar", new File(harnessDir, "modules/ext/nbi-ant-tasks.jar").getAbsolutePath().replace("\\", "/"));

        props.put("nbi.registries.management.jar", new File(harnessDir, "modules/ext/nbi-registries-management.jar").getAbsolutePath().replace("\\", "/"));

        props.put("nbi.engine.jar", new File(harnessDir, "modules/ext/nbi-engine.jar").getAbsolutePath().replace("\\", "/"));

        if (installerLicenseFile != null) {
            getLog().info(String.format("License file is at %1s, exist = %2$s", installerLicenseFile, installerLicenseFile.exists()));
            props.put("nbi.license.file", installerLicenseFile.getAbsolutePath()); //mkleint: no path replacement here??
        }

        List<String> platforms = new ArrayList<String>();
        List<File> outputs = new ArrayList<File>();

        if (this.installerOsLinux) {
            platforms.add("linux");
            File linuxFile = new File(outputDirectory, installersFilePrefix + "-linux.sh");
            outputs.add(linuxFile);
        }
        if (this.installerOsSolaris) {
            platforms.add("solaris");
            File solarisFile = new File(outputDirectory, installersFilePrefix + "-solaris.sh");
            outputs.add(solarisFile);
        }
        if (this.installerOsWindows) {
            platforms.add("windows");
            File windowsFile = new File(outputDirectory, installersFilePrefix + "-windows.exe");
            outputs.add(windowsFile);
        }
        if (this.installerOsMacosx) {
            platforms.add("macosx");
            File macosxFile = new File(outputDirectory, installersFilePrefix + "-macosx.tgz");
            outputs.add(macosxFile);
        }

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < platforms.size(); i++) {
            if (i != 0) {
                sb.append(" ");
            }
            sb.append(platforms.get(i));
        }
        if (sb.length() == 0) {
            //nothing to build
            getLog().warn("Nothing to build.");
        }

        props.put("generate.installer.for.platforms", sb.toString());

        File javaHome = new File(System.getProperty("java.home"));
        if (new File(javaHome, "lib/rt.jar").exists() && javaHome.getName().equals("jre")) //mkleint: does this work on mac? no rt.jar there
        {
            javaHome = javaHome.getParentFile();
        }
        props.put("generator-jdk-location-forward-slashes", javaHome.getAbsolutePath().replace("\\", "/"));

        props.put("pack200.enabled", "" + installerPack200Enable);

        if (appIconIcnsFile != null) {
            props.put("nbi.dock.icon.file", appIconIcnsFile.getAbsolutePath());
        }

        try {
            antProject.setUserProperty("ant.file", new File(harnessDir, "nbi/stub/template.xml").getAbsolutePath().replace("\\", "/"));
            ProjectHelper helper = ProjectHelper.getProjectHelper();
            antProject.addReference("ant.projectHelper", helper);
            helper.parse(antProject, new File(harnessDir, "nbi/stub/template.xml"));
            for (Map.Entry<String, String> e : props.entrySet()) {
                antProject.setProperty(e.getKey(), e.getValue());
            }
            if (userSettings != null) {
                for (Map.Entry<String, String> e : userSettings.entrySet()) {
                    antProject.setProperty(e.getKey(), e.getValue());
                }
            }
            antProject.executeTarget("build");
        } catch (Exception ex) {
            throw new RuntimeException("Installers creation failed: " + ex, ex);
        }
    }

    /**
     * Creates a project initialized with the same logger.
     *
     * Code taken from {@code AbstractNetbeansMojo.java}.
     */
    protected final Project antProject() {
        Project antProject = new Project();
        antProject.init();
        antProject.addBuildListener(new BuildListener() {
            @Override
            public void buildStarted(BuildEvent be) {
                getLog().debug("Ant build started");
            }

            @Override
            public void buildFinished(BuildEvent be) {
                if (be.getException() != null) {
                    getLog().error(be.getMessage(), be.getException());
                } else {
                    getLog().debug("Ant build finished");
                }
            }

            @Override
            public void targetStarted(BuildEvent be) {
                getLog().info(be.getTarget().getName() + ":");
            }

            @Override
            public void targetFinished(BuildEvent be) {
                getLog().debug(be.getTarget().getName() + " finished");
            }

            @Override
            public void taskStarted(BuildEvent be) {
                getLog().debug(be.getTask().getTaskName() + " started");
            }

            @Override
            public void taskFinished(BuildEvent be) {
                getLog().debug(be.getTask().getTaskName() + " finished");
            }

            @Override
            public void messageLogged(BuildEvent be) {
                switch (be.getPriority()) {
                    case Project.MSG_ERR:
                        getLog().error(be.getMessage());
                        break;
                    case Project.MSG_WARN:
                        getLog().warn(be.getMessage());
                        break;
                    case Project.MSG_INFO:
                        getLog().info(be.getMessage());
                        break;
                    default:
                        getLog().debug(be.getMessage());
                }
            }
        });
        return antProject;
    }

    private Log getLog() {
        return log;
    }
}
