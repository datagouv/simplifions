import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
import "dsfr"

Turbo.config.forms.submitter = "aria-disabled"
const faireRelireLAncreAuDsfr = () => dispatchEvent(new HashChangeEvent("hashchange"))
addEventListener("turbo:render", faireRelireLAncreAuDsfr)
