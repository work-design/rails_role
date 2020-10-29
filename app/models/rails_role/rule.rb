module RailsRole::Rule
  extend ActiveSupport::Concern

  included do
    attribute :identifier, :string
    attribute :namespace_identifier, :string, default: 'application'
    attribute :business_identifier, :string
    attribute :controller_identifier, :string
    attribute :action_name, :string
    attribute :position, :integer

    belongs_to :govern, foreign_key: :controller_identifier, primary_key: :identifier, optional: true

    enum operation: {
      list: 'list',
      read: 'read',
      add: 'add',
      edit: 'edit',
      remove: 'remove'
    }, _default: 'read'

    has_many :role_rules, foreign_key: :action_identifier, primary_key: :identifier, dependent: :delete_all
    has_many :roles, through: :role_rules

    default_scope -> { order(position: :asc, id: :asc) }

    after_initialize if: :new_record? do
      self.identifier = "#{controller_identifier}/#{action_name}"
      if govern
        self.business_identifier = govern.business_identifier
        self.namespace_identifier = govern.namespace_identifier
      end
    end
    after_commit :delete_cache

    acts_as_list scope: [:controller_identifier]
  end

  def name
    t1 = I18n.t "#{identifier.split('/').join('.')}.title", default: nil
    return t1 if t1

    t2 = self.class.enum_i18n :action_name, self.action_name
    return t2 if t2

    identifier
  end

  def delete_cache
    self.roles.each do |role|
      if Rails.cache.delete("rails_role/#{role.id}")
        puts "-----> Cache key rails_role/#{role.id} deleted"
      end
      if Rails.cache.delete("verbose_role/#{role.id}")
        puts "-----> Cache key verbose_role/#{role.id} deleted"
      end
    end
  end

end

