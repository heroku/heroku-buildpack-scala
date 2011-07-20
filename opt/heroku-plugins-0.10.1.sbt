resolvers ++= Seq(Resolver.url("heroku-sbt-db") artifacts "http://maven-s3pository.herokuapp.com/databinder/[organization]/[module]/[revision]/[type]s/[artifact](-[classifier]).[ext]",
                 "heroku-central" at "http://maven-s3pository.herokuapp.com/central/",
                 "heroku-scala-tools-releases" at "http://maven-s3pository.herokuapp.com/scala-tools-releases/",
                 "heroku-scala-tools-snapshots" at "http://maven-s3pository.herokuapp.com/scala-tools-snapshots/")

