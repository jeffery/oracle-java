oracle-java
===========

The Oracle JDK installer for openSUSE Linux

Download the JDK tar.gz from Oracle website
=
  http://www.oracle.com/technetwork/java/javase/downloads/index.html

Download the jdk installer script
=

    wget https://raw.github.com/jeffery/oracle-java/master/install-jdk.sh

Run the script as root user
=
pointing it to the downloaded tar.gz archive

    $ sudo bash install-jdk.sh ~/Downloads/jdk-7u17-linux-x64.tar.gz
    
Update the system-wide Java
=

Java application launcher:
    
    $ sudo /usr/sbin/update-alternatives --config java
    
Java compiler:
    
    $ sudo /usr/sbin/update-alternatives --config javac
    
Web browser plug-in:
    
    $ sudo /usr/sbin/update-alternatives --config javaplugin
    
For each of the above options select the alternatives which are installed in jdk_Oracle folder
    
Verify the new version is installed
=
    $ java -version
    java version "1.7.0_17"
    Java(TM) SE Runtime Environment (build 1.7.0_17-b02)
    Java HotSpot(TM) 64-Bit Server VM (build 23.7-b01, mixed mode)
