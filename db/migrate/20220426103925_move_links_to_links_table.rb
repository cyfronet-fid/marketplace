# frozen_string_literal: true

class MoveLinksToLinksTable < ActiveRecord::Migration[6.1]
  def change
    Service.find_each do |service|
      service.multimedia&.each do |item|
        execute "INSERT INTO links (url, type, linkable_id, linkable_type, created_at, updated_at)
                     VALUES ('#{item}', 'Link::MultimediaUrl', '#{service.id}',
                             'Service', '#{Time.now}', '#{Time.now}');"
      end
      service&.use_cases_url&.each do |item|
        execute "INSERT INTO links (url, type, linkable_id, linkable_type, created_at, updated_at)
                     VALUES ('#{item}', 'Link::UseCasesUrl', '#{service.id}',
                             'Service', '#{Time.now}', '#{Time.now}');"
      end
    end
    Provider.find_each do |provider|
      provider.multimedia&.each do |item|
        execute "INSERT INTO links (url, type, linkable_id, linkable_type, created_at, updated_at)
                     VALUES ('#{item}', 'Link::MultimediaUrl', '#{provider.id}',
                             'Provider', '#{Time.now}', '#{Time.now}');"
      end
    end
  end
end
