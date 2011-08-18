package com.typesafe.startscript

import _root_.sbt._

import Project.Initialize
import Keys._
import Defaults._
import Scope.GlobalScope

object StartScriptPlugin extends Plugin {
    override lazy val settings = Seq(commands += ensureStartScriptTasksCommand)

    // Extracted.getOpt is not in 10.1 and earlier
    private def inCurrent[T](extracted: Extracted, key: ScopedKey[T]): Scope = {
        if (key.scope.project == This)
            key.scope.copy(project = Select(extracted.currentRef))
        else
            key.scope
    }
    private def getOpt[T](extracted: Extracted, key: ScopedKey[T]): Option[T] = {
        extracted.structure.data.get(inCurrent(extracted, key), key.key)
    }

    // surely this is harder than it has to be
    private def extractedLabel(extracted: Extracted): String = {
        val ref = extracted.currentRef
	val structure = extracted.structure
        val project = Load.getProject(structure.units, ref.build, ref.project)
        Keys.name in ref get structure.data getOrElse ref.project
    }

    private def collectIfMissing(extracted: Extracted, settings: Seq[Setting[_]], toCollect: Setting[_]): Seq[Setting[_]] = {
        val maybeExisting = getOpt(extracted, toCollect.key)
        maybeExisting match {
            case Some(x) => settings
            case None => settings :+ toCollect
        }
    }

    private case class StartScriptSetting(alias: Setting[_], other: Seq[Setting[_]])

    private def resolveStartScriptSetting(extracted: Extracted, log: Logger): StartScriptSetting = {
        val maybePackageWar = getOpt(extracted, (packageWar in Compile).scoped)
        val maybeExportJars = getOpt(extracted, (exportJars in Compile).scoped)

        if (maybePackageWar.isDefined) {
            log.info("Aliasing start-script to start-script-for-war in " + extractedLabel(extracted))
            StartScriptSetting(startScript in Compile <<= (startScriptForWar in Compile).identity,
                            startScriptWarSettings)
        } else if (maybeExportJars.isDefined && maybeExportJars.get) {
            log.info("Aliasing start-script to start-script-for-jar in " + extractedLabel(extracted))
            StartScriptSetting(startScript in Compile <<= (startScriptForJar in Compile).identity,
                            startScriptJarSettings)
        } else if (true /* can't figure out how to decide this ("is there a main class?") without compiling first */) {
            log.info("Aliasing start-script to start-script-for-classes in " + extractedLabel(extracted))
            StartScriptSetting(startScript in Compile <<= (startScriptForClasses in Compile).identity,
                            startScriptClassesSettings)
        } else {
            log.info("Aliasing start-script to start-script-not-defined in " + extractedLabel(extracted))
            StartScriptSetting(startScript in Compile <<= (startScriptNotDefined in Compile).identity,
                            genericStartScriptSettings)
        }
    }

    private def makeAppendSettings(settings: Seq[Setting[_]], inProject: ProjectRef, extracted: Extracted) = {
         // transforms This scopes in 'settings' to be the desired project
	val appendSettings = Load.transformSettings(Load.projectScope(inProject), inProject.build, extracted.rootProject, settings)
        appendSettings
    }

    private def reloadWithAppended(state: State, appendSettings: Seq[Setting[_]]): State = {
        val session = Project.session(state)
        val structure = Project.structure(state)

        // reloads with appended settings
	val newStructure = Load.reapply(session.original ++ appendSettings, structure)

        // updates various aspects of State based on the new settings
        // and returns the updated State
	Project.setProject(session, newStructure, state)
    }

    private def getStartScriptTaskSettings(state: State, ref: ProjectRef): Seq[Setting[_]] = {
        val log = CommandSupport.logger(state)
        val extracted = Extracted(Project.structure(state), Project.session(state), ref)

        log.debug("Analyzing startScript tasks for " + extractedLabel(extracted))

        val resolved = resolveStartScriptSetting(extracted, log)

        var settingsToAdd = Seq[Setting[_]]()
        for (s <- resolved.other) {
            settingsToAdd = collectIfMissing(extracted, settingsToAdd, s)
        }

        settingsToAdd = settingsToAdd :+ resolved.alias

        makeAppendSettings(settingsToAdd, ref, extracted)
    }

    // command to add the startScript tasks, avoiding overriding anything the
    // app already has, and intelligently selecting the right target for
    // the "start-script" alias
    lazy val ensureStartScriptTasksCommand =
        Command.command("ensure-start-script-tasks") { (state: State) =>
            val allRefs = Project.extract(state).structure.allProjectRefs
            val allAppendSettings = allRefs.foldLeft(Seq[Setting[_]]())({ (soFar, ref) =>
                soFar ++ getStartScriptTaskSettings(state, ref)
            })
            val newState = reloadWithAppended(state, allAppendSettings)

            //println(Project.details(Project.extract(newState).structure, false, GlobalScope, startScript.key))

            newState
        }

