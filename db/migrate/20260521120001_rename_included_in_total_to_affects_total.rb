# frozen_string_literal: true

class RenameIncludedInTotalToAffectsTotal < ActiveRecord::Migration[8.1]
  def up
    rename_column :receipt_adjustments, :included_in_total, :affects_total
    change_column_default :receipt_adjustments, :affects_total, from: true, to: false
  end

  def down
    change_column_default :receipt_adjustments, :affects_total, from: false, to: true
    rename_column :receipt_adjustments, :affects_total, :included_in_total
  end
end
