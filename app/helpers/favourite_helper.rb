# frozen_string_literal: true

module FavouriteHelper
  def favourite?(services, slug)
    services.any? { |s| s.slug == slug }
  end

  # Returns a unique list of Service records that are favourited by the user.
  # Maps favourited Offers to their parent Services and ignores other types.
  def favourite_services_for(user)
    user
      .user_favourites
      .includes(:favoritable)
      .map do |fav|
        obj = fav.favoritable
        case obj
        when Service
          obj
        when Offer
          obj.service
        end
      end
      .compact
      .uniq
  end

  def resource_link(obj)
    if obj.is_a?(Service)
      service_path(obj)
    elsif obj.is_a?(Offer)
      service_choose_offer_path(obj.service)
    else
      obj.links.first
    end
  end

  def object_name(obj)
    if obj.respond_to?(:name)
      obj.name
    elsif obj.respond_to?(:title)
      obj.title
    else
      obj.to_s
    end
  end
end
