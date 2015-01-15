class Organization < ActiveRecord::Base
  has_one :permission, as: :target
  has_many :projects, -> { where { deleted.not_eq true } }
  has_many :accounts
  belongs_to :logo

  scope :from_param, ->(param) { where(url_name: param) }
  scope :active, -> { where { deleted.not_eq true } }
  has_many :manages, -> { where(deleted_at: nil, deleted_by: nil) }, as: 'target'
  has_many :managers, through: :manages, source: :account

  acts_as_editable editable_attributes: [:name, :url_name, :org_type, :logo_id, :description, :homepage_url],
                   merge_within: 30.minutes

  def to_param
    url_name
  end

  def active_managers
    Manage.organizations.for_target(self).active.to_a.map(&:account)
  end

  def allow_undo?(key)
    ![:name, :org_type].include?(key)
  end
end