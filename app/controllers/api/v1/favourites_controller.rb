# frozen_string_literal: true

class Api::V1::FavouritesController < Api::V1::ApplicationController
  include ResearchProductsHelper

  def index
    favourites = current_user.user_favourites.includes(:favoritable)
    data =
      favourites.map do |fav|
        resource = fav.favoritable
        payload = { type: fav.favoritable_type, pid: resource.respond_to?(:pid) ? resource.pid : resource.to_s }

        # Enrich payload with a few public fields when available
        if resource.is_a?(ResearchProduct)
          payload[:attributes] = resource.public_attributes
        elsif resource.respond_to?(:name)
          payload[:name] = resource.name
        end

        payload
      end

    render json: { status: "ok", favourites: data }, status: :ok
  end

  # POST /api/v1/favourites
  # Body JSON: { "pid": "<identifier>", "type": "<ClassName>" }
  def create
    resource = resolve_resource_for_create!

    fav = UserFavourite.find_or_initialize_by(user: current_user, favoritable: resource)
    if fav.persisted? || fav.save
      render json: { status: "ok", message: "Added to favourites" }, status: :ok
    else
      render json: { status: "error", message: fav.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    render json: { status: "error", message: e.message }, status: :bad_request
  rescue ActiveRecord::RecordNotFound => e
    render json: { status: "error", message: e.message }, status: :not_found
  end

  # DELETE /api/v1/favourites
  # Body JSON: { "pid": "<identifier>", "type": "<ClassName>" }
  def destroy
    resource = resolve_resource_for_destroy!

    favourite = UserFavourite.find_by(user: current_user, favoritable: resource)
    if favourite
      favourite.destroy
      render json: { status: "ok", message: "Removed from favourites" }, status: :ok
    else
      render json: { status: "error", message: "Favourite not found" }, status: :not_found
    end
  rescue ArgumentError => e
    render json: { status: "error", message: e.message }, status: :bad_request
  rescue ActiveRecord::RecordNotFound => e
    render json: { status: "error", message: e.message }, status: :not_found
  end

  private

  def favourite_params
    # Support both nested and flat JSON payloads and allow array params
    params.require(:favourite).permit(:pid, :type, :name, :best_access_right, :favourite, links: [], authors: [])
  rescue ActionController::ParameterMissing
    params.permit(:pid, :type, :name, :best_access_right, :favourite, links: [], authors: [])
  end

  def resolve_resource_for_create!
    type_str = favourite_params[:type].to_s
    pid = favourite_params[:pid].to_s
    raise ArgumentError, "param 'type' is required" if type_str.blank?
    raise ArgumentError, "param 'pid' is required" if pid.blank?

    klass = safe_constantize(type_str)

    if klass && favoritable_class?(klass)
      # Known favoritable class – must exist, otherwise 404
      find_resource!(klass, pid)
    else
      # Unknown class – create ResearchProduct with provided type
      ResearchProduct.find_or_create_by!(
        resource_id: pid,
        resource_type: type_str,
        title: favourite_params[:name],
        authors: Array(favourite_params[:authors]),
        best_access_right: favourite_params[:best_access_right],
        links: Array(favourite_params[:links])
      )
    end
  end

  def resolve_resource_for_destroy!
    type_str = favourite_params[:type].to_s
    pid = favourite_params[:pid].to_s
    raise ArgumentError, "param 'type' is required" if type_str.blank?
    raise ArgumentError, "param 'pid' is required" if pid.blank?

    klass = safe_constantize(type_str)

    if klass && favoritable_class?(klass)
      find_resource!(klass, pid)
    else
      # Unknown class – try to find existing ResearchProduct, do not create on delete
      rp = ResearchProduct.find_by(resource_id: pid, resource_type: type_str)
      raise ActiveRecord::RecordNotFound, "ResearchProduct not found" unless rp
      rp
    end
  end

  def favoritable_class?(klass)
    klass.included_modules.include?(Favoritable)
  end

  def safe_constantize(name)
    name.safe_constantize
  end

  def find_resource!(klass, pid)
    case klass.name
    when "Service"
      klass.friendly.find(pid)
    when "Offer"
      # Prefer slug/iid notation, fallback to numeric id
      begin
        Offer.find_by_slug_iid!(pid)
      rescue StandardError
        if pid.to_s =~ /^\d+$/
          Offer.find(pid.to_i)
        else
          raise ActiveRecord::RecordNotFound, "Offer not found"
        end
      end
    when "ResearchProduct"
      # Known class – do not auto-create on create path, require presence
      ResearchProduct.friendly.find(pid)
    else
      # Generic fallback: try friendly_id when available, otherwise standard find
      if klass.respond_to?(:friendly)
        klass.friendly.find(pid)
      elsif pid.to_s =~ /^\d+$/
        klass.find(pid.to_i)
      else
        raise ActiveRecord::RecordNotFound, "#{klass.name} not found"
      end
    end
  end
end
