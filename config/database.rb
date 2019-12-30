Sequel.default_timezone = :utc
Sequel::Model.plugin :timestamps
Sequel.extension(:pg_hstore, :pg_hstore_ops)
DB_OPTIONS = {
  adapter:         DB_ADAPTER,
  host:            DB_HOST,
  port:            DB_PORT,
  database:        DB_NAME,
  user:            DB_USER,
  password:        DB_PASSWORD,
  max_connections: DB_POOL.to_i,
  logger:          Service::LoggerDb
}.freeze

DB = Sequel.connect(DB_OPTIONS)
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      DB.disconnect
      DB = Sequel.connect(DB_OPTIONS)
    end
  end
end
