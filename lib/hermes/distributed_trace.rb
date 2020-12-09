require "active_record"

module Hermes
  class DistributedTrace < ::ActiveRecord::Base
    self.table_name = Hermes.configuration.distributed_tracing_database_table

    if Hermes.configuration.store_distributed_traces?
      establish_connection(Hermes.configuration.distributed_tracing_database_uri)
    end
  end
end
