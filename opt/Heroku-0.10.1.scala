import sbt._
import Keys._

object Heroku extends Plugin {
  override def settings = Seq(
    externalResolvers <<= resolvers map { appResolvers =>
      Seq(Resolver.defaultLocal) ++ appResolvers ++
      Seq(Resolver.url("heroku-sbt-db") artifacts "http://maven-s3pository.herokuapp.com/databinder/[organization]/[module]/[revision]/[type]s/[artifact](-[classifier]).[ext]",
          Resolver.url("heroku-central", url("http://maven-s3pository.herokuapp.com/central/")),
          Resolver.url("heroku-scala-tools-releases", url("http://maven-s3pository.herokuapp.com/scala-tools-releases/")),
          Resolver.url("heroku-scala-tools-snapshots", url("http://maven-s3pository.herokuapp.com/scala-tools-snapshots/")))
  })
}
