require 'test_helper'

class PermissionsIntegrationTest < ActionDispatch::IntegrationTest
  let(:admin) { create(:admin, password: TEST_PASSWORD) }
  let(:account) { create(:account, password: TEST_PASSWORD) }

  before do
    @organization = create(:organization)
    @permission = create(:permission, target: @organization, remainder: true)
  end

  describe 'show' do
    describe 'organization' do
      it 'unlogged users should see permissions alert' do
        login_as nil
        get permissions_organization_path(@organization)
        must_respond_with :ok
        response.body.must_include(I18n.t('permissions.must_log_in'))
        must_select 'input[disabled="disabled"]'
      end

      it 'admins should not see permissions alert' do
        login_as admin
        get permissions_organization_path(@organization)
        must_respond_with :ok
        response.body.wont_include(I18n.t('permissions.must_log_in'))
        must_select 'input[disabled="disabled"]', false
      end

      it 'non-managers should see permissions alert' do
        login_as account
        get permissions_organization_path(@organization)
        must_respond_with :ok
        response.body.must_include(I18n.t('permissions.not_manager'))
        must_select 'input[disabled="disabled"]'
      end

      it 'managers pending approval should see permissions alert' do
        Manage.create(target: @organization, account_id: admin.id) # auto-approved
        Manage.create(target: @organization, account_id: account.id) # pending approval
        login_as account
        get permissions_organization_path(@organization)
        must_respond_with :ok
        response.body.must_include(I18n.t('permissions.not_manager'))
        must_select 'input[disabled="disabled"]'
      end

      it 'approved managers should not see permissions alert' do
        login_as account
        Manage.create(target: @organization, account_id: account.id, approved_by: admin.id)
        get permissions_organization_path(@organization)
        must_respond_with :ok
        response.body.wont_include(I18n.t('permissions.not_manager'))
        must_select 'input[disabled="disabled"]', false
      end

      it 'should gracefully handle non-existent organizations' do
        login_as nil
        get permissions_organization_path(:i_am_a_banana)
        must_respond_with :not_found
      end

      it 'must respond with not_found when organization is deleted' do
        account = create(:account)
        organization = create(:organization)
        login_as account
        organization.update!(deleted: true, editor_account: account)

        get permissions_organization_path(organization)

        must_respond_with :not_found
      end
    end
  end

  describe 'update' do
    describe 'organization' do
      it 'unlogged users should 401' do
        login_as nil
        put update_permissions_organization_path(@organization), permission: { remainder: true }
        must_respond_with :redirect
        must_redirect_to new_session_path
      end

      it 'admins should be able to update the permissions' do
        login_as admin
        put update_permissions_organization_path(@organization), permission: { remainder: true }
        @permission.reload
        must_respond_with :ok
        @permission.remainder.must_equal true
      end

      it 'non-managers should 401' do
        login_as account
        put update_permissions_organization_path(@organization), permission: { remainder: true }
        must_respond_with :unauthorized
      end

      it 'managers pending approval should 401' do
        Manage.create(target: @organization, account_id: admin.id) # auto-approved
        Manage.create(target: @organization, account_id: account.id) # pending approval
        login_as account
        put update_permissions_organization_path(@organization), permission: { remainder: true }
        must_respond_with :unauthorized
      end

      it 'approved managers should be able to update the permissions' do
        login_as account
        Manage.create(target: @organization, account_id: account.id, approved_by: admin.id)
        put update_permissions_organization_path(@organization), permission: { remainder: true }
        @permission.reload
        must_respond_with :ok
        @permission.remainder.must_equal true
      end

      it 'save failures should 422' do
        login_as account
        Manage.create(target: @organization, account_id: account.id, approved_by: admin.id)
        Permission.any_instance.expects(:update).returns false
        put update_permissions_organization_path(@organization), permission: { remainder: true }
        @permission.reload
        must_respond_with :unprocessable_entity
        @permission.remainder.must_equal true
      end
    end
  end
end
