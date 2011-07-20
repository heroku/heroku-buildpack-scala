resolvers ++= Seq(Resolver.url("heroku-sbt-db") artifacts "http://maven-s3pository.herokuapp.com/databinder/[organization]/[module]/[revision]/[type]s/[artifact](-[classifier]).[ext]",
          Resolver.url("heroku-central", url("http://maven-s3pository.herokuapp.com/central/")),
          Resolver.url("heroku-scala-tools-releases", url("http://maven-s3pository.herokuapp.com/scala-tools-releases/")),
          Resolver.url("heroku-scala-tools-snapshots", url("http://maven-s3pository.herokuapp.com/scala-tools-snapshots/")))

