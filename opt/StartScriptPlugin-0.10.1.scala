package com.typesafe.startScript

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
        """test -x '%s' || (echo "'%s' not found, this script must be run from the project base directory" 1>&2 && exit 1)""".format(relativeScript, relativeScript)
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
exit 1
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
        val template = """#!/bin/bas
@SCRIPT_ROOT_CHECK@
java $JAVA_OPTS -cp "@CLASSPATH@" -jar @JARFILE@ "$@"
exit 1
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
    def startScriptForWarTask(streams: TaskStreams, baseDirectory: File, scriptFile: File, warFile: File) = {
        writeScript(scriptFile, """#!/bin/bash
echo "Launching web projects is not yet implemented" 1>&2
exit 1
""")
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
        startScriptForWar in Compile <<= (streams, startScriptBaseDirectory, startScriptFile in Compile, packageWar in Compile) map startScriptForWarTask
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
