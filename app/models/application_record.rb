class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  FORMAT_SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
end
