require 'rails_helper'

RSpec.describe 'config/recurring.yml' do
  let(:taches) do
    ActiveSupport::ConfigurationFile.parse(Rails.root.join('config/recurring.yml'))
      .to_h { |cle, options| [cle, SolidQueue::RecurringTask.from_configuration(cle, **options.symbolize_keys)] }
  end

  it 'rafraîchit le catalogue chaque nuit à 3 h, heure de Paris' do
    tache = taches.fetch('rafraichir_catalogue')
    apres_midi = Time.find_zone('Europe/Paris').parse('2026-12-01 15:00')

    expect(tache).to be_valid
    expect(tache.class_name).to eq('RafraichirCatalogueJob')
    expect(tache.next_time_after(apres_midi).in_time_zone('Europe/Paris').strftime('%F %R')).to eq('2026-12-02 03:00')
    expect(tache.next_time_after(apres_midi + 6.months).in_time_zone('Europe/Paris').hour).to eq(3)
  end

  it 'fait le ménage des jobs terminés' do
    expect(taches.fetch('clear_solid_queue_finished_jobs')).to be_valid
  end

  describe 'seul l’hôte frontal planifie les tâches' do
    around do |example|
      avant = ENV.slice('FRONTAL', 'SOLID_QUEUE_SKIP_RECURRING')
      example.run
    ensure
      ENV.delete('FRONTAL')
      ENV.delete('SOLID_QUEUE_SKIP_RECURRING')
      ENV.update(avant)
    end

    def processus_avec(frontal:)
      ENV.delete('SOLID_QUEUE_SKIP_RECURRING')
      ENV['FRONTAL'] = frontal
      load Rails.root.join('config/initializers/solid_queue_frontal.rb')
      SolidQueue::Configuration.new.configured_processes.map(&:kind)
    end

    it 'ne planifie rien sur l’hôte de secours' do
      expect(processus_avec(frontal: 'false')).not_to include(:scheduler)
    end

    it 'planifie sur l’hôte frontal' do
      expect(processus_avec(frontal: 'true')).to include(:scheduler)
    end

    it 'planifie quand FRONTAL est absent (local, CI)' do
      expect(processus_avec(frontal: nil)).to include(:scheduler)
    end
  end
end
