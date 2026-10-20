Ransack.configure do |config|
  config.sanitize_custom_scope_booleans = false
  config.add_predicate 'sans_accent_cont', arel_predicate: 'matches', case_insensitive: true, formatter: proc { |mot|
    Arel::Nodes::NamedFunction.new('unaccent', [Arel::Nodes.build_quoted("%#{ActiveRecord::Base.sanitize_sql_like(mot)}%")])
  }
end
