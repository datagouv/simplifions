require_relative '../harness'

DOSSIER = 'admin-colonne-actions'.freeze
PANNEAU = 'aside.admin-panneau'.freeze

def visible_a_l_ecran?(page, bouton)
  page.evaluate_script(<<~JS, bouton)
    (function(el) { const r = el.getBoundingClientRect(); return r.top >= 0 && r.bottom <= innerHeight && document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2) === el })(arguments[0])
  JS
end

def etat_en_base(demarche) = ActiveRecord::Base.uncached { demarche.reload.slice(:nom, :visible) }

def defiler_jusqu_au_pied_de_page(page, bouton)
  page.document.synchronize do
    page.execute_script("window.scrollTo(0, document.querySelector('footer').offsetTop - innerHeight)")
    raise Capybara::ExpectationNotMet, "Enregistrer hors écran à #{page.evaluate_script('window.scrollY')}" unless visible_a_l_ecran?(page, bouton)
  end
end

def colle_en_bas(page)
  longue = Demarche.find(1)
  page.visit("/admin/demarches/#{longue.id}/edit")
  hauteur = page.evaluate_script('document.documentElement.scrollHeight')
  page.assert_selector PANNEAU, text: /Publiée/i
  defiler_jusqu_au_pied_de_page(page, page.find_button('Enregistrer', disabled: true))
  Verify.evidence(DOSSIER, page, 'defile', "demarche=#{longue.id} hauteur=#{hauteur} scrollY=#{page.evaluate_script('window.scrollY')} enregistrer_a_l_ecran=true")
end

def grise(page, nom)
  Verify.ouvrir_fiche(page, nom)
  page.find_button('Enregistrer', disabled: true)
  page.find_button('Publier', disabled: false)
  Verify.evidence(DOSSIER, page, 'enregistrer-grise', 'enregistrer=desactive publier=actif')
  page.fill_in 'Nom', with: "#{nom} saisie"
  page.find_button('Enregistrer', disabled: false)
  Verify.evidence(DOSSIER, page, 'enregistrer-actif', 'enregistrer=actif apres_saisie')
end

def entree(page, demarche, nom)
  page.find_field('Nom').send_keys(:enter)
  page.assert_text "« #{nom} saisie » enregistré."
  etat = etat_en_base(demarche)
  raise "entrée #{etat}" unless etat == { 'nom' => "#{nom} saisie", 'visible' => false }

  page.assert_selector PANNEAU, text: /Masquée/i
  Verify.evidence(DOSSIER, page, 'entree', "entree_garde_l_etat=#{etat}")
end

def erreurs(page)
  page.find_button('Enregistrer', disabled: true)
  page.fill_in 'Nom', with: ''
  page.click_button 'Enregistrer'
  page.assert_text 'Nom doit être rempli'
  page.find_button('Enregistrer', disabled: false)
  Verify.evidence(DOSSIER, page, 'erreur-enregistrer-actif', 'enregistrer=actif sur_formulaire_en_erreur')
end

def publier(page, demarche, nom)
  page.fill_in 'Nom', with: nom
  page.scroll_to(0, 2_000)
  page.click_button 'Publier'
  page.assert_text "« #{nom} » enregistré."
  page.assert_selector PANNEAU, text: /Publiée/i
  etat = etat_en_base(demarche)
  raise "publier #{etat}" unless etat == { 'nom' => nom, 'visible' => true }

  Verify.evidence(DOSSIER, page, 'publiee', "base=#{etat}")
end

def page_publique(page, slug)
  publique = page.window_opened_by { page.click_link 'Voir la page publique' }
  titre = page.within_window(publique) do
    page.assert_current_path("/demarches/#{slug}")
    page.find('h1').text
  end
  publique.close
  Verify.evidence(DOSSIER, page, 'page-publique', "h1=#{titre}")
end

def masquer(page, demarche)
  page.click_button 'Masquer'
  page.assert_selector PANNEAU, text: /Masquée/i
  visible = etat_en_base(demarche)['visible']
  raise "masquer #{visible}" if visible

  Verify.evidence(DOSSIER, page, 'masquee', "visible=#{visible}")
end

def mobile(page)
  page.current_window.resize_to(375, 800)
  debord = page.evaluate_script('document.documentElement.scrollWidth - document.documentElement.clientWidth')
  ordre = page.evaluate_script("document.querySelector('#{PANNEAU}').getBoundingClientRect().top < document.getElementById('formulaire-fiche').getBoundingClientRect().top")
  raise "375 px : débord #{debord}, colonne avant le formulaire #{ordre}" unless debord <= 0 && ordre

  Verify.evidence(DOSSIER, page, 'mobile', "debord=#{debord} colonne_sous_le_titre=#{ordre}")
ensure
  page.current_window.resize_to(1280, 1024)
end

def supprimee(page, nom)
  reste = ActiveRecord::Base.uncached { Demarche.where(nom:).count }
  raise "reste_en_base=#{reste}" unless reste.zero?

  Verify.evidence(DOSSIER, page, 'supprimee', "reste_en_base=#{reste}")
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"
  Verify.login(page)
  Verify.check('Sticky') { colle_en_bas(page) }
  demarche = Demarche.create!(nom:, slug:)
  Verify.check('Greyed') { grise(page, nom) }
  Verify.check('Enter') { entree(page, demarche, nom) }
  Verify.check('Errors') { erreurs(page) }
  Verify.check('Publish') do
    publier(page, demarche, nom)
    page_publique(page, slug)
  end
  Verify.check('Hide') { masquer(page, demarche) }
  Verify.check('Mobile') { mobile(page) }
  Verify.check('Delete') do
    page.accept_confirm("Supprimer « #{nom} » ?") { page.click_button 'Supprimer' }
    page.assert_text "« #{nom} » supprimé."
  end
  Verify.check('Proof') { supprimee(page, nom) }
ensure
  Demarche.where(slug:).destroy_all
end
