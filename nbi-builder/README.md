Code extracted from http://mojo.codehaus.org/nbm-maven/nbm-maven-plugin/ to build an
NBI installer from and ant-based NetBeans Platform project.

It's a bit inconvenient to use. Here's an example.

    ARGS="--zip-name test_program \
      --project-dir $HOME/NetBeansProjects/test_program \
      --project-name TestProgram \
      --harness-dir /opt/netbeans-7.2/harness \
      --pack200 false"
    mvn exec:java \
      -Dant.home=/usr/share/ant \
      -Dexec.args="$ARGS"
