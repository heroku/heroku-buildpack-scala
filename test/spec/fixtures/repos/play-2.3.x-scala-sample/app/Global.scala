import play.api._
import play.api.mvc._

import play.api.Logger
import scala.concurrent.Future
import play.api.libs.concurrent.Execution.Implicits.defaultContext

object RequestIdLoggingFilter extends Filter {
  def apply(nextFilter: (RequestHeader) => Future[Result])
  (requestHeader: RequestHeader): Future[Result] = {
    Logger.info(s"request_id=${requestHeader.headers.get("X-Request-ID").getOrElse("None")}")
    nextFilter(requestHeader)
  }
}

object Global extends WithFilters(RequestIdLoggingFilter) {

  override def onStart(app: Application) {
    Logger.info("Application has started");
  }

  override def onStop(app: Application) {
    Logger.info("CUSTOM Application shutdown...");
  }

}