    case class RelativeClasspathString(value: String)

    ///// Settings keys

    val startScriptFile = SettingKey[File]("start-script-name")
    val relativeDependencyClasspathString = TaskKey[RelativeClasspathString]("relative-dependency-classpath-string", "Dependency classpath as colon-separated string with each entry relative to the build root directory.")
    val relativeFullClasspathString = TaskKey[RelativeClasspathString]("relative-full-classpath-string", "Full classpath as colon-separated string with each entry relative to the build root directory.")
    val startScriptBaseDirectory = SettingKey[File]("start-script-base-directory", "All start scripts must be run from this directory.")
    val startScriptForWar = TaskKey[File]("start-script-for-war", "Generate a shell script to launch the war file")
    val startScriptForJar = TaskKey[File]("start-script-for-jar", "Generate a shell script to launch the jar file")
    val startScriptForClasses = TaskKey[File]("start-script-for-classes", "Generate a shell script to launch from classes directory")
    val startScriptNotDefined = TaskKey[File]("start-script-not-defined", "Generate a shell script that just complains that the project is not launchable")
    val startScript = TaskKey[File]("start-script", "Generate a shell script that runs the application")

    // jetty-related settings keys
    val startScriptJettyVersion = SettingKey[String]("start-script-jetty-version", "Version of Jetty to use for running the .war")
    val startScriptJettyChecksum = SettingKey[String]("start-script-jetty-checksum", "Expected SHA-1 of the Jetty distribution we intend to download")
    val startScriptJettyURL = SettingKey[String]("start-script-jetty-url", "URL of the Jetty distribution to download (if set, then it overrides the start-script-jetty-version)")
    val startScriptJettyContextPath = SettingKey[String]("start-script-jetty-context-path", "Context path for the war file when deployed to Jetty")
    val startScriptJettyHome = TaskKey[File]("start-script-jetty-home", "Download Jetty distribution and return JETTY_HOME")

    // this is in WebPlugin, but we don't want to rely on WebPlugin to build
    private val packageWar = TaskKey[File]("package-war")

    private def directoryEqualsOrContains(d: File, f: File): Boolean = {
        if (d == f) {
            true
        } else {
            val p = f.getParentFile()
            if (p == null)
                false
            else
                directoryEqualsOrContains(d, p)
        }
    }

    // Because we want to still work if the project directory is built and then moved,
    // we change all file references pointing inside build's base directory to be relative
    // to the build (not the project) before placing them in the start script.
    // This is presumably unix-specific so we skip it if the separator char is not '/'
    // We never add ".." to make something relative, since we are only making relative
    // to basedir things that are already inside basedir. If basedir moves, we'd want
    // references to outside of it to be absolute, to keep working. We don't support
    // moving projects, just the entire build, which is generally a single git repo.
    private def relativizeFile(baseDirectory: File, f: File) = {
        if (java.io.File.separatorChar != '/') {
            f
        } else {
            val baseCanonical = baseDirectory.getCanonicalFile()
            val fCanonical = f.getCanonicalFile()
            if (directoryEqualsOrContains(baseCanonical, fCanonical)) {
                val basePath = baseCanonical.getAbsolutePath()
                val fPath = fCanonical.getAbsolutePath()
                if (fPath.startsWith(basePath)) {
                    new File("." + fPath.substring(basePath.length))
                } else {
                    error("Internal bug: %s contains %s but is not a prefix of it".format(basePath, fPath))
                }
            } else {
                // leave it as-is, don't even canonicalize
                f
            }
        }
    }

    private def relativeClasspathStringTask(baseDirectory: File, cp: Classpath) = {
        RelativeClasspathString(cp.files map { f => relativizeFile(baseDirectory, f) } mkString("", ":", ""))
    }

    // generate shell script that checks we're in the right directory
    // by checking that the script itself exists.
    private def scriptRootCheck(baseDirectory: File, scriptFile: File): String = {
        val relativeScript = relativizeFile(baseDirectory, scriptFile)
        val template = """
function die() {
    echo "$*" 1>&2
    exit 1
}
test -x '@RELATIVE_SCRIPT@' || die "'@RELATIVE_SCRIPT@' not found, this script must be run from the project base directory"
"""
        template.replace("@RELATIVE_SCRIPT@", relativeScript.toString)
    }

    private def writeScript(scriptFile: File, script: String) = {
        IO.write(scriptFile, script)
        scriptFile.setExecutable(true)
    }

