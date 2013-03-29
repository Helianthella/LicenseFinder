require "spec_helper"

describe LicenseFinder::YmlToSql do
  let(:legacy_attributes) do
    {
      'name' => "spec_name",
      'version' => "2.1.3",
      'license' => "GPLv2",
      'license_url' => "www.license_url.org",
      'approved' => true,
      'manual' => true,
      'summary' => "some summary",
      'description' => "some description",
      'homepage' => 'www.homepage.com',
      'children' => ["child1_name"],
      'parents' => ["parent1_name"],

      'notes' => 'some notes',
      'license_files' => ['/Users/pivotal/foo/lic1', '/Users/pivotal/bar/lic2'],

      'bundler_groups' => ["test"],
    }
  end

  describe ".needs_conversion?" do
    it "is true if the yml still exists"
    it "is false otherwise"
  end
  describe ".remove_yml" do
    it "removes the yml file"
  end

  describe '.convert_all' do
    before do
      (DB.tables - [:schema_migrations]).each { |table| DB[table].truncate }
    end

    it "handles un-seeded licenses (maybe?)"

    it "persists all of the dependency's attributes" do
      described_class.convert_all([legacy_attributes])

      described_class::Sql::Dependency.count.should == 1
      saved_dep = described_class::Sql::Dependency.first
      saved_dep.name.should == "spec_name"
      saved_dep.version.should == "2.1.3"
      saved_dep.summary.should == "some summary"
      saved_dep.description.should == "some description"
      saved_dep.homepage.should == "www.homepage.com"
    end

    it "associates the license to the dependency" do
      described_class.convert_all([legacy_attributes])

      saved_dep = described_class::Sql::Dependency.first
      saved_dep.license.name.should == "GPLv2"
      saved_dep.license.url.should == "www.license_url.org"
    end

    it "sets approval type to 'manual' for a manually approved dependency" do
      described_class.convert_all([legacy_attributes])

      saved_dep = described_class::Sql::Dependency.first
      saved_dep.approval.state.should == true
      saved_dep.approval.approval_type.should == 'manual'
    end

    it "does not set approval type if dependency is unapproved" do
      described_class.convert_all([legacy_attributes.merge('approved' => false)])

      saved_dep = described_class::Sql::Dependency.first
      saved_dep.approval.state.should == false
      saved_dep.approval.approval_type.should == nil
    end

    it "defaults approval type to 'whitelist'" do
      described_class.convert_all([legacy_attributes.merge('manual' => nil)])

      saved_dep = described_class::Sql::Dependency.first
      saved_dep.approval.state.should == true
      saved_dep.approval.approval_type.should == 'whitelist'
    end

    it "associates bundler groups" do
      described_class.convert_all([legacy_attributes])

      saved_dep = described_class::Sql::Dependency.first
      saved_dep.bundler_groups.count.should == 1
      saved_dep.bundler_groups.first.name.should == 'test'
    end

    it "associates children" do
      child_attrs = {
        'name' => 'child1_name',
        'version' => '0.0.1',
        'license' => 'other'
      }
      described_class.convert_all([legacy_attributes, child_attrs])

      described_class::Sql::Dependency.count.should == 2
      saved_dep = described_class::Sql::Dependency.first(name: 'spec_name')
      saved_dep.children.count.should == 1
      saved_dep.children.first.name.should == 'child1_name'
    end
  end
end
