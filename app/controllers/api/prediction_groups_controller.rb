# frozen_string_literal: true

module Api
  class PredictionGroupsController < AuthorisedController
    MAXIMUM_PREDICTION_GROUPS_LIMIT = 1000
    DEFAULT_PREDICTION_GROUPS_LIMIT = 100

    before_action :find_prediction_group, only: %i[show update]
    before_action :authorize_to_see_prediction_group, only: [:show]
    before_action :authorize_to_update_prediction_group, only: [:update]

    def create
      prediction_group = UpdatedPredictionGroup.new(PredictionGroup.new,
                                                    @user,
                                                    prediction_group_params).prediction_group
      if prediction_group.save
        render json: prediction_group
      else
        render json: prediction_group.errors, status: :unprocessable_entity
      end
    end

    def index
      render json: build_prediction_groups
    end

    def show
      render json: find_prediction_group
    end

    def update
      prediction_group = UpdatedPredictionGroup.new(find_prediction_group,
                                                    @user,
                                                    prediction_group_params).prediction_group
      if prediction_group.save
        render json: prediction_group
      else
        render json: prediction_group.errors, status: :unprocessable_entity
      end
    end

    protected

    def find_prediction_group
      PredictionGroup.includes(predictions: Prediction::DEFAULT_INCLUDES).find(params[:id])
    end

    private

    def authorize_to_see_prediction_group
      prediction_group = find_prediction_group
      prediction = prediction_group.try(:predictions).try(:first)
      raise UnauthorizedRequest unless prediction.present? &&
                                       (prediction.visible_to_everyone? ||
                                        @user.authorized_for?(prediction))
    end

    def authorize_to_update_prediction_group
      prediction_group = find_prediction_group
      prediction = prediction_group.try(:predictions).try(:first)
      return if prediction.nil?
      raise UnauthorizedRequest unless @user.authorized_for?(prediction)
    end

    def build_prediction_groups
      limit = params[:limit].to_i
      out_of_range = (1..MAXIMUM_PREDICTION_GROUPS_LIMIT).cover?(limit)
      limit = DEFAULT_PREDICTION_GROUPS_LIMIT unless out_of_range
      visible_to_everyone = Visibility::VALUES[:visible_to_everyone]
      group_ids = Prediction.where(visibility: visible_to_everyone).select(:prediction_group_id)
      PredictionGroup
        .includes(predictions: Prediction::DEFAULT_INCLUDES)
        .where(id: group_ids)
        .order(id: :desc)
        .limit(limit)
    end

    def prediction_group_params
      params.require(:prediction_group).permit!
    end
  end
end