    def startScriptForClassesTask(streams: TaskStreams, baseDirectory: File, scriptFile: File, cpString: RelativeClasspathString, maybeMainClass: Option[String]) = {
        maybeMainClass match {
            case Some(mainClass) =>
                val template = """#!/bin/bash
@SCRIPT_ROOT_CHECK@

java $JAVA_OPTS -cp "@CLASSPATH@" @MAINCLASS@ "$@"

exit 0

"""
                val script = template.replace("@SCRIPT_ROOT_CHECK@", scriptRootCheck(baseDirectory, scriptFile)).replace("@CLASSPATH@", cpString.value).replace("@MAINCLASS@", mainClass)
                writeScript(scriptFile, script)
                streams.log.info("Wrote start script for class " + mainClass + " to " + scriptFile)
                scriptFile
            case None =>
                startScriptNotDefinedTask(streams, scriptFile)
        }
    }

    def startScriptForJarTask(streams: TaskStreams, baseDirectory: File, scriptFile: File, jarFile: File, cpString: RelativeClasspathString) = {
        val template = """#!/bin/bash
@SCRIPT_ROOT_CHECK@
java $JAVA_OPTS -cp "@CLASSPATH@" "$@"
exit 0

"""
        val script = template.replace("@SCRIPT_ROOT_CHECK@", scriptRootCheck(baseDirectory, scriptFile)).replace("@CLASSPATH@", cpString.value).replace("@JARFILE@", jarFile.toString)
        writeScript(scriptFile, script)
        streams.log.info("Wrote start script for jar " + jarFile + " to " + scriptFile)
        scriptFile
    }

    // FIXME implement this; it will be a little bit tricky because
    // we need to download and unpack the Jetty "distribution" which isn't
    // a normal jar dependency. Not sure if Ivy can do that, may have to just
    // have a configurable URL and checksum.
    def startScriptForWarTask(streams: TaskStreams, baseDirectory: File, scriptFile: File, warFile: File, jettyHome: File, jettyContextPath: String) = {

        // First we need a Jetty config to move us to the right context path
        val contextFile = jettyHome / "contexts" / "start-script.xml"
        val contextFileTemplate = """
<Configure class="org.eclipse.jetty.webapp.WebAppContext">
  <Set name="contextPath">@CONTEXTPATH@</Set>
  <Set name="war"><SystemProperty name="jetty.home" default="."/>/webapps/@WARFILE_BASENAME@</Set>
</Configure>
"""
        val contextFileContents = contextFileTemplate.replace("@WARFILE_BASENAME@", warFile.getName).replace("@CONTEXTPATH@", jettyContextPath)
        IO.write(contextFile, contextFileContents)

        val template = """#!/bin/bash
@SCRIPT_ROOT_CHECK@

/bin/cp -f "@WARFILE@" "@JETTY_HOME@/webapps" || die "Failed to copy @WARFILE@ to @JETTY_HOME@/webapps"

if test x"$PORT" = x ; then
    PORT=8080
fi

java $JAVA_OPTS -Djetty.port="$PORT" -Djetty.home="@JETTY_HOME@" -jar "@JETTY_HOME@/start.jar" "$@"

exit 0

"""
        val script = template.replace("@SCRIPT_ROOT_CHECK@", scriptRootCheck(baseDirectory, scriptFile)).replace("@WARFILE@", warFile.toString).replace("@JETTY_HOME@", jettyHome.toString)
        writeScript(scriptFile, script)

        streams.log.info("Wrote start script for war " + warFile + " to " + scriptFile)
        scriptFile
    }

    // this is weird; but I can't figure out how to have a "startScript" task in the root
    // project that chains to child tasks, without having this dummy. For example "package"
    // works the same way, it even creates a bogus empty jar file in the root project!
    def startScriptNotDefinedTask(streams: TaskStreams, scriptFile: File) = {
        writeScript(scriptFile, """#!/bin/bash
echo "No meaningful way to start this project was defined in the SBT build" 1>&2
exit 1

""")
        streams.log.info("Wrote start script that always fails to " + scriptFile)
        scriptFile
    }

    private def basenameFromURL(url: URL) = {
        val path = url.getPath
        val slash = path.lastIndexOf('/')
        if (slash < 0)
            path
        else
            path.substring(slash + 1)
    }

