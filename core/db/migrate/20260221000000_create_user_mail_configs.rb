# frozen_string_literal: true

class CreateUserMailConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :user_mail_configs do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :email, null: false
      t.string :imap_host, null: false
      t.integer :imap_port, null: false, default: 993
      t.string :smtp_host, null: false
      t.integer :smtp_port, null: false, default: 587
      t.string :password, null: false
      t.timestamps
    end
  end
end
