# frozen_string_literal: true

class CreatePhaseOneBillSplittingTables < ActiveRecord::Migration[8.1]
  def change
    create_table :bills do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "draft"

      t.timestamps
    end
    add_index :bills, :status

    create_table :receipts do |t|
      t.references :bill, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "draft"

      t.timestamps
    end
    add_index :receipts, :status

    create_table :receipt_images do |t|
      t.references :receipt, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :capture_type, null: false

      t.timestamps
    end
    add_index :receipt_images, [ :receipt_id, :position ]

    create_table :receipt_items do |t|
      t.references :bill, null: false, foreign_key: true
      t.references :receipt, foreign_key: true
      t.string :name, null: false
      t.decimal :quantity, precision: 10, scale: 3, null: false, default: 1
      t.integer :unit_price_cents, null: false
      t.integer :total_cents, null: false
      t.string :category
      t.string :icon_key
      t.integer :position, null: false, default: 0
      t.decimal :confidence, precision: 5, scale: 4

      t.timestamps
    end
    add_index :receipt_items, [ :bill_id, :position ]

    create_table :receipt_adjustments do |t|
      t.references :receipt, null: false, foreign_key: true
      t.string :label, null: false
      t.string :kind, null: false
      t.integer :amount_cents, null: false
      t.boolean :included_in_total, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :receipt_adjustments, [ :receipt_id, :position ]
    add_index :receipt_adjustments, [ :receipt_id, :kind ]

    create_table :bill_participants do |t|
      t.references :bill, null: false, foreign_key: true
      t.string :name, null: false
      t.string :initials
      t.string :avatar_background_color
      t.string :avatar_text_color
      t.integer :seat_index
      t.boolean :is_host, null: false, default: false
      t.boolean :settled, null: false, default: false

      t.timestamps
    end
    add_index :bill_participants, [ :bill_id, :seat_index ]

    create_table :item_assignments do |t|
      t.references :receipt_item, null: false, foreign_key: true
      t.references :bill_participant, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :split_method, null: false

      t.timestamps
    end
    add_index :item_assignments, [ :receipt_item_id, :bill_participant_id ], unique: true,
      name: "index_item_assignments_on_receipt_item_and_participant"

    create_table :receipt_processing_runs do |t|
      t.references :receipt, null: false, foreign_key: true
      t.string :provider
      t.string :status, null: false, default: "pending"
      t.text :raw_ocr_text
      t.jsonb :raw_ai_response
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
    add_index :receipt_processing_runs, [ :receipt_id, :status ]
    add_index :receipt_processing_runs, :status
  end
end
