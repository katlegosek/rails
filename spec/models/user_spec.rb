# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  context 'validations' do
    subject { FactoryBot.build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:role) }

    it { should have_many(:notifications_users).dependent(:destroy) }
    it { should have_many(:notifications) }

    it {
      should define_enum_for(:role).with_values(user: 'user', admin: 'admin')
                                   .backed_by_column_of_type(:string)
    }

    it 'creates' do
      expect(FactoryBot.create(:user)).to be_valid
    end
  end

  context 'scopes' do
    before(:each) do
      FactoryBot.create(:user)
    end

    describe 'by_search' do
      it 'should return a record if given a valid term' do
        expect(User.by_search(User.first.first_name).any?).to be_truthy
      end

      it 'should not return a record if given a invalid term' do
        expect(User.by_search('anything').any?).to be_falsey
      end

      it 'should return everything if blank' do
        expect(User.by_search.count).to eq(User.count)
      end
    end
  end

  context 'functions' do
    describe 'full_name' do
      it 'returns the first and last name' do
        user = FactoryBot.create(:user)
        user.full_name.include?(user.first_name) && user.full_name.include?(user.last_name)
      end
    end
  end

  context 'Destroyable' do
    describe 'destroy' do
      it 'should obfuscate the user\'s information' do
        user = FactoryBot.create(:user)
        user.destroy

        expect(user.deleted_at.present?).to be_truthy
        expect(user.email.include?('@obfuscate.com')).to be_truthy
      end
    end
  end

  context "Archive and Restore" do
    describe "Archive" do
      it "should archive the user" do
        user = FactoryBot.create(:user)
        user.archive

        expect(user.deleted_at).not_to be_nil
      end

      it "should find archived users" do
        user = FactoryBot.create(:user)
        user.archive

        expect(User.archived.count).to eq(1)
        expect(User.archived(true).count).to eq(1)
        expect(User.archived("true").count).to eq(1)
        expect(User.archived(1).count).to eq(1)
        expect(User.archived("1").count).to eq(1)
        expect(User.archived(false).count).to eq(0)
      end
    end

    describe "Restore" do
      it "should archive the user" do
        user = FactoryBot.create(:user)
        user.archive
        user.restore

        expect(user.deleted_at).to be_nil
      end
    end
  end

  context "OTP" do
    describe "Verify OTP" do
      it "should verify with a correct code" do
        user = FactoryBot.create(:user)
        verify = user.verify_otp(user.otp_code)

        expect(verify).to be_truthy
      end

      it "should allow 123456 as a default for test and development" do
        user = FactoryBot.create(:user)
        verify = user.verify_otp("123456")

        expect(verify).to be_truthy
      end

      it "should fail to verify with an incorrect otp" do
        user = FactoryBot.create(:user)
        verify = user.verify_otp("654321")

        expect(verify).to be_falsey
      end

      it "should verify with a correct code after 2 failed attempts" do
        user = FactoryBot.create(:user)
        code = user.otp_code
        user.verify_otp("654321")
        user.verify_otp("765432")
        verify = user.verify_otp(code)

        expect(verify).to be_truthy
      end

      it "should fail to verify a valid code after 3 failed attempts" do
        user = FactoryBot.create(:user)
        code = user.otp_code
        user.verify_otp("654321")
        user.verify_otp("765432")
        user.verify_otp("876543")
        verify = user.verify_otp(code)

        expect(verify).to be_falsey
      end
    end
  end
end