    def startScriptJettyHomeTask(streams: TaskStreams, target: File, jettyURLString: String, jettyChecksum: String) = {
        try {
            val jettyURL = new URL(jettyURLString)
            val jettyDistBasename = basenameFromURL(jettyURL)
            if (!jettyDistBasename.endsWith(".zip"))
                error("%s doesn't end with .zip".format(jettyDistBasename))
            val jettyHome = target / jettyDistBasename.substring(0, jettyDistBasename.length - ".zip".length)

            val zipFile = target / jettyDistBasename
            if (!zipFile.exists()) {
                streams.log.info("Downloading %s to %s".format(jettyURL.toExternalForm, zipFile))
                IO.download(jettyURL, zipFile)
            } else {
                streams.log.debug("%s already exists".format(zipFile))
            }
            val sha1 = Hash.toHex(Hash(zipFile))
            if (sha1 != jettyChecksum) {
                streams.log.error("%s has checksum %s expected %s".format(jettyURL.toExternalForm, sha1, jettyChecksum))
                error("Bad checksum on Jetty distribution")
            }
            try {
                IO.delete(jettyHome)
            } catch {
                case e => // probably didn't exist
            }
            val files = IO.unzip(zipFile, target)
            val jettyHomePrefix = jettyHome.getCanonicalPath
            // check that all the unzipped files went where expected
            files foreach { f =>
                if (!f.getCanonicalPath.startsWith(jettyHomePrefix))
                    error("Unzipped jetty file %s that isn't in %s".format(f, jettyHome))
            }
            streams.log.debug("Unzipped %d files to %s".format(files.size, jettyHome))

            // delete annoying test.war and associated gunge
            for (deleteContentsOf <- (Seq("contexts", "webapps") map { jettyHome / _ })) {
                val contents = PathFinder(deleteContentsOf) ** new SimpleFileFilter({ f =>
                    f != deleteContentsOf
                })
                for (doNotWant <- contents.get) {
                    streams.log.debug("Deleting test noise " + doNotWant)
                    IO.delete(doNotWant)
                }
            }

            jettyHome
        } catch {
            case e: Throwable =>
                streams.log.error("Failure obtaining Jetty distribution: " + e.getMessage)
            throw e
        }
    }

    // apps can manually add these settings (in the way you'd use WebPlugin.webSettings),
    // or you can install the plugin globally and use ensure-start-script-tasks to add
    // these settings to any project.
    val genericStartScriptSettings: Seq[Project.Setting[_]] = Seq(
        startScriptFile <<= (target) { (target) => target / "start" },
        // maybe not the right way to do this...
        startScriptBaseDirectory <<= (thisProjectRef) { (ref) => new File(ref.build) },
        startScriptNotDefined in Compile <<= (streams, startScriptFile in Compile) map startScriptNotDefinedTask,
        relativeDependencyClasspathString in Compile <<= (startScriptBaseDirectory, dependencyClasspath in Runtime) map relativeClasspathStringTask,
        relativeFullClasspathString in Compile <<= (startScriptBaseDirectory, fullClasspath in Runtime) map relativeClasspathStringTask
    )

    // settings to be added to a web plugin project
    val startScriptWarSettings: Seq[Project.Setting[_]] = Seq(
        // hardcoding these defaults is not my favorite, but I'm not sure what else to do exactly.
        startScriptJettyVersion in Compile :== "7.3.0.v20110203",
        startScriptJettyChecksum in Compile :== "46ea33c033ca2597592cae294d23917079e1095d",
        startScriptJettyURL in Compile <<= (startScriptJettyVersion in Compile) { (version) =>  "http://download.eclipse.org/jetty/" + version + "/dist/jetty-distribution-" + version + ".zip" },
        startScriptJettyContextPath in Compile :== "/",
        startScriptJettyHome in Compile <<= (streams, target, startScriptJettyURL in Compile, startScriptJettyChecksum in Compile) map startScriptJettyHomeTask,
        startScriptForWar in Compile <<= (streams, startScriptBaseDirectory, startScriptFile in Compile, packageWar in Compile, startScriptJettyHome in Compile, startScriptJettyContextPath in Compile) map startScriptForWarTask
    ) ++ genericStartScriptSettings

    // settings to be added to a project with an exported jar
    val startScriptJarSettings: Seq[Project.Setting[_]] = Seq(
        startScriptForJar in Compile <<= (streams, startScriptBaseDirectory, startScriptFile in Compile, packageBin in Compile, relativeDependencyClasspathString in Compile) map startScriptForJarTask
    ) ++ genericStartScriptSettings

    // settings to be added to a project that doesn't export a jar
    val startScriptClassesSettings: Seq[Project.Setting[_]] = Seq(
        startScriptForClasses in Compile <<= (streams, startScriptBaseDirectory, startScriptFile in Compile, relativeFullClasspathString in Compile, mainClass in Compile) map startScriptForClassesTask
    ) ++ genericStartScriptSettings
}
