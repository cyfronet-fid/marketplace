# frozen_string_literal: true

class Import::Vocabularies
  ACCEPTED_VOCABULARIES = {
    SUPERCATEGORY: Category,
    CATEGORY: Category,
    SERVICE_CATEGORY: Vocabulary::ServiceCategory,
    SUBCATEGORY: Category,
    TRL: Vocabulary::Trl,
    SCIENTIFIC_DOMAIN: ScientificDomain,
    SCIENTIFIC_SUBDOMAIN: ScientificDomain,
    TARGET_USER: TargetUser,
    ACCESS_TYPE: Vocabulary::AccessType,
    ACCESS_MODE: Vocabulary::AccessMode,
    # TODO: Add order_type as vocabulary
    # ORDER_TYPE: Vocabulary::OrderType,
    FUNDING_BODY: Vocabulary::FundingBody,
    FUNDING_PROGRAM: Vocabulary::FundingProgram,
    LIFE_CYCLE_STATUS: Vocabulary::LifeCycleStatus,
    PROVIDER_AREA_OF_ACTIVITY: Vocabulary::AreaOfActivity,
    PROVIDER_ESFRI_TYPE: Vocabulary::EsfriType,
    PROVIDER_ESFRI_DOMAIN: Vocabulary::EsfriDomain,
    PROVIDER_LEGAL_STATUS: Vocabulary::LegalStatus,
    PROVIDER_LIFE_CYCLE_STATUS: Vocabulary::ProviderLifeCycleStatus,
    PROVIDER_NETWORK: Vocabulary::Network,
    PROVIDER_SOCIETAL_GRAND_CHALLENGE: Vocabulary::SocietalGrandChallenge,
    PROVIDER_STRUCTURE_TYPE: Vocabulary::StructureType,
    PROVIDER_MERIL_SCIENTIFIC_DOMAIN: Vocabulary::MerilScientificDomain,
    PROVIDER_MERIL_SCIENTIFIC_SUBDOMAIN: Vocabulary::MerilScientificDomain,
    PROVIDER_HOSTING_LEGAL_ENTITY: Vocabulary::HostingLegalEntity,
    RELATED_PLATFORM: Platform,
    MARKETPLACE_LOCATION: Vocabulary::ResearchActivity,
    DS_JURISDICTION: Vocabulary::Jurisdiction,
    DS_RESEARCH_ENTITY_TYPE: Vocabulary::EntityType,
    DS_PERSISTENT_IDENTITY_SCHEME: Vocabulary::EntityTypeScheme,
    # rubocop:disable Naming/VariableNumber
    DS_COAR_ACCESS_RIGHTS_1_0: Vocabulary::ResearchProductAccessPolicy,
    # rubocop:enable Naming/VariableNumber
    DS_CLASSIFICATION: Vocabulary::DatasourceClassification
  }.freeze

  def initialize(
    eosc_registry_base_url,
    dry_run: true,
    filepath: nil,
    faraday: Faraday,
    logger: ->(msg) { puts msg },
    token: nil
  )
    @eosc_registry_base_url = eosc_registry_base_url
    @dry_run = dry_run
    @faraday = faraday
    @token = token

    @logger = logger
    @filepath = filepath
  end

  def call
    log "Importing vocabularies from EOSC Registry #{@eosc_registry_base_url}..."

    begin
      r = Importers::Request.new(@eosc_registry_base_url, "vocabulary/byType", faraday: @faraday, token: @token).call
    rescue Errno::ECONNREFUSED
      abort("import exited with errors - could not connect to #{@eosc_registry_base_url}")
    end

    @vocabularies = r.body

    @not_implemented = @vocabularies.except(*ACCEPTED_VOCABULARIES.keys.map(&:to_s))

    updated = 0
    created = 0
    total_vocabularies_count = (@vocabularies&.reduce(0) { |p, (_k, v)| p + v.size }).to_i
    not_implemented_count = (@not_implemented&.reduce(0) { |p, (_k, v)| p + v.size }).to_i
    output = []

    log "[INFO] Vocabularies types #{@not_implemented.keys} are not implemented and won't be imported"

    @vocabularies
      .slice(*ACCEPTED_VOCABULARIES.keys.map(&:to_s))
      .each do |type, vocabularies_array|
        vocabularies_array.each do |vocabulary_data|
          output.append(vocabulary_data)

          updated_vocabulary_data = Importers::Vocabulary.new(vocabulary_data, clazz(type), @token).call

          mapped_vocabulary = clazz(type).find_by(eid: vocabulary_data["id"])

          if mapped_vocabulary.blank?
            created += 1
            log "Adding [NEW] vocabulary type: #{clazz(type)}, " \
                  "name: #{updated_vocabulary_data[:name]}, eid: #{updated_vocabulary_data[:eid]}"
            clazz(type).create!(updated_vocabulary_data) unless @dry_run
          else
            updated += 1
            log "Updating [EXISTING] vocabulary type: #{clazz(type)}, " \
                  "name: #{updated_vocabulary_data[:name]}, eid: #{updated_vocabulary_data[:eid]}"
            mapped_vocabulary.update!(updated_vocabulary_data) unless @dry_run
          end
        rescue ActiveRecord::RecordInvalid => e
          log "[WARN] Vocabulary type: #{clazz(type)}, " \
                "name: #{updated_vocabulary_data[:name]} eid: #{updated_vocabulary_data[:eid]} cannot be created. #{e}"
        end
      end

    log "TOTAL: #{total_vocabularies_count}, CREATED: #{created}, " \
          "UPDATED: #{updated}, UNPROCESSED: #{not_implemented_count}"

    File.open(@filepath, "w") { |file| file << JSON.pretty_generate(output) } unless @filepath.nil?
  end

  private

  def clazz(type)
    ACCEPTED_VOCABULARIES[type.to_sym]
  end

  def log(msg)
    @logger.call(msg)
  end
end
