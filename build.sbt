name := "heroku-buildpack-scala"

resolvers +=
  "rubygems-release" at "http://rubygems-proxy.torquebox.org/releases"

libraryDependencies ++= Seq(
  "rubygems" % "thor" % "0.15.4",
  "rubygems" % "rspec-retry" % "0.3.0",
  "rubygems" % "heroku_hatchet" % "1.3.4" excludeAll(ExclusionRule("rubygems", "thor")),
  "rubygems" % "rspec" % "3.0.0"
)

val hatchet = taskKey[Unit]("Run the suite of Hatchet specs")

val Hatchet = config("hatchet")

def jruby(rubyGemsHome: File): org.jruby.Main = {
  val ruby = new org.jruby.RubyInstanceConfig()
  val env = ruby.getEnvironment.asInstanceOf[java.util.Map[String,String]]
  val newEnv = new java.util.HashMap[String, String]
  newEnv.putAll(env)
  newEnv.put("GEM_HOME", rubyGemsHome.getAbsolutePath)
  newEnv.put("GEM_PATH", rubyGemsHome.getAbsolutePath)
  ruby.setEnvironment(newEnv)
  new org.jruby.Main(ruby)
}

hatchet := {
  val rubyGemsHome = target.value / "rubygems"
  IO.createDirectory(rubyGemsHome)
  val oldContextClassLoader = Thread.currentThread.getContextClassLoader
  Thread.currentThread.setContextClassLoader(this.getClass.getClassLoader)
    (update in Hatchet).value.allFiles.foreach { f =>
      if (f.getName.endsWith(".gem")) {
        jruby(rubyGemsHome).run(List("-S", "gem", "install", f.getAbsolutePath, "-f", "-l", "-i", rubyGemsHome.getAbsolutePath).toArray[String])
      }
    }
    val rubyGemsBin = rubyGemsHome / "bin"
    jruby(rubyGemsHome).run(List("-S", rubyGemsBin.getAbsolutePath + "/hatchet", "install").toArray[String])
    jruby(rubyGemsHome).run(List("-S", rubyGemsBin.getAbsolutePath + "/rspec").toArray[String])
  Thread.currentThread.setContextClassLoader(oldContextClassLoader)
}
