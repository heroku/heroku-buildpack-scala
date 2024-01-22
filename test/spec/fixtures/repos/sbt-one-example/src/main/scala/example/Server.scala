package example

import com.twitter.finagle.{Http, Service}
import com.twitter.finagle.http
import com.twitter.util.{Await, Future}

import util.Properties

object Server {
  def main(args: Array[String]) {
    val port = Properties.envOrElse("PORT", "8080").toInt
    println("Starting on port: "+port)

    // val service = new Service[http.Request, http.Response] {
    //   def response = http.Response(req.version, http.Status.Ok)
    //   def apply(req: http.Request): Future[http.Response] =
    //     Future.value(response)
    // }

    val server = Http.serve(s":$port", new Hello)
    Await.ready(server)
  }
}

class Hello extends Service[http.Request, http.Response] {
  def apply(req: http.Request): Future[http.Response] = {
    val response = http.Response(req.version, http.Status.Ok)
    response.setContentString("Hello from Scala!")
    Future(response)
  }
}
