# frozen_string_literal: true

require 'spec_helper'

describe PredictionVersion do
  describe '.create_from_current_prediction_if_required' do
    subject(:create) { described_class.create_from_current_prediction_if_required(prediction) }

    context 'prediction has not changed' do
      let!(:prediction) { FactoryBot.create(:prediction) }

      specify { expect { create }.not_to change { prediction.versions.length } }
    end

    context 'prediction is new' do
      let(:user) { FactoryBot.create(:user) }
      let!(:prediction) do
        FactoryBot.build(:prediction, description: 'A description', deadline: Date.yesterday,
                                      creator: user, uuid: 'uuid1', withdrawn: true)
      end

      specify do
        create
        version = prediction.versions.first
        expect(prediction.version).to eq 1
        expect(version.version).to eq 1
        expect(version.description).to eq 'A description'
        expect(version.deadline).to eq Date.yesterday
        expect(version.withdrawn).to be true
        expect(version.visibility).to eq 'visible_to_everyone'
      end
    end
  end

  describe '#previous_version' do
    subject(:previous_version) { most_recent_version.previous_version }

    let(:prediction) { FactoryBot.create(:prediction, description: 'old description') }
    let(:most_recent_version) { prediction.versions.last }

    specify do
      prediction.update(description: 'new description')
      expect(most_recent_version.description).to eq 'new description'
      expect(previous_version.description).to eq 'old description'
    end
  end
end
