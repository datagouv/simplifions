class ApplicationInteractor
  include Interactor

  private

  def fail_with!(message)
    context.errors ||= []
    context.errors << message
    context.fail!
  end
end
