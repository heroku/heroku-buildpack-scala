package controllers

import play.api._
import play.api.mvc._
import play.api.cache.Cache
import play.api.Play.current

object Application extends Controller {

  def index = Action {
    Ok(views.html.index("New stuff!!!! Your new application is ready."))
  }

  def login = Action {
    val r = (new scala.util.Random).nextInt(100000)
    Cache.set("connected", s"${r}@gmail.com")
    Ok(s"Welcome, ${Cache.getAs[String]("connected")}")
  }

  def test = Action { request =>
    Cache.getAs[String]("connected") match {
      case Some(user) => Ok("Hello " + user)
      case None => Unauthorized("Oops, you are not connected");
    }
  }

  def logout = Action { request =>
    Cache.set("connected", None)
    Ok("Bye")
  }
}
