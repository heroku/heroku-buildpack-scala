package com.heroku

import zio._
import zio.http._

object App extends ZIOAppDefault {
  private val routes = Routes(
    Method.GET / Root -> handler(Response.text("Hello from Scala!"))
  )

  def run = for {
    port <- System.env("PORT").map(_.flatMap(_.toIntOption).getOrElse(8080))
    _ <- Server.serve(routes).provide(Server.defaultWithPort(port))
  } yield ()
}
