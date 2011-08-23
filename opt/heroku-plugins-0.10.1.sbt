resolvers ++= Seq(Resolver.url("heroku-sbt-typesafe") artifacts "http://s3pository.heroku.com/ivy-typesafe-releases/[organization]/[module]/[revision]/[type]s/[artifact](-[classifier]).[ext]",
                 "heroku-central" at "http://s3pository.heroku.com/maven-central/",
                 "heroku-scala-tools-releases" at "http://s3pository.heroku.com/maven-scala-tools-releases/",
                 "heroku-scala-tools-snapshots" at "http://s3pository.heroku.com/maven-scala-tools-snapshots/")


