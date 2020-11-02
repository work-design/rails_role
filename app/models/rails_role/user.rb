module RailsRole::User
  extend ActiveSupport::Concern
  include RailsRoleExt::Base

  included do
    attribute :cached_role_ids, :integer, array: true

    has_many :who_roles, as: :who, dependent: :destroy
    has_many :roles, through: :who_roles

    after_save :sync_to_role_ids, if: ->{ saved_change_to_cached_role_ids? }
  end

  def taxon_codes
    roles.map(&:taxon_codes).flatten
  end

  def admin?
    if respond_to?(:account_identities) && (RailsRole.config.default_admin_accounts & account_identities).length > 0
      true
    elsif respond_to?(:identity) && RailsRole.config.default_admin_accounts.include?(identity)
      true
    elsif defined? super
      super
    end
  end

  def sync_to_role_ids
    self.role_ids = cached_role_ids
  end

end
