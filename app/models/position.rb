class Position < ActiveRecord::Base
  # FIXME: Temporary fix to make Account::PositionCore tests work.
  attr_writer :committer_name

  has_one :contribution
  belongs_to :account
  belongs_to :affiliation, class_name: 'Organization', foreign_key: :organization_id
  belongs_to :project
  belongs_to :name

  scope :claimed_by, -> account { where { account_id.eq(account.id) & name_id.not_eq(nil) } }

  class << self
    # FIXME: Replace account.active_positions with account.positions.active
    def active
      where('
        EXISTS (SELECT * FROM name_facts
          INNER JOIN projects
            ON projects.best_analysis_id = name_facts.analysis_id
            AND name_facts.name_id = positions.name_id
            AND projects.id = positions.project_id)
      ')
    end
  end
end
