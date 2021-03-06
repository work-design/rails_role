module Roled
  module Model::Role
    extend ActiveSupport::Concern

    included do
      attribute :name, :string
      attribute :description, :string
      attribute :visible, :boolean, default: false
      attribute :who_types, :string, array: true
      attribute :role_hash, :json, default: {}
      attribute :default, :boolean

      has_many :who_roles, dependent: :destroy
      has_many :role_rules, dependent: :destroy, autosave: true, inverse_of: :role
      has_many :rules, through: :role_rules, dependent: :destroy
      has_many :governs, ->{ distinct }, through: :role_rules
      has_many :busynesses, -> { distinct }, through: :role_rules
      has_many :role_types, dependent: :delete_all

      scope :visible, -> { where(visible: true) }

      validates :name, presence: true

      #before_save :sync_who_types
      after_update :set_default, if: -> { default? && saved_change_to_default? }
      after_commit :delete_cache, if: -> { default? && saved_change_to_role_hash? }
      after_save_commit :sync, if: -> { saved_change_to_role_hash? }
    end

    def has_role?(**options)
      if options.key?(:business)
        business = options[:business].to_s
      else
        business = nil
      end
      if options.key?(:namespace)
        namespace = options[:namespace].to_s
      else
        namespace = nil
      end
      if options.key?(:controller)
        controller = options[:controller].to_s.delete_prefix('/').presence
      else
        controller = nil
      end

      opts = [business, namespace, controller, options[:action]].take_while(&->(i){ !i.nil? })
      logger.debug "  \e[35m-----> Role: #{opts} \e[0m"
      return false if opts.blank?
      role_hash.dig(*opts)
    end

    def set_default
      self.class.where.not(id: self.id).update_all(default: false)
      delete_cache
    end

    def delete_cache
      if Rails.cache.delete('default_role_hash')
        logger.debug "-----> delete cache default role hash"
      end
    end

    def sync_who_types
      who_types.exists?(who)
    end

    def business_on(busyness)
      role_hash.merge! busyness.role_hash
    end

    def namespace_on(name_space, business_identifier)
      role_hash.deep_merge!(business_identifier.to_s => {
        name_space.identifier => name_space.role_hash(business_identifier.presence)
      })
    end

    def namespace_off(name_space, business_identifier)
      role_hash.fetch(business_identifier.to_s, {}).delete(name_space.identifier.to_s)

      if role_hash.dig(business_identifier.to_s).blank?
        role_hash.delete(business_identifier.to_s)
      end
    end

    def govern_on(govern)
      toggle = {
        govern.business_identifier.to_s => {
          govern.namespace_identifier.to_s => {
            govern.controller_path => govern.role_hash
          }
        }
      }

      role_hash.deep_merge!(toggle)
    end

    def govern_off(govern)
      role_hash.fetch(govern.business_identifier.to_s, {}).fetch(govern.namespace_identifier.to_s, {}).delete(govern.controller_path)

      if role_hash.dig(govern.business_identifier.to_s, govern.namespace_identifier.to_s).blank?
        role_hash.fetch(govern.business_identifier.to_s, {}).delete(govern.namespace_identifier.to_s)
      end

      if role_hash.dig(govern.business_identifier.to_s).blank?
        role_hash.delete(govern.business_identifier.to_s)
      end
    end

    def role_rule_hash
      role_rules.group_by(&:business_identifier).transform_values! do |businesses|
        businesses.group_by(&:namespace_identifier).transform_values! do |namespaces|
          namespaces.group_by(&:controller_path).transform_values! do |controllers|
            controllers.each_with_object({}) { |i, h| h.merge! i.action_name => i.rule_id }
          end
        end
      end
    end

    def sync
      moved, add = role_rule_hash.diff_changes role_hash
      remove_role_rule(moved)
      add_role_rule(add)
    end

    def add_role_rule(add)
      add_attrs = []

      add.each do |business, namespaces|
        namespaces.each do |namespace, controllers|
          controllers.each do |controller, actions|
            actions.each do |action|
              add_attrs << {
                role_id: id,
                business_identifier: business,
                namespace_identifier: namespace,
                controller_path: controller,
                action_name: action[0],
                rule_id: action[1],
                created_at: Time.current,
                updated_at: Time.current
              }
            end
          end
        end
      end

      if add_attrs.present?
        RoleRule.insert_all(add_attrs)
      end
    end

    def remove_role_rule(moved)
      moved_ids = []

      moved.each do |business, namespaces|
        namespaces.each do |namespace, controllers|
          controllers.each do |controller, actions|
            moved_ids += role_rules.select(&->(i) { i.business_identifier == business && i.namespace_identifier == namespace && i.controller_path == controller && actions.keys.include?(i.action_name)  }).map(&:id)
          end
        end
      end

      RoleRule.where(id: moved_ids).delete_all if moved_ids.present?
    end

  end
end
