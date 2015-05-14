#!/bin/bash
: '
Project: https://github.com/jeffery/oracle-java
Date: 31-03-2013

Copyright (C) 2013  Jeffery Fernandez <jeffery@fernandez.net.au>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.
'

set -e

exitWithMessage()
{
	# Pipe std out to std error
	echo $1 1>&2
	exit 1;
}

printUsage()
{
	echo Usage:  `basename $1` PATH_TO_DOWNLOADED_TGZ
	echo Example: `basename $1` ~/Downloads/jdk-7u17-linux-x64.tar.gz
	exit 127
}

isRunByRoot()
{
	if [ "$(id -u)" != "0" ]; then
		false
	else
		true
	fi
}

isGzipArchive()
{
	if [ $(file -b "$1" | awk '{ print $1 }') = "gzip" ]; then
		true
	else
		false
	fi
}

isPathToArchiveValid()
{
	if [ -f "$1" ] && isGzipArchive "$1"; then
		true
	else
		false
	fi
}


getTarArchiveName()
{
	basename $(tar -ztf "$1" | head -n 1)
}

extractTarGzipArchive()
{
	sudo tar -xvzf "$1"
}

is64BitArchitecture()
{
	local arch
	arch=$(getconf -a | grep LONG_BIT | awk -F ' ' '{print $2}')
	if [ $arch -eq 64 ]; then
		true
	else
		false
	fi
}

fixPermissions()
{
	sudo chown -R root:root "$1"
}

copyToLibraryPath()
{
	sudo cp -r "$1" "$2"
}

createSymbolicLink()
{
	if [ -e "$1" ]; then
		sudo ln -sf -T "$1" "$2"
	else
		exitWithMessage "Could not find path to $1"
	fi
}


findAllManPages()
{
	find "$1" -name "*.1" | grep "man/man1"
}

gzipManPages()
{
	for manPage in $(findAllManPages "$1"); do sudo gzip -f $manPage; done;
}

getJavaFullVersion()
{
	local jdkPath="$1"
	"$jdkPath/bin/java" -version 2>&1 | awk '/version/ {print $3}' | egrep -o '[0-9]+\.[0-9]{1,2}+\.[0-9]_[0-9]{1,2}'
}

getJavaVersion()
{
	local jdkPath="$1"
	"$jdkPath/bin/java" -version 2>&1 | awk '/version/ {print $3}' | egrep -o '[0-9]+\.[0-9]{1,2}+\.[0-9]'
}

setupJvmExports()
{
	local jvmExportsPath="$1"
	local jdkSymbolicPath="$2"
	local javaFullVersion="$3"
	local javaVersion="$4"
	
	sudo mkdir -p "$jvmExportsPath"
	cd "$jvmExportsPath"
	
	createSymbolicLink "${jdkSymbolicPath}/jre/lib/rt.jar" "jaas-${javaFullVersion}rac.jar"
	createSymbolicLink "jaas-${javaFullVersion}rac.jar" "jaas-${javaVersion}.jar"
	createSymbolicLink "jaas-${javaFullVersion}rac.jar" "jaas.jar"

	createSymbolicLink "${jdkSymbolicPath}/jre/lib/jce.jar" "jce-${javaFullVersion}rac.jar"
	createSymbolicLink "jce-${javaFullVersion}rac.jar" "jce-${javaVersion}.jar"
	createSymbolicLink "jce-${javaFullVersion}rac.jar" "jce.jar"

	createSymbolicLink "${jdkSymbolicPath}/jre/lib/rt.jar" "jdbc-stdext-${javaFullVersion}rac.jar"
	createSymbolicLink "jdbc-stdext-${javaFullVersion}rac.jar" "jdbc-stdext-${javaVersion}.jar"
	createSymbolicLink "jdbc-stdext-${javaFullVersion}rac.jar" "jdbc-stdext.jar"

	createSymbolicLink "${jdkSymbolicPath}/jre/lib/rt.jar" "jndi-${javaFullVersion}rac.jar"
	createSymbolicLink "jndi-${javaFullVersion}rac.jar" "jndi-${javaVersion}.jar"
	createSymbolicLink "jndi-${javaFullVersion}rac.jar" "jndi.jar"

	createSymbolicLink "${jdkSymbolicPath}/jre/lib/rt.jar" "jndi-cos-${javaFullVersion}rac.jar"
	createSymbolicLink "jndi-cos-${javaFullVersion}rac.jar" "jndi-cos-${javaVersion}.jar"
	createSymbolicLink "jndi-cos-${javaFullVersion}rac.jar" "jndi-cos.jar"

	createSymbolicLink "${jdkSymbolicPath}/jre/lib/rt.jar" "jndi-ldap-${javaFullVersion}rac.jar"
	createSymbolicLink "jndi-ldap-${javaFullVersion}rac.jar" "jndi-ldap-${javaVersion}.jar"
	createSymbolicLink "jndi-ldap-${javaFullVersion}rac.jar" "jndi-ldap.jar"

	createSymbolicLink "${jdkSymbolicPath}/jre/lib/rt.jar" "jndi-rmi-${javaFullVersion}rac.jar"
	createSymbolicLink "jndi-rmi-${javaFullVersion}rac.jar" "jndi-rmi-${javaVersion}.jar"
	createSymbolicLink "jndi-rmi-${javaFullVersion}rac.jar" "jndi-rmi.jar"

	createSymbolicLink "${jdkSymbolicPath}/jre/lib/jsse.jar" "jsse-${javaFullVersion}rac.jar"
	createSymbolicLink "jsse-${javaFullVersion}rac.jar" "jsse-${javaVersion}.jar"
	createSymbolicLink "jsse-${javaFullVersion}rac.jar" "jsse.jar"

	createSymbolicLink "${jdkSymbolicPath}/jre/lib/rt.jar" "sasl-${javaFullVersion}rac.jar"
	createSymbolicLink "sasl-${javaFullVersion}rac.jar" "sasl-${javaVersion}.jar"
	createSymbolicLink "sasl-${javaFullVersion}rac.jar" "sasl.jar"
}

