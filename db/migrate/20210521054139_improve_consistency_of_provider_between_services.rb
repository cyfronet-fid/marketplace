class ImproveConsistencyOfProviderBetweenServices < ActiveRecord::Migration[6.0]
  def up
    execute(
      <<~SQL
        UPDATE providers
        SET abbreviation = 'Please update abbreviation in provider panel.'
        WHERE abbreviation IS NULL;
      SQL
    )
    change_column :providers, :abbreviation, :string, null: false

    execute(
      <<~SQL
          UPDATE providers
          SET website = 'Please update website URL in provider panel.'
          WHERE website IS NULL;
      SQL
    )
    change_column :providers, :website, :string, null: false

    execute(
      <<~SQL
          UPDATE providers
          SET legal_entity = false
          WHERE legal_entity IS NULL;
      SQL
    )
    change_column :providers, :legal_entity, :boolean, null: false

    execute(
      <<~SQL
          UPDATE providers
          SET description = 'Please update provider description in provider panel.'
          WHERE description IS NULL;
      SQL
    )
    change_column :providers, :description, :string, null: false

    execute(
      <<~SQL
          UPDATE providers
          SET street_name_and_number = 'Please update provider street and number in provider panel.'
          WHERE street_name_and_number IS NULL;
      SQL
    )
    change_column :providers, :street_name_and_number, :string, null: false

    execute(
      <<~SQL
          UPDATE providers
          SET postal_code = 'Please update postal code in provider panel.'
          WHERE postal_code IS NULL;
      SQL
    )
    change_column :providers, :postal_code, :string, null: false

    execute(
      <<~SQL
          UPDATE providers
          SET city = 'Please update city in provider panel.'
          WHERE city IS NULL;
      SQL
    )
    change_column :providers, :city, :string, null: false

    execute(
      <<~SQL
          UPDATE providers
          SET country = 'Please update country in provider panel.'
          WHERE country IS NULL;
      SQL
    )
    change_column :providers, :country, :string, null: false

    execute(
    <<~SQL
        UPDATE contacts AS c
        SET first_name = 'Please update main contact first name in provider panel.',
            last_name = 'Please update main contact last name in provider panel.'
        FROM providers AS p
        WHERE c.contactable_type LIKE '%Provider%'
              AND c.type LIKE '%MainContact%'
              AND c.contactable_id = p.id;
      SQL
    )

    execute(
    <<~SQL
          WITH d AS (
            SELECT rootd.id AS root_domain_id, subd.id AS other_domain_id
            FROM scientific_domains AS subd
            LEFT JOIN scientific_domains AS rootd ON (
              rootd.ancestry_depth = 0
              AND subd.ancestry IS NOT NULL
              AND subd.ancestry::int8 = rootd.id
              AND subd.name LIKE 'Other%'
            ) 
          )
          UPDATE provider_scientific_domains AS psd
          SET scientific_domain_id = d.other_domain_id
          FROM d
          WHERE psd.scientific_domain_id = d.root_domain_id
        SQL
    )
    execute(
      <<~SQL
          WITH v AS (
            SELECT rootv.id AS root_domain_id, subv.id AS other_domain_id
            FROM vocabularies AS rootv
            LEFT JOIN vocabularies AS subv ON (
              rootv.type LIKE 'Vocabulary::MerilScientificDomain'
              AND subv.type LIKE 'Vocabulary::MerilScientificDomain'
              AND rootv.ancestry_depth = 0
              AND subv.ancestry IS NOT NULL
              AND subv.ancestry::int8 = rootv.id
              AND subv.name LIKE 'Other%'
            )
          )
          UPDATE provider_vocabularies AS pv
          SET vocabulary_id = v.other_domain_id
          FROM v
          WHERE pv.vocabulary_id = v.root_domain_id
      SQL
    )
    execute(
    <<~SQL
          WITH v AS (
            SELECT id
            FROM vocabularies
            WHERE type LIKE 'Vocabulary::LegalStatus' AND name LIKE 'Other%'
          ),
          single_legal_status AS (
            SELECT provider_id
            FROM provider_vocabularies
            WHERE vocabulary_type LIKE 'Vocabulary::LegalStatus'
            GROUP By provider_id
            HAVING COUNT(*) = 1
          )
          UPDATE provider_vocabularies AS pv
          SET vocabulary_id = v.id
          FROM v, single_legal_status
          WHERE pv.vocabulary_type LIKE 'Vocabulary::LegalStatus'
                AND pv.provider_id <> single_legal_status.provider_id
        SQL
    )
    execute(
      <<~SQL
          WITH v AS (
            SELECT id
            FROM vocabularies
            WHERE type LIKE 'Vocabulary::EsfriType' AND name LIKE 'Other%'
          ),
          single_legal_status AS (
            SELECT provider_id
            FROM provider_vocabularies
            WHERE vocabulary_type LIKE 'Vocabulary::EsfriType'
            GROUP By provider_id
            HAVING COUNT(*) = 1
          )
          UPDATE provider_vocabularies AS pv
          SET vocabulary_id = v.id
          FROM v, single_legal_status
          WHERE pv.vocabulary_type LIKE 'Vocabulary::EsfriType'
                AND pv.provider_id <> single_legal_status.provider_id
      SQL
    )
    execute(
      <<~SQL
          WITH v AS (
            SELECT id
            FROM vocabularies
            WHERE type LIKE 'Vocabulary::ProviderLifeCycleStatus' AND name LIKE 'Other%'
          ),
          single_legal_status AS (
            SELECT provider_id
            FROM provider_vocabularies
            WHERE vocabulary_type LIKE 'Vocabulary::ProviderLifeCycleStatus'
            GROUP By provider_id
            HAVING COUNT(*) = 1
          )
          UPDATE provider_vocabularies AS pv
          SET vocabulary_id = v.id
          FROM v, single_legal_status
          WHERE pv.vocabulary_type LIKE 'Vocabulary::ProviderLifeCycleStatus'
                AND pv.provider_id <> single_legal_status.provider_id
      SQL
    )
  end

  def down
    change_column :providers, :abbreviation, :string, null: true
    execute(
      <<~SQL
        UPDATE providers
        SET abbreviation = NULL
        WHERE abbreviation LIKE 'Please update abbreviation in provider panel.';
      SQL
    )

    change_column :providers, :website, :string, null: true
    change_column :providers, :legal_entity, :boolean, null: true
    execute(
      <<~SQL
          UPDATE providers
          SET website = NULL
          WHERE website LIKE 'Please update website URL in provider panel.';
      SQL
    )

    change_column :providers, :description, :string, null: true
    execute(
      <<~SQL
          UPDATE providers
          SET description = NULL
          WHERE description LIKE 'Please update provider description in provider panel.';
      SQL
    )

    change_column :providers, :street_name_and_number, :string, null: true
    execute(
      <<~SQL
          UPDATE providers
          SET street_name_and_number = NULL
          WHERE street_name_and_number LIKE 'Please update provider street and number in provider panel.';
      SQL
    )

    change_column :providers, :postal_code, :string, null: true
    execute(
      <<~SQL
          UPDATE providers
          SET postal_code = NULL
          WHERE postal_code LIKE 'Please update postal code in provider panel.';
      SQL
    )

    change_column :providers, :city, :string, null: true
    execute(
      <<~SQL
          UPDATE providers
          SET city = NULL
          WHERE city LIKE 'Please update city in provider panel.';
      SQL
    )

    change_column :providers, :country, :string, null: true
    execute(
      <<~SQL
          UPDATE providers
          SET country = NULL
          WHERE country LIKE 'Please update country in provider panel.';
      SQL
    )

    execute(
      <<~SQL
        UPDATE contacts AS c
        SET first_name = NULL
        FROM providers AS p
        WHERE c.contactable_type LIKE '%Provider%'
              AND c.type LIKE '%MainContact%'
              AND c.contactable_id = p.id
              AND c.first_name LIKE 'Please update main contact first name in provider panel.';
      SQL
    )
    execute(
      <<~SQL
        UPDATE contacts AS c
        SET last_name = NULL
        FROM providers AS p
        WHERE c.contactable_type LIKE '%Provider%'
              AND c.type LIKE '%MainContact%'
              AND c.contactable_id = p.id
              AND c.last_name LIKE 'Please update main contact last name in provider panel.';
    SQL
    )
  end
end
