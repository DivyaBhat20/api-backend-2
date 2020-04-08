class AddExpiresAtToUserValidationTokens < ActiveRecord::Migration[6.0]
  def change
    add_column :user_validation_tokens, :expires_at, :datetime
  end
end
