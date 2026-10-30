require_relative '../harness'

DOSSIER = 'admin-lecture-seule'.freeze

def identifiant_grist(page)
  demarche = Demarche.where.not(grist_id: nil).order(:id).first!
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.scroll_to(page.find('p', text: "Identifiant Grist : #{demarche.grist_id}"), align: :center)
  page.assert_no_selector "[name='demarche[grist_id]']"
  Verify.evidence(DOSSIER, page, 'identifiant-grist', "demarche=#{demarche.id} grist_id=#{demarche.grist_id} champ=0")
end

def aucun_champ_datagouv(page)
  champs = Solution::DATAGOUV.count { |champ| page.has_selector?("[name='solution[#{champ}]']", wait: 0) }
  raise "#{champs} champs data.gouv saisissables" unless champs.zero?
end

def bloc_datagouv(page)
  solution = Solution.where.not(datagouv_titre: nil).order(:id).first!
  page.visit("/admin/solutions/#{solution.id}/edit")
  bloc = page.find('h2', text: 'Repris de data.gouv.fr').find(:xpath, '..')
  bloc.assert_text "Titre : #{solution.datagouv_titre}"
  aucun_champ_datagouv(page)
  page.scroll_to(bloc, align: :center)
  Verify.evidence(DOSSIER, page, 'datagouv', "solution=#{solution.id} uid=#{solution.uid_datagouv} titre=#{solution.datagouv_titre} champs=0")
end

Verify.drive(__FILE__) do |page|
  Verify.login(page)
  Verify.check('Grist') { identifiant_grist(page) }
  Verify.check('data.gouv') { bloc_datagouv(page) }
  Verify.check('Proof') { Verify.logout(page) }
end
