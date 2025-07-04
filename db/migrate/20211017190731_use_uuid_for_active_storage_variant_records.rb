class UseUuidForActiveStorageVariantRecords < ActiveRecord::Migration[6.1]
  def change
    drop_table :active_storage_variant_records
    create_table :active_storage_variant_records, id: :uuid do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false
  
      t.index %i[ blob_id variation_digest ], name: "index_active_storage_variant_records_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