createJavaAlternativesCommand()
{
	local binaryList="$1"
	local jdkSymbolicPath="$2"

	local alternativesCommand=""

	for binaryName in $binaryList
	do
		binaryPath="${jdkSymbolicPath}/bin/${binaryName}"
		manPageGzipFile="${jdkSymbolicPath}/man/man1/${binaryName}.1.gz"

		if [ -f "$binaryPath" ]; then
			alternativesCommand="$alternativesCommand \
			--slave /usr/bin/${binaryName} ${binaryName} ${jdkSymbolicPath}/bin/$binaryName"
		else
			exitWithMessage "No Binaries FOUND for ${binaryPath}"
		fi

		if [ -f "$manPageGzipFile" ]; then
			alternativesCommand="$alternativesCommand \
			--slave /usr/share/man/man1/${binaryName}.1.gz ${binaryName}.1.gz $manPageGzipFile"
		fi
	done;

	echo "$alternativesCommand"
}

setupJavaApplicationAlternatives()
{
	local jdkSymbolicPath="$1"
	local libPath="$2"
	local executableFiles="java-rmi.cgi jvisualvm keytool orbd policytool rmid rmiregistry servertool tnameserv"
	
	sudo /usr/sbin/update-alternatives \
	--install /usr/bin/java java $jdkSymbolicPath/bin/java 3 \
	--slave /usr/share/man/man1/java.1.gz java.1.gz $jdkSymbolicPath/man/man1/java.1.gz \
	\
	--slave $libPath/jvm/jre jre $jdkSymbolicPath/jre \
	--slave $libPath/jvm-exports/jre jre_exports $libPath/jvm-exports/jdk_Oracle \
	\
	$(createJavaAlternativesCommand "$executableFiles" "$jdkSymbolicPath")
}

setupJavaCompilerAlternatives()
{
	local libPath="$1"
	local jdkSymbolicPath="$2"
	local jvmExportsPath="$3"

	local executableFiles="appletviewer extcheck idlj jar jarsigner javadoc javafxpackager javah javap jcmd jconsole
	jdb jhat jinfo jmap jps jrunscript jsadebugd jstack jstat jstatd native2ascii pack200 rmic schemagen serialver
	unpack200 wsgen wsimport xjc"

	sudo /usr/sbin/update-alternatives \
	--install /usr/bin/javac javac $jdkSymbolicPath/bin/javac 3 \
	--slave /usr/share/man/man1/javac.1.gz javac.1.gz $jdkSymbolicPath/man/man1/javac.1.gz \
	\
	--slave $libPath/jvm/java java_sdk $jdkSymbolicPath \
	--slave $libPath/jvm-exports/java java_sdk_exports $jvmExportsPath \
	$(createJavaAlternativesCommand "$executableFiles" "$jdkSymbolicPath")
}

setupBrowserPluginAlternatives()
{
	local arch="$1"
	local jdkSymbolicPath="$2"
	local libPath="$3"

	sudo /usr/sbin/update-alternatives \
	--install $libPath/browser-plugins/javaplugin.so javaplugin $jdkSymbolicPath/jre/lib/$arch/libnpjp2.so 3 \
	$(createJavaAlternativesCommand "javaws" "$jdkSymbolicPath")
}

