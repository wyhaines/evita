module Evita
  class Database
    def self.setup(config)
      db = DB.open config.database

      begin
        # Check if the table exists.
        db.exec "SELECT 1 FROM storage"
      rescue SQLite3::Exception
        db.exec(
          <<-ESQL
          CREATE TABLE storage
            (
              namespace varchar(200),
              key varchar(200),
              value varchar(4096)
            )
          ESQL
        )
        db.exec(
          <<-ESQL
          CREATE INDEX idx_storage_namespace_x_key
          ON storage(namespace, key)
          ESQL
        )
        db.exec(
          <<-ESQL
          CREATE TABLE users
            (
              service varchar(200) NOT NULL,
              namespace varchar(200) NOT NULL,
              id int NOT NULL,
              name varchar(200) NOT NULL,
              metadata varchar(4096) NOT NULL
            )
          ESQL
        )
        db.exec(
          <<-ESQL
          CREATE INDEX idx_users_service_namespace_id
          ON users(service, namespace, id)
          ESQL
        )
        db.exec(
          <<-ESQL
          CREATE INDEX idx_users_service_namespace_name
          ON users(service, namespace, name)
          ESQL
        )
      end
      db
    end
  end
end
