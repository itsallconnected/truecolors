# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'finding software updates through the admin interface' do
  before do
    Fabricate(:software_update, version: '99.99.99', type: 'major', urgent: true, release_notes: 'https://github.com/truecolors/truecolors/releases/v99')
    Fabricate(:software_update, version: '3.5.0', type: 'major', urgent: true, release_notes: 'https://github.com/truecolors/truecolors/releases/v3.5.0')

    sign_in Fabricate(:owner_user), scope: :user
  end

  it 'shows a link to the software updates page, which links to release notes' do
    visit settings_profile_path
    click_on I18n.t('admin.critical_update_pending')

    expect(page).to have_title(I18n.t('admin.software_updates.title'))

    expect(page).to have_content('99.99.99')
                .and have_no_content('3.5.0')

    click_on I18n.t('admin.software_updates.release_notes')
    expect(page).to have_current_path('https://github.com/truecolors/truecolors/releases/v99', url: true)
  end
end