setupJavaControlPanel()
{
	local jdkSymbolicPath="$1"

	createSymbolicLink "${jdkSymbolicPath}/jre/bin/jcontrol" "/usr/bin/jcontrol"
	createSymbolicLink "${jdkSymbolicPath}/jre/lib/desktop/icons/hicolor/16x16/apps/sun-jcontrol.png" "/usr/share/icons/hicolor/16x16/apps/sun-jcontrol.png"
	createSymbolicLink "${jdkSymbolicPath}/jre/lib/desktop/icons/hicolor/48x48/apps/sun-jcontrol.png" "/usr/share/icons/hicolor/48x48/apps/sun-jcontrol.png"
	createSymbolicLink "${jdkSymbolicPath}/jre/lib/desktop/icons/LowContrast/16x16/apps/sun-jcontrol.png" "/usr/share/icons/locolor/16x16/apps/sun-jcontrol.png"
	createSymbolicLink "${jdkSymbolicPath}/jre/lib/desktop/icons/LowContrast/48x48/apps/sun-jcontrol.png" "/usr/share/icons/locolor/48x48/apps/sun-jcontrol.png"
	createSymbolicLink "${jdkSymbolicPath}/jre/lib/desktop/applications/sun_java.desktop" "/usr/share/applications/sun_java.desktop"
}

runCleanup()
{
	sudo rm -fR "./$1"
}


displayPostInstallationInformation()
{
	echo "
	* Installation is now Complete *

	- Don't forget to update your system alternatives for

	Java application launcher:
		sudo /usr/sbin/update-alternatives --config java
	Java compiler:
		sudo /usr/sbin/update-alternatives --config javac
	Web browser plug-in:
		sudo /usr/sbin/update-alternatives --config javaplugin
	"
}
startInstallation()
{
	echo "$1"
	
	local libPath=""
	local arch=""
	if is64BitArchitecture; then
		libPath="/usr/lib64"
		arch="amd64"
	else
		libPath="/usr/lib"
		arch="i386"
	fi
	
	local tarArchiveName=$(getTarArchiveName "$1" || exitWithMessage "Could not obtain archive name" )
	local jdkAbsolutePath="$libPath/$tarArchiveName"
	local jdkSymbolicPath="$libPath/jdk_Oracle"
	local jvmExportsPath="$libPath/jvm-exports/jdk_Oracle"
	
	extractTarGzipArchive "$1" || 
		exitWithMessage "Could not extract archive"
		
	fixPermissions "$tarArchiveName" || 
		exitWithMessage "Could not fix permissions of archive"
	
	copyToLibraryPath "$tarArchiveName" "$libPath" || 
		exitWithMessage "Could not copy library to $libPath"
		
	local javaFullVersion=$(getJavaFullVersion "$jdkAbsolutePath")
	local javaVersion=$(getJavaVersion "$jdkAbsolutePath")
	
	createSymbolicLink "$jdkAbsolutePath" "$jdkSymbolicPath" || 
		exitWithMessage "Could not create symlink to $jdkSymbolicPath"
	
	gzipManPages "$jdkAbsolutePath" || 
		exitWithMessage "Could not gzip man pages"
	
	# Execute in sub-shell, otherwise PWD will move
	$(setupJvmExports "$jvmExportsPath" "$jdkSymbolicPath" "$javaFullVersion" "$javaVersion" || 
		exitWithMessage "Could not create JVM export symlinks")

	setupJavaApplicationAlternatives "$jdkSymbolicPath" "$libPath" ||
		exitWithMessage "Failed updating Application alternatives"
	
	setupJavaCompilerAlternatives "$libPath" "$jdkSymbolicPath" "$jvmExportsPath" ||
		exitWithMessage "Failed updating Compiler alternatives"

	setupBrowserPluginAlternatives "$arch" "$jdkSymbolicPath" "$libPath" ||
		exitWithMessage "Failed updating Plugin alternatives"

	setupJavaControlPanel "$jdkSymbolicPath" ||
		exitWithMessage "Could not install Sun Java Control Panel"
	
	runCleanup "$tarArchiveName" ||
		exitWithMessage "Failed cleaning up"

	displayPostInstallationInformation && exit 0
}

if [ "$#" -ne 1 ]; then
	printUsage "$0"
else
	if isPathToArchiveValid "$1"; then
		if ! isRunByRoot; then
			exitWithMessage "This script must be run as root user"
		fi
		
		startInstallation "$1"
	else
		exitWithMessage "The path to jdk/jre tar.gz is invalid"
	fi
fi

