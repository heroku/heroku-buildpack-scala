import sbt._
import Keys._

object Heroku extends Plugin {
  override def settings = Seq(
    externalResolvers <<= resolvers map { appResolvers =>
      Seq(Resolver.defaultLocal) ++ appResolvers ++
      Seq(Resolver.url("heroku-sbt-typesafe") artifacts "http://s3pository.heroku.com/ivy-typesafe-releases/[organization]/[module]/[revision]/[type]s/[artifact](-[classifier]).[ext]",
          "heroku-central" at "http://s3pository.heroku.com/maven-central/",
          "typesafe" at "http://repo.typesafe.com/typesafe/repo/")
  })
}
