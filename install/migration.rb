class InstallSearchObject < ActiveRecord::Migration
  def self.up
    create_table :search_objects, :force => true do |t|
      t.string  :searchable_type, :null => false
      t.integer :searchable_id,   :null => false
      t.string  :title,           :null => false, :default => ""
      t.text    :content,         :null => false, :default => ""
    end
    ActiveRecord::Base.connection.execute "ALTER TABLE search_objects ENGINE = MyISAM;"
    ActiveRecord::Base.connection.execute "ALTER TABLE search_objects ADD FULLTEXT INDEX ft_title(title);"
    ActiveRecord::Base.connection.execute "ALTER TABLE search_objects ADD FULLTEXT INDEX ft_content(content);"
  end

  def self.down
    drop_table :search_objects
  end
end

