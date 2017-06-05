module Shamu

  # {include:file:lib/shamu/auditing/README.md}
  module Auditing
    require "shamu/auditing/auditing_service"
    require "shamu/auditing/logging_auditing_service"
    require "shamu/auditing/list_scope"
    require "shamu/auditing/support"
    require "shamu/auditing/transaction"
  end
end
