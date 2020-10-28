module RailsRole::Business
  extend ActiveSupport::Concern

  included do
    attribute :name, :string
    attribute :identifier, :string
    attribute :position, :integer

    has_many :governs, foreign_key: :business_identifier, primary_key: :identifier

    validates :identifier, uniqueness: true

    acts_as_list
  end

end
