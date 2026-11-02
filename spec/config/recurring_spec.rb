require 'rails_helper'

RSpec.describe 'config/recurring.yml' do
  def taches_en(env)
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new(env))
    scheduler = SolidQueue::Configuration.new.configured_processes.find { |processus| processus.kind == :scheduler }
    scheduler.attributes[:recurring_tasks].index_by(&:key)
  end

  it 'rafraîchit le catalogue en production chaque nuit à 0 h 30 UTC, l’hiver comme l’été' do
    tache = taches_en('production').fetch('rafraichir_catalogue')
    hiver = Time.utc(2026, 12, 1, 15)
    ete = Time.utc(2027, 7, 1, 15)

    expect(tache).to be_valid
    expect(tache.class_name).to eq('RafraichirCatalogueJob')
    expect(tache.next_time_after(hiver).utc.strftime('%F %R')).to eq('2026-12-02 00:30')
    expect(tache.next_time_after(ete).utc.strftime('%F %R')).to eq('2027-07-02 00:30')
  end

  %w[staging sandbox development].each do |env|
    it "ne rafraîchit pas le catalogue la nuit en #{env}" do
      expect(taches_en(env)).not_to have_key('rafraichir_catalogue')
    end
  end

  %w[production staging sandbox development test].each do |env|
    it "fait le ménage des jobs terminés en #{env}" do
      expect(taches_en(env).fetch('clear_solid_queue_finished_jobs')).to be_valid
    end
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
