module Evita
  struct User
    getter id : Int32
    getter name : String
    getter service : String
    getter namespace : String
    getter metadata : Hash(String, String)

    def self.create(service, namespace, id, name, metadata)
      user = User.new(
        name,
        service,
        namespace,
        id,
        metadata
      )

      user.save!
    end

    def self.create(adapter, id, name, metadata)
      user = User.new(
        name: name,
        service: adapter.service,
        namespace: adapter.namespace,
        id: id,
        metadata: metadata
      )

      user.save!
    end

    def initialize(
      name : String = "",
      service : String = "",
      namespace : String = "",
      @id = 1,
      @metadata : Hash(String, String) = Hash(String, String).new
    )
      @name = name.to_s
      @service = service.to_s
      @namespace = namespace.to_s
    end

    def initialize(
      name : String = "",
      @id = 1,
      @metadata : Hash(String, String) = Hash(String, String).new,
      adapter : Adapter = Adapter::Shell.new(Evita.bot)
    )
      @name = name.to_s
      @service = adapter.service
      @namespace = adapter.namespace
    end

    def mention_name
      metadata["mention_name"]? || name
    end

    def save
      sql = <<-ESQL
      UPDATE users set (name, metadata) values (?, ?)
      ESQL
      Evita.bot.db.exec(sql, name, metadata)
    end

    # Deletes any existing user record, and creates a new one.
    def save!
      sql = <<-ESQL
      BEGIN TRANSACTION
      ESQL
      Evita.bot.db.exec(sql)
      sql = <<-ESQL
      DELETE from users where
      service = ? and namespace = ? and id = ?
      ESQL
      Evita.bot.db.exec(sql, service, namespace, id)
      sql = <<-ESQL
      INSERT INTO users (service, namespace, id, name, metadata)
      VALUES (?, ?, ?, ?, ?)
      ESQL
      Evita.bot.db.exec(sql, service, namespace, id, name, metadata
      )
      self
    rescue
      Evita.bot.db.exec(
        <<-ESQL
        ROLLBACK
        ESQL
      )

      nil
    end

    def to_s
      "#{@name}:#{@id}"
    end
  end
end
