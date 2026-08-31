class ApplicationComponent < ViewComponent::Base
  delegate :liste_humaine, to: :helpers
end
